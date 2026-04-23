// StillVideoExporter.swift
// Native iOS still-image → H.264/AAC MP4 exporter using AVFoundation only.
// No FFmpeg, no GPL dependencies.
//
// Architecture mirrors android/…/video/StillVideoExporter.kt:
//   PNG  ──► CVPixelBuffer ──► H.264 video track ┐
//   MP3  ──► PCM decode   ──► AAC  audio track  ─┴─► AVAssetWriter → .mp4

import AVFoundation
import UIKit
import CoreVideo
import CoreMedia

final class StillVideoExporter {

    // MARK: - Error types

    enum ExportError: LocalizedError {
        case imageLoadFailed(String)
        case invalidAudioDuration
        case audioTrackMissing
        case pixelBufferCreationFailed
        case writerSetupFailed(String)
        case writingFailed(String)

        var errorDescription: String? {
            switch self {
            case .imageLoadFailed(let path):
                return "Cannot load PNG image at path: \(path)"
            case .invalidAudioDuration:
                return "Audio duration is zero or negative; cannot determine video length"
            case .audioTrackMissing:
                return "No audio track found in source audio file"
            case .pixelBufferCreationFailed:
                return "Failed to create CVPixelBuffer from PNG image"
            case .writerSetupFailed(let msg):
                return "AVAssetWriter setup failed: \(msg)"
            case .writingFailed(let msg):
                return "Video writing failed: \(msg)"
            }
        }
    }

    // MARK: - Public entry point

    /// Starts the export on a background thread.
    /// `completion` is always called on the main thread.
    static func export(
        imagePath: String,
        audioPath: String,
        outputPath: String,
        width: Int,
        height: Int,
        fps: Int,
        videoBitrate: Int,
        audioBitrate: Int,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try exportSync(
                    imagePath: imagePath,
                    audioPath: audioPath,
                    outputPath: outputPath,
                    width: width,
                    height: height,
                    fps: fps,
                    videoBitrate: videoBitrate,
                    audioBitrate: audioBitrate
                )
                DispatchQueue.main.async { completion(.success(outputPath)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    // MARK: - Synchronous implementation

    private static func exportSync(
        imagePath: String,
        audioPath: String,
        outputPath: String,
        width: Int,
        height: Int,
        fps: Int,
        videoBitrate: Int,
        audioBitrate: Int
    ) throws {

        // ── 1. Load image ──────────────────────────────────────────────────────
        guard let image = UIImage(contentsOfFile: imagePath) else {
            throw ExportError.imageLoadFailed(imagePath)
        }

        // ── 2. Measure audio duration ──────────────────────────────────────────
        let audioURL = URL(fileURLWithPath: audioPath)
        let audioAsset = AVURLAsset(
            url: audioURL,
            options: [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        )

        // Load duration synchronously via semaphore (required for precise timing)
        var audioDuration: Double = 0
        let durationSemaphore = DispatchSemaphore(value: 0)
        audioAsset.loadValuesAsynchronously(forKeys: ["duration", "tracks"]) {
            audioDuration = CMTimeGetSeconds(audioAsset.duration)
            durationSemaphore.signal()
        }
        durationSemaphore.wait()

        guard audioDuration > 0 else {
            throw ExportError.invalidAudioDuration
        }

        guard let audioTrack = audioAsset.tracks(withMediaType: .audio).first else {
            throw ExportError.audioTrackMissing
        }

        // ── 3. Build pixel buffer from image ───────────────────────────────────
        let pixelBuffer = try makePixelBuffer(from: image, width: width, height: height)

        // ── 4. Set up AVAssetWriter ────────────────────────────────────────────
        let outputURL = URL(fileURLWithPath: outputPath)
        try? FileManager.default.removeItem(at: outputURL)

        let writer: AVAssetWriter
        do {
            writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        } catch {
            throw ExportError.writerSetupFailed(error.localizedDescription)
        }

        // H.264 video input
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: videoBitrate,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                AVVideoMaxKeyFrameIntervalKey: fps,   // one I-frame per second
            ],
        ]
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput.expectsMediaDataInRealTime = false

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: [
                // 32BGRA is the format officially supported by AVFoundation's
                // H.264 encoder for pixel buffer input. 32ARGB is not guaranteed
                // and may produce garbled output or fail on hardware encoders.
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height,
            ]
        )

        guard writer.canAdd(videoInput) else {
            throw ExportError.writerSetupFailed("Cannot add video input to writer")
        }
        writer.add(videoInput)

        // AAC audio input (re-encode from MP3/AAC source)
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderBitRateKey: audioBitrate,
        ]
        let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        audioInput.expectsMediaDataInRealTime = false

        guard writer.canAdd(audioInput) else {
            throw ExportError.writerSetupFailed("Cannot add audio input to writer")
        }
        writer.add(audioInput)

        // AVAssetReader: decode audio source to PCM for re-encoding
        let audioReader: AVAssetReader
        do {
            audioReader = try AVAssetReader(asset: audioAsset)
        } catch {
            throw ExportError.writerSetupFailed("Cannot create AVAssetReader: \(error.localizedDescription)")
        }

        let audioReaderOutput = AVAssetReaderTrackOutput(
            track: audioTrack,
            outputSettings: [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsNonInterleaved: false,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false,
                // Force stereo output so channel count always matches the AAC
                // writer (AVNumberOfChannelsKey: 2). AVFoundation upmixes mono
                // sources automatically. Without this, a mono azan file produces
                // 1-channel PCM samples that the stereo AAC encoder rejects.
                AVNumberOfChannelsKey: 2,
                AVSampleRateKey: 44100,
            ]
        )
        audioReaderOutput.alwaysCopiesSampleData = false

        guard audioReader.canAdd(audioReaderOutput) else {
            throw ExportError.writerSetupFailed("Cannot add audio reader output")
        }
        audioReader.add(audioReaderOutput)

        // ── 5. Write ───────────────────────────────────────────────────────────
        writer.startWriting()
        audioReader.startReading()
        writer.startSession(atSourceTime: .zero)

        let totalFrames = Int(ceil(audioDuration * Double(fps)))
        let frameDuration = CMTimeMake(value: 1, timescale: Int32(fps))

        let group = DispatchGroup()
        var videoWriteError: Error?
        var audioWriteError: Error?

        // Drive video frames (same pixel buffer repeated for every frame)
        group.enter()
        var frameIndex = 0
        let videoQueue = DispatchQueue(label: "com.qiblatime.videoexport.video", qos: .userInitiated)
        videoInput.requestMediaDataWhenReady(on: videoQueue) {
            while videoInput.isReadyForMoreMediaData {
                if frameIndex >= totalFrames {
                    videoInput.markAsFinished()
                    group.leave()
                    return
                }
                let pts = CMTimeMultiply(frameDuration, multiplier: Int32(frameIndex))
                guard adaptor.append(pixelBuffer, withPresentationTime: pts) else {
                    videoWriteError = ExportError.writingFailed(
                        writer.error?.localizedDescription ?? "pixel buffer append failed at frame \(frameIndex)"
                    )
                    videoInput.markAsFinished()
                    group.leave()
                    return
                }
                frameIndex += 1
            }
        }

        // Drive audio samples (decode → PCM → re-encode to AAC)
        group.enter()
        let audioQueue = DispatchQueue(label: "com.qiblatime.videoexport.audio", qos: .userInitiated)
        audioInput.requestMediaDataWhenReady(on: audioQueue) {
            while audioInput.isReadyForMoreMediaData {
                if let sample = audioReaderOutput.copyNextSampleBuffer() {
                    guard audioInput.append(sample) else {
                        audioWriteError = ExportError.writingFailed(
                            writer.error?.localizedDescription ?? "audio sample append failed"
                        )
                        audioInput.markAsFinished()
                        group.leave()
                        return
                    }
                } else {
                    // All samples drained
                    audioInput.markAsFinished()
                    group.leave()
                    return
                }
            }
        }

        group.wait()

        if let err = videoWriteError ?? audioWriteError {
            writer.cancelWriting()
            throw err
        }

        // ── 6. Finalize ────────────────────────────────────────────────────────
        let finishSemaphore = DispatchSemaphore(value: 0)
        writer.finishWriting { finishSemaphore.signal() }
        finishSemaphore.wait()

        if writer.status == .failed {
            throw ExportError.writingFailed(
                writer.error?.localizedDescription ?? "finishWriting returned failure"
            )
        }
    }

