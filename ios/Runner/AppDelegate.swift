import UIKit
import Flutter
import AVFoundation

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

    let proximityRegistrar = registrar(forPlugin: "QiblaProximityChannel")
    let proximityChannel = FlutterEventChannel(
      name: "com.qiblatime/proximity",
      binaryMessenger: proximityRegistrar.messenger()
    )
    proximityChannel.setStreamHandler(proximityStreamHandler)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
