package com.qiblatime.app.video

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.media.MediaMuxer
import android.os.Build
import java.io.File
import java.nio.ByteBuffer
import kotlin.math.max

/**
 * Creates a vertical MP4 from a still image + MP3 audio using platform codecs.
 * No FFmpeg, no GPL dependencies.
 *
 * Notes:
 * - Video: H.264 (AVC) via MediaCodec (software/hardware depending on device)
 * - Audio: decodes MP3 -> PCM -> encodes AAC via MediaCodec
 */
object StillVideoExporter {
  private const val MIME_VIDEO_AVC = "video/avc"
  private const val MIME_AUDIO_AAC = "audio/mp4a-latm"

  data class Params(
    val imagePath: String,
    val audioPath: String,
    val outputPath: String,
    val width: Int,
    val height: Int,
    val fps: Int,
    val videoBitrate: Int,
    val audioBitrate: Int,
  )

  fun export(params: Params) {
    val imageFile = File(params.imagePath)
    require(imageFile.exists()) { "Image not found: ${params.imagePath}" }
    val audioFile = File(params.audioPath)
    require(audioFile.exists()) { "Audio not found: ${params.audioPath}" }

    val outputFile = File(params.outputPath)
    outputFile.parentFile?.mkdirs()
    if (outputFile.exists()) outputFile.delete()

    val durationUs = readAudioDurationUs(params.audioPath)
    require(durationUs > 0) { "Could not read audio duration." }

    val bitmap = BitmapFactory.decodeFile(params.imagePath)
      ?: throw IllegalStateException("Could not decode image.")
    val scaledBitmap = scaleToFit(bitmap, params.width, params.height)

    val muxer = MediaMuxer(params.outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
    var videoTrackIndex = -1
    var audioTrackIndex = -1
    var started = false

    val videoEncoder = createVideoEncoder(params, durationUs)
    val videoInputBuffers = videoEncoder.inputBuffers
    val videoBufferInfo = MediaCodec.BufferInfo()

    val audioDecoder = createAudioDecoder(params.audioPath)
    val audioDecoderInputBuffers = audioDecoder.inputBuffers
    val audioDecoderOutputBuffers = audioDecoder.outputBuffers
    val audioEncoderBufferInfo = MediaCodec.BufferInfo()

    val extractor = MediaExtractor()
    extractor.setDataSource(params.audioPath)
    val audioTrack = selectAudioTrack(extractor)
    require(audioTrack >= 0) { "No audio track found in input." }
    extractor.selectTrack(audioTrack)
    val inputAudioFormat = extractor.getTrackFormat(audioTrack)
    val sampleRate =
      if (inputAudioFormat.containsKey(MediaFormat.KEY_SAMPLE_RATE)) {
        inputAudioFormat.getInteger(MediaFormat.KEY_SAMPLE_RATE)
      } else {
        44100
      }
    val channelCount =
      if (inputAudioFormat.containsKey(MediaFormat.KEY_CHANNEL_COUNT)) {
        inputAudioFormat.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
      } else {
        2
      }

    val audioEncoder = createAudioEncoder(params, sampleRate, channelCount)
    val audioEncoderInputBuffers = audioEncoder.inputBuffers

    // Start codecs.
    videoEncoder.start()
    audioDecoder.start()
    audioEncoder.start()

    // Feed video frames ASAP; feed audio in parallel-ish inside a single loop.
    val frameCount = max(1, (durationUs * params.fps / 1_000_000L).toInt())
    val frameDurationUs = 1_000_000L / params.fps.toLong()
    var nextFrameIndex = 0

    var extractorDone = false
    var decoderDone = false
    var encoderDone = false

    var videoInputDone = false
    var videoOutputDone = false

    // Audio PCM staging buffer
    var pendingPcm: ByteArray? = null
    var pendingPcmOffset = 0

    while (!videoOutputDone || !encoderDone) {
      // 1) Feed video encoder with repeated still frames (YUV420).
      if (!videoInputDone) {
        val inIndex = videoEncoder.dequeueInputBuffer(0)
        if (inIndex >= 0) {
          val buffer = videoInputBuffers[inIndex]
          buffer.clear()
          val ptsUs = nextFrameIndex * frameDurationUs
          if (nextFrameIndex >= frameCount) {
            videoEncoder.queueInputBuffer(inIndex, 0, 0, ptsUs, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
            videoInputDone = true
          } else {
            val yuv = bitmapToNV21(scaledBitmap, params.width, params.height)
            buffer.put(yuv)
            videoEncoder.queueInputBuffer(inIndex, 0, yuv.size, ptsUs, 0)
            nextFrameIndex++
          }
        }
      }

      // 2) Drain video encoder output.
      if (!videoOutputDone) {
        val outIndex = videoEncoder.dequeueOutputBuffer(videoBufferInfo, 0)
        when {
          outIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
            val newFormat = videoEncoder.outputFormat
            videoTrackIndex = muxer.addTrack(newFormat)
            if (audioTrackIndex >= 0 && !started) {
              muxer.start()
              started = true
            }
          }
          outIndex >= 0 -> {
            val outBuffer = videoEncoder.getOutputBuffer(outIndex) ?: ByteBuffer.allocate(0)
            if ((videoBufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG) != 0) {
              videoBufferInfo.size = 0
            }
            if (videoBufferInfo.size > 0) {
              require(started) { "Muxer not started yet." }
              outBuffer.position(videoBufferInfo.offset)
              outBuffer.limit(videoBufferInfo.offset + videoBufferInfo.size)
              muxer.writeSampleData(videoTrackIndex, outBuffer, videoBufferInfo)
            }
            videoEncoder.releaseOutputBuffer(outIndex, false)
            if ((videoBufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
              videoOutputDone = true
            }
          }
        }
      }

      // 3) Feed audio decoder from extractor.
      if (!extractorDone) {
        val inIndex = audioDecoder.dequeueInputBuffer(0)
        if (inIndex >= 0) {
          val inputBuffer = audioDecoderInputBuffers[inIndex]
          inputBuffer.clear()
          val sampleSize = extractor.readSampleData(inputBuffer, 0)
          if (sampleSize < 0) {
            audioDecoder.queueInputBuffer(inIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
            extractorDone = true
          } else {
            val presentationTimeUs = extractor.sampleTime
            audioDecoder.queueInputBuffer(inIndex, 0, sampleSize, presentationTimeUs, 0)
            extractor.advance()
          }
        }
      }

      // 4) Drain audio decoder and feed audio encoder.
      if (!decoderDone) {
        val outIndex = audioDecoder.dequeueOutputBuffer(audioEncoderBufferInfo, 0)
        when {
          outIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
            // not used
          }
          outIndex >= 0 -> {
            val outBuffer = if (Build.VERSION.SDK_INT >= 21) {
              audioDecoder.getOutputBuffer(outIndex)
            } else {
              audioDecoderOutputBuffers[outIndex]
            }
            if (outBuffer != null && audioEncoderBufferInfo.size > 0) {
              val pcmBytes = ByteArray(audioEncoderBufferInfo.size)
              outBuffer.position(audioEncoderBufferInfo.offset)
              outBuffer.limit(audioEncoderBufferInfo.offset + audioEncoderBufferInfo.size)
              outBuffer.get(pcmBytes)
              pendingPcm = pcmBytes
              pendingPcmOffset = 0
            }
            audioDecoder.releaseOutputBuffer(outIndex, false)
            if ((audioEncoderBufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
              decoderDone = true
            }
          }
        }
      }

      // 5) Feed audio encoder with pending PCM.
      if (!encoderDone) {
        val inIndex = audioEncoder.dequeueInputBuffer(0)
        if (inIndex >= 0) {
          val inputBuffer = audioEncoderInputBuffers[inIndex]
          inputBuffer.clear()
          val pcm = pendingPcm
          if (pcm == null) {
            if (decoderDone) {
              audioEncoder.queueInputBuffer(inIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
            } else {
              // No PCM ready yet; don't queue empty buffers.
            }
          } else {
            val remaining = pcm.size - pendingPcmOffset
            val toWrite = minOf(remaining, inputBuffer.remaining())
            inputBuffer.put(pcm, pendingPcmOffset, toWrite)
            pendingPcmOffset += toWrite
            if (pendingPcmOffset >= pcm.size) {
              pendingPcm = null
            }
            audioEncoder.queueInputBuffer(inIndex, 0, toWrite, audioEncoderBufferInfo.presentationTimeUs, 0)
          }
        }
      }

      // 6) Drain audio encoder output and write to muxer.
      val outIndex = audioEncoder.dequeueOutputBuffer(audioEncoderBufferInfo, 0)
      when {
        outIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
          val newFormat = audioEncoder.outputFormat
          audioTrackIndex = muxer.addTrack(newFormat)
          if (videoTrackIndex >= 0 && !started) {
            muxer.start()
            started = true
          }
        }
        outIndex >= 0 -> {
          val outBuffer = audioEncoder.getOutputBuffer(outIndex) ?: ByteBuffer.allocate(0)
          if ((audioEncoderBufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG) != 0) {
            audioEncoderBufferInfo.size = 0
          }
          if (audioEncoderBufferInfo.size > 0) {
            require(started) { "Muxer not started yet." }
            outBuffer.position(audioEncoderBufferInfo.offset)
            outBuffer.limit(audioEncoderBufferInfo.offset + audioEncoderBufferInfo.size)
            muxer.writeSampleData(audioTrackIndex, outBuffer, audioEncoderBufferInfo)
          }
          audioEncoder.releaseOutputBuffer(outIndex, false)
          if ((audioEncoderBufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
            encoderDone = true
          }
        }
      }
    }

    extractor.release()
    audioDecoder.stop()
    audioDecoder.release()
    audioEncoder.stop()
    audioEncoder.release()
    videoEncoder.stop()
    videoEncoder.release()
    if (started) muxer.stop()
    muxer.release()
  }

  private fun createVideoEncoder(params: Params, durationUs: Long): MediaCodec {
    val format = MediaFormat.createVideoFormat(MIME_VIDEO_AVC, params.width, params.height)
    format.setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible)
    format.setInteger(MediaFormat.KEY_BIT_RATE, params.videoBitrate)
    format.setInteger(MediaFormat.KEY_FRAME_RATE, params.fps)
    format.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
    if (Build.VERSION.SDK_INT >= 24) {
      format.setInteger(MediaFormat.KEY_PROFILE, MediaCodecInfo.CodecProfileLevel.AVCProfileBaseline)
      format.setInteger(MediaFormat.KEY_LEVEL, MediaCodecInfo.CodecProfileLevel.AVCLevel3)
    }
    val codec = MediaCodec.createEncoderByType(MIME_VIDEO_AVC)
    codec.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
    return codec
  }

  private fun createAudioDecoder(audioPath: String): MediaCodec {
    val extractor = MediaExtractor()
    extractor.setDataSource(audioPath)
    val trackIndex = selectAudioTrack(extractor)
    require(trackIndex >= 0) { "No audio track found." }
    val inputFormat = extractor.getTrackFormat(trackIndex)
    val mime = inputFormat.getString(MediaFormat.KEY_MIME) ?: error("No mime")
    extractor.release()
    val decoder = MediaCodec.createDecoderByType(mime)
    decoder.configure(inputFormat, null, null, 0)
    return decoder
  }

  private fun createAudioEncoder(params: Params, sampleRate: Int, channelCount: Int): MediaCodec {
    val format = MediaFormat.createAudioFormat(MIME_AUDIO_AAC, sampleRate, channelCount)
    format.setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
    format.setInteger(MediaFormat.KEY_BIT_RATE, params.audioBitrate)
    format.setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 16384)
    val codec = MediaCodec.createEncoderByType(MIME_AUDIO_AAC)
    codec.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
    return codec
  }

  private fun selectAudioTrack(extractor: MediaExtractor): Int {
    for (i in 0 until extractor.trackCount) {
      val format = extractor.getTrackFormat(i)
      val mime = format.getString(MediaFormat.KEY_MIME) ?: continue
      if (mime.startsWith("audio/")) return i
    }
    return -1
  }

  private fun readAudioDurationUs(audioPath: String): Long {
    val retriever = MediaMetadataRetriever()
    return try {
      retriever.setDataSource(audioPath)
      val durationMs = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull()
      (durationMs ?: 0L) * 1000L
    } finally {
      retriever.release()
    }
  }

  private fun scaleToFit(bitmap: Bitmap, width: Int, height: Int): Bitmap {
    if (bitmap.width == width && bitmap.height == height) return bitmap
    return Bitmap.createScaledBitmap(bitmap, width, height, true)
  }

  // Naive ARGB -> NV21 conversion. Good enough for still image frames.
  private fun bitmapToNV21(bitmap: Bitmap, width: Int, height: Int): ByteArray {
    val argb = IntArray(width * height)
    bitmap.getPixels(argb, 0, width, 0, 0, width, height)

    val yuv = ByteArray(width * height * 3 / 2)
    var yIndex = 0
    var uvIndex = width * height

    var index = 0
    for (j in 0 until height) {
      for (i in 0 until width) {
        val color = argb[index++]
        val r = (color shr 16) and 0xff
        val g = (color shr 8) and 0xff
        val b = color and 0xff

        val y = ((66 * r + 129 * g + 25 * b + 128) shr 8) + 16
        val u = ((-38 * r - 74 * g + 112 * b + 128) shr 8) + 128
        val v = ((112 * r - 94 * g - 18 * b + 128) shr 8) + 128

        yuv[yIndex++] = y.coerceIn(0, 255).toByte()

        if (j % 2 == 0 && i % 2 == 0) {
          yuv[uvIndex++] = v.coerceIn(0, 255).toByte()
          yuv[uvIndex++] = u.coerceIn(0, 255).toByte()
        }
      }
    }
    return yuv
  }
}
