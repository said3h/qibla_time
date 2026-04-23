// VideoExportChannel.swift
// Registers the 'com.qiblatime/video_export' MethodChannel on iOS and
// routes 'exportStillVideo' calls to StillVideoExporter.
//
// Mirrors the Android handler in MainActivity.kt (method channel section).
// Same parameter contract: imagePath, audioPath, outputPath, width, height,
// fps, videoBitrate, audioBitrate.

import Flutter
import Foundation

final class VideoExportChannel {

    /// Call this once from AppDelegate.application(_:didFinishLaunchingWithOptions:).
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.qiblatime/video_export",
            binaryMessenger: registrar.messenger()
        )
        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "exportStillVideo":
                VideoExportChannel.handleExport(call: call, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    // MARK: - Private handler

    private static func handleExport(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        guard
            let args = call.arguments as? [String: Any],
            let imagePath = args["imagePath"] as? String, !imagePath.isEmpty,
            let audioPath = args["audioPath"] as? String, !audioPath.isEmpty,
            let outputPath = args["outputPath"] as? String, !outputPath.isEmpty
        else {
            result(FlutterError(
                code: "INVALID_ARGS",
                message: "imagePath, audioPath and outputPath are required and must be non-empty",
                details: nil
            ))
            return
        }

        let width        = args["width"]        as? Int ?? 1080
        let height       = args["height"]       as? Int ?? 1920
        let fps          = args["fps"]          as? Int ?? 30
        let videoBitrate = args["videoBitrate"] as? Int ?? 2_500_000
        let audioBitrate = args["audioBitrate"] as? Int ?? 192_000

        StillVideoExporter.export(
            imagePath:    imagePath,
            audioPath:    audioPath,
            outputPath:   outputPath,
            width:        width,
            height:       height,
            fps:          fps,
            videoBitrate: videoBitrate,
            audioBitrate: audioBitrate
        ) { exportResult in
            // Completion is already dispatched to main thread by StillVideoExporter
            switch exportResult {
            case .success(let path):
                result(path)
            case .failure(let error):
                result(FlutterError(
                    code: "EXPORT_FAILED",
                    message: error.localizedDescription,
                    details: nil
                ))
            }
        }
    }
}
