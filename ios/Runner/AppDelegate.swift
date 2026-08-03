import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    // Evita franja blanca bajo el home indicator (fondo nativo por defecto es blanco).
    window?.backgroundColor = UIColor.black
    window?.rootViewController?.view.backgroundColor = UIColor.black
    return ok
  }
}
