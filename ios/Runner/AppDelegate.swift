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
    GMSServices.provideAPIKey("AIzaSyAGPiHCvO7ES5wj9GMVFzHnEKOTNdiHrLo")
    // Must be set before plugins register: firebase_messaging captures this as
    // the original delegate and forwards non-FCM (local) notifications to it,
    // which is what lets flutter_local_notifications present in the foreground.
    UNUserNotificationCenter.current().delegate = self
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
