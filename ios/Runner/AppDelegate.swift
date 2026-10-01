import Flutter
import UIKit
import GoogleMaps
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let googleMapsApiKey = Self.dotEnvValue(for: "G_CLIENTID_IOS") {
      GMSServices.provideAPIKey(googleMapsApiKey)
    }
    // Must be set before plugins register: firebase_messaging captures this as
    // the original delegate and forwards non-FCM (local) notifications to it,
    // which is what lets flutter_local_notifications present in the foreground.
    UNUserNotificationCenter.current().delegate = self
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Reads a value from the .env file bundled as a Flutter asset (see pubspec.yaml).
  private static func dotEnvValue(for key: String) -> String? {
    let assetKey = FlutterDartProject.lookupKey(forAsset: ".env")
    guard let path = Bundle.main.path(forResource: assetKey, ofType: nil),
          let contents = try? String(contentsOfFile: path, encoding: .utf8) else {
      return nil
    }
    for line in contents.components(separatedBy: .newlines) {
      let parts = line.split(separator: "=", maxSplits: 1)
      guard parts.count == 2,
            parts[0].trimmingCharacters(in: .whitespaces) == key else { continue }
      let value = parts[1].trimmingCharacters(in: .whitespaces)
        .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
      return value.isEmpty ? nil : value
    }
    return nil
  }
}
