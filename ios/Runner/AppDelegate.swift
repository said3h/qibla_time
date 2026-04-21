import UIKit
import Flutter
import AVFoundation
import Photos

final class QiblaProximityStreamHandler: NSObject, FlutterStreamHandler {
  private let notificationCenter = NotificationCenter.default
  private let device = UIDevice.current
  private var proximityObserver: NSObjectProtocol?

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    device.isProximityMonitoringEnabled = true
    guard device.isProximityMonitoringEnabled else {
      return FlutterError(
        code: "PROXIMITY_UNAVAILABLE",
        message: "This device does not expose a proximity sensor.",
        details: nil
      )
    }

    proximityObserver = notificationCenter.addObserver(
      forName: UIDevice.proximityStateDidChangeNotification,
      object: device,
      queue: .main
    ) { notification in
      guard let device = notification.object as? UIDevice else { return }
      events(device.proximityState ? 1 : 0)
    }

    events(device.proximityState ? 1 : 0)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    if let observer = proximityObserver {
      notificationCenter.removeObserver(observer)
      proximityObserver = nil
    }
    device.isProximityMonitoringEnabled = false
    return nil
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let proximityStreamHandler = QiblaProximityStreamHandler()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback)
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print("Failed to configure AVAudioSession for Quran playback: \(error)")
    }

    GeneratedPluginRegistrant.register(with: self)

    if let proximityRegistrar = registrar(forPlugin: "QiblaProximityChannel") {
      let proximityChannel = FlutterEventChannel(
        name: "com.qiblatime/proximity",
        binaryMessenger: proximityRegistrar.messenger()
      )
      proximityChannel.setStreamHandler(proximityStreamHandler)
    }

    configureGalleryChannel()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func configureGalleryChannel() {
    guard let galleryRegistrar = registrar(forPlugin: "QiblaGalleryChannel") else {
      return
    }

    let galleryChannel = FlutterMethodChannel(
      name: "com.qiblatime/gallery",
      binaryMessenger: galleryRegistrar.messenger()
    )

    galleryChannel.setMethodCallHandler { [weak self] (
      call: FlutterMethodCall,
      result: @escaping FlutterResult
    ) in
      switch call.method {
      case "saveVideoToGallery":
        guard
          let arguments = call.arguments as? [String: Any],
          let path = arguments["path"] as? String,
          !path.isEmpty
        else {
          result(FlutterError(
            code: "INVALID_ARGS",
            message: "Missing video path",
            details: nil
          ))
          return
        }

        guard let self = self else {
          result(FlutterError(
            code: "SAVE_VIDEO_FAILED",
            message: "Failed to save video.",
            details: nil
          ))
          return
        }

        self.saveVideoToGallery(path: path, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func saveVideoToGallery(path: String, result: @escaping FlutterResult) {
    let fileURL = URL(fileURLWithPath: path)
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      result(FlutterError(
        code: "SAVE_VIDEO_FAILED",
        message: "Video file does not exist.",
        details: nil
      ))
      return
    }

    guard UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(fileURL.path) else {
      result(FlutterError(
        code: "SAVE_VIDEO_FAILED",
        message: "Video file is not compatible with the photo library.",
        details: nil
      ))
      return
    }

    PHPhotoLibrary.shared().performChanges({
      _ = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
    }) { success, error in
      DispatchQueue.main.async {
        if success {
          result(true)
        } else {
          result(FlutterError(
            code: "SAVE_VIDEO_FAILED",
            message: error?.localizedDescription ?? "Failed to save video.",
            details: nil
          ))
        }
      }
    }
  }
}
