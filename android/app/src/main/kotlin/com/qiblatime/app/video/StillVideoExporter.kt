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
import android.util.Log
import java.io.File
import java.nio.ByteBuffer
import java.util.concurrent.CancellationException
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
  private const val TAG = "QiblaVideoExport"
  private const val CANCELLED_MESSAGE = "El vídeo tardó demasiado y se canceló"

  @Volatile
  private var cancelRequested = false

  @Volatile
  private var activeStep = "sin iniciar"

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
    cancelRequested = false
    step(
      "inicio del export",
      "image=${params.imagePath} audio=${params.audioPath} output=${params.outputPath} size=${params.width}x${params.height} fps=${params.fps}",
    )

    try {
      exportInternal(params)
    } catch (e: Throwable) {
      Log.e(TAG, "export failed", e)
      throw e
    } finally {
      cancelRequested = false
    }
  }

  fun cancelActiveExport() {
    cancelRequested = true
    Log.w(TAG, "cancel requested lastStep=$activeStep")
  }

  fun lastActiveStep(): String = activeStep

  private fun exportInternal(params: Params) {
    val imageFile = File(params.imagePath)
    require(imageFile.exists()) { "Image not found: ${params.imagePath}" }
    val audioFile = File(params.audioPath)
    require(audioFile.exists()) { "Audio not found: ${params.audioPath}" }
    Log.i(
      TAG,
      "input files ok imageBytes=${imageFile.length()} audioBytes=${audioFile.length()}",
    )
    checkCancelled()

    val outputFile = File(params.outputPath)
    outputFile.parentFile?.mkdirs()
    if (outputFile.exists()) outputFile.delete()

    Log.i(TAG, "reading audio duration")
    val durationUs = readAudioDurationUs(params.audioPath)
    require(durationUs > 0) { "Could not read audio duration." }
    step("audio abierto", "durationUs=$durationUs")
    checkCancelled()

    Log.i(TAG, "reading image bitmap")
    val bitmap = BitmapFactory.decodeFile(params.imagePath)
      ?: throw IllegalStateException("Could not decode image.")
    val scaledBitmap = scaleToFit(bitmap, params.width, params.height)
    val yuvFrame = bitmapToNV21(scaledBitmap, params.width, params.height)
    step(
      "imagen cargada",
      "image decoded bitmap=${bitmap.width}x${bitmap.height} scaled=${scaledBitmap.width}x${scaledBitmap.height} yuvBytes=${yuvFrame.size}",
    )
    checkCancelled()

    Log.i(TAG, "creating MediaMuxer output=${params.outputPath}")
    val muxer = MediaMuxer(params.outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
    step("MediaMuxer creado", "output=${params.outputPath}")
    checkCancelled()
    var videoTrackIndex = -1
    var audioTrackIndex = -1
    var started = false

    Log.i(TAG, "creating video MediaCodec")
    val videoEncoder = createVideoEncoder(params, durationUs)
    val videoBufferInfo = MediaCodec.BufferInfo()
    step("MediaCodec vídeo creado", "codec=${videoEncoder.name}")
    checkCancelled()

    Log.i(TAG, "creating audio decoder MediaCodec")
    val audioDecoder = createAudioDecoder(params.audioPath)
    step("MediaCodec audio creado", "decoder=${audioDecoder.name}")
    val audioDecoderBufferInfo = MediaCodec.BufferInfo()
    val audioEncoderBufferInfo = MediaCodec.BufferInfo()

    Log.i(TAG, "opening audio extractor")
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
    Log.i(
      TAG,
      "audio extractor ready track=$audioTrack sampleRate=$sampleRate channels=$channelCount format=$inputAudioFormat",
    )
    step("MediaExtractor listo", "track=$audioTrack sampleRate=$sampleRate channels=$channelCount")
    checkCancelled()

    Log.i(TAG, "creating audio encoder MediaCodec")
    val audioEncoder = createAudioEncoder(params, sampleRate, channelCount)
    step("MediaCodec audio creado", "decoder=${audioDecoder.name} encoder=${audioEncoder.name}")
    checkCancelled()

    // Start codecs.
    Log.i(TAG, "starting MediaCodecs")
    videoEncoder.start()
    audioDecoder.start()
    audioEncoder.start()
    val videoInputBuffers = videoEncoder.inputBuffers
    val audioDecoderInputBuffers = audioDecoder.inputBuffers
    val audioDecoderOutputBuffers = audioDecoder.outputBuffers
    val audioEncoderInputBuffers = audioEncoder.inputBuffers
    Log.i(TAG, "MediaCodecs started")

    // Feed video frames ASAP; feed audio in parallel-ish inside a single loop.
    val frameCount = max(1, (durationUs * params.fps / 1_000_000L).toInt())
    val frameDurationUs = 1_000_000L / params.fps.toLong()
    step("escritura de frames empezada", "frameCount=$frameCount frameDurationUs=$frameDurationUs")
    var nextFrameIndex = 0

    var extractorDone = false
    var decoderDone = false
    var encoderDone = false

    var videoInputDone = false
    var videoOutputDone = false

    // Audio PCM staging buffer
    var pendingPcm: ByteArray? = null
    var pendingPcmOffset = 0
    var loggedFirstAudioSample = false

    try {
      while (!videoOutputDone || !encoderDone) {
      checkCancelled()
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
            Log.i(TAG, "queued video end of stream ptsUs=$ptsUs")
          } else {
            buffer.put(yuvFrame)
            videoEncoder.queueInputBuffer(inIndex, 0, yuvFrame.size, ptsUs, 0)
            nextFrameIndex++
            if (nextFrameIndex == 1 || nextFrameIndex % (params.fps * 2) == 0 || nextFrameIndex == frameCount) {
              Log.d(TAG, "queued video frame=$nextFrameIndex/$frameCount ptsUs=$ptsUs")
            }
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
            Log.i(TAG, "video output format changed track=$videoTrackIndex format=$newFormat")
            if (audioTrackIndex >= 0 && !started) {
              muxer.start()
              started = true
              Log.i(TAG, "MediaMuxer started after video format")
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
              Log.i(TAG, "video encoder reached end of stream")
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
            Log.i(TAG, "audio extractor reached end of stream")
          } else {
            val presentationTimeUs = extractor.sampleTime
            audioDecoder.queueInputBuffer(inIndex, 0, sampleSize, presentationTimeUs, 0)
            if (!loggedFirstAudioSample) {
              loggedFirstAudioSample = true
              step("escritura de audio empezada", "firstSampleSize=$sampleSize ptsUs=$presentationTimeUs")
            }
            extractor.advance()
          }
        }
      }

      // 4) Drain audio decoder and feed audio encoder.
      if (!decoderDone) {
        val outIndex = audioDecoder.dequeueOutputBuffer(audioDecoderBufferInfo, 0)
        when {
          outIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
            Log.i(TAG, "audio decoder output format changed format=${audioDecoder.outputFormat}")
          }
          outIndex >= 0 -> {
            val outBuffer = if (Build.VERSION.SDK_INT >= 21) {
              audioDecoder.getOutputBuffer(outIndex)
            } else {
              audioDecoderOutputBuffers[outIndex]
            }
            if (outBuffer != null && audioDecoderBufferInfo.size > 0) {
              val pcmBytes = ByteArray(audioDecoderBufferInfo.size)
              outBuffer.position(audioDecoderBufferInfo.offset)
              outBuffer.limit(audioDecoderBufferInfo.offset + audioDecoderBufferInfo.size)
              outBuffer.get(pcmBytes)
              pendingPcm = pcmBytes
              pendingPcmOffset = 0
            }
            audioDecoder.releaseOutputBuffer(outIndex, false)
            if ((audioDecoderBufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
              decoderDone = true
              Log.i(TAG, "audio decoder reached end of stream")
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
            audioEncoder.queueInputBuffer(inIndex, 0, toWrite, audioDecoderBufferInfo.presentationTimeUs, 0)
          }
        }
      }

      // 6) Drain audio encoder output and write to muxer.
      val outIndex = audioEncoder.dequeueOutputBuffer(audioEncoderBufferInfo, 0)
      when {
        outIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
          val newFormat = audioEncoder.outputFormat
          audioTrackIndex = muxer.addTrack(newFormat)
          Log.i(TAG, "audio encoder output format changed track=$audioTrackIndex format=$newFormat")
          if (videoTrackIndex >= 0 && !started) {
            muxer.start()
            started = true
            Log.i(TAG, "MediaMuxer started after audio format")
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
            Log.i(TAG, "audio encoder reached end of stream")
          }
        }
      }

      }
    } finally {
      Log.i(TAG, "closing native exporter resources lastStep=$activeStep")
      safeReleaseExtractor(extractor)
      safeStopAndRelease("audioDecoder", audioDecoder)
      safeStopAndRelease("audioEncoder", audioEncoder)
      safeStopAndRelease("videoEncoder", videoEncoder)
      if (started) {
        safeStopMuxer(muxer)
      }
      safeReleaseMuxer(muxer)
    }

    if (!outputFile.exists()) {
      throw IllegalStateException("Output file was not generated: ${outputFile.absolutePath}")
    }
    if (outputFile.length() <= 0L) {
      throw IllegalStateException("Output file was generated but is empty: ${outputFile.absolutePath}")
    }
    step("export terminado", "path=${outputFile.absolutePath} bytes=${outputFile.length()}")
  }

  private fun step(name: String, details: String = "") {
    activeStep = name
    if (details.isBlank()) {
      Log.i(TAG, "STEP $name")
    } else {
      Log.i(TAG, "STEP $name - $details")
    }
  }

  private fun checkCancelled() {
    if (cancelRequested) {
      throw CancellationException("$CANCELLED_MESSAGE. Último paso nativo: $activeStep")
    }
  }

  private fun safeReleaseExtractor(extractor: MediaExtractor) {
    try {
      extractor.release()
    } catch (e: Throwable) {
      Log.w(TAG, "Failed to release extractor", e)
    }
  }

  private fun safeStopAndRelease(name: String, codec: MediaCodec) {
    try {
      codec.stop()
    } catch (e: Throwable) {
      Log.w(TAG, "Failed to stop $name", e)
    }
    try {
      codec.release()
    } catch (e: Throwable) {
      Log.w(TAG, "Failed to release $name", e)
    }
  }

  private fun safeStopMuxer(muxer: MediaMuxer) {
    try {
      muxer.stop()
    } catch (e: Throwable) {
      Log.w(TAG, "Failed to stop muxer", e)
    }
  }

  private fun safeReleaseMuxer(muxer: MediaMuxer) {
    try {
      muxer.release()
    } catch (e: Throwable) {
      Log.w(TAG, "Failed to release muxer", e)
    }
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
