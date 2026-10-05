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
    // Written into the built Info.plist by the "Inject Maps API Key" build
    // phase from --dart-define-from-file=env/app.json.
    if let googleMapsApiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !googleMapsApiKey.isEmpty {
      GMSServices.provideAPIKey(googleMapsApiKey)
    } else {
      NSLog("GMSApiKey missing — build with --dart-define-from-file=env/app.json; Google Maps will not render.")
    }
    // Must be set before plugins register: firebase_messaging captures this as
    // the original delegate and forwards non-FCM (local) notifications to it,
    // which is what lets flutter_local_notifications present in the foreground.
    UNUserNotificationCenter.current().delegate = self
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
