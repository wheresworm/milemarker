import UIKit
import Flutter
import GoogleMaps  // 👈 Add this if it’s not already there

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyCZaS4SxazMkerP7V8qK0JhlsOBJQc5Avs")  // 👈 Add this line

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