    // MARK: - Pixel buffer helper

    /// Renders `image` into a new CVPixelBuffer of the exact target size.
    /// Uses aspect-fill scaling so the image covers the full canvas without
    /// letterboxing (matches the storyCanvas mode used on the Dart side).
    private static func makePixelBuffer(
        from image: UIImage,
        width: Int,
        height: Int
    ) throws -> CVPixelBuffer {
        // 32BGRA: the canonical format for AVFoundation video encoding on iOS.
        // CGContext bitmapInfo must match: byteOrder32Little + noneSkipFirst
        // produces BGRA byte layout in memory, which is what kCVPixelFormatType_32BGRA expects.
        let attrs: [CFString: Any] = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey: width,
            kCVPixelBufferHeightKey: height,
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
        ]

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width, height,
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &pixelBuffer
        )
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            throw ExportError.pixelBufferCreationFailed
        }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        // byteOrder32Little | noneSkipFirst = BGRA8888, matching kCVPixelFormatType_32BGRA
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue
        guard let ctx = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo
        ) else {
            throw ExportError.pixelBufferCreationFailed
        }

        // No y-flip needed: ctx.draw(cgImage, in:) in a raw CVPixelBuffer-backed
        // CGContext draws with the image's visual top at y=maxY (Quartz top),
        // which maps to pixel-buffer row 0. Adding a y-flip would double-invert
        // the image, producing a 180° upside-down video.
        if let cgImage = image.cgImage {
            let srcW = CGFloat(cgImage.width)
            let srcH = CGFloat(cgImage.height)
            let dstW = CGFloat(width)
            let dstH = CGFloat(height)
            // Aspect-fill: scale so the image covers the full canvas
            let scale = max(dstW / srcW, dstH / srcH)
            let drawW = srcW * scale
            let drawH = srcH * scale
            let x = (dstW - drawW) / 2.0
            let y = (dstH - drawH) / 2.0
            ctx.draw(cgImage, in: CGRect(x: x, y: y, width: drawW, height: drawH))
        }

        return buffer
    }
}
