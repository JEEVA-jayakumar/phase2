import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging // Added for FCM

@main
@objc class AppDelegate: FlutterAppDelegate, MessagingDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Firebase
    FirebaseApp.configure()

    // Set UNUserNotificationCenter delegate
    UNUserNotificationCenter.current().delegate = self

    // Request notification permissions
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
        if let error = error {
          print("Error requesting notification permissions: \(error.localizedDescription)")
        }
        if granted {
          print("Notification permissions granted.")
          DispatchQueue.main.async {
            application.registerForRemoteNotifications()
          }
        } else {
          print("Notification permissions denied.")
        }
      }
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
      application.registerForRemoteNotifications()
    }

    // Set Messaging delegate
    Messaging.messaging().delegate = self

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - UNUserNotificationCenterDelegate Methods

  // Handle foreground notifications
  @available(iOS 10.0, *)
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    print("Will present notification: \(userInfo)")
    // Show the notification alert (banner, sound, badge)
    // You can customize this to show an in-app message or handle differently
    completionHandler([[.alert, .sound, .badge]])
  }

  // Handle user tapping on a notification
  @available(iOS 10.0, *)
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    print("Did receive notification response: \(userInfo)")
    // Pass the notification data to Flutter
    // (You might want to use a MethodChannel to send this data to your Flutter code)
    completionHandler()
  }

  // MARK: - Remote Notification Registration Callbacks

  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("Registered for remote notifications with device token: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
    // Pass device token to Firebase Messaging
    Messaging.messaging().apnsToken = deviceToken
  }

  override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("Failed to register for remote notifications: \(error.localizedDescription)")
  }

  // MARK: - MessagingDelegate Methods

  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("Firebase registration token: \(String(describing: fcmToken))")
    // You can send this token to your server if needed
    // Or store it for later use with Flutter.
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
        name: Notification.Name("FCMToken"),
        object: nil,
        userInfo: dataDict
    )
    // TODO: If necessary send token to application server.
    // Note: This callback is fired at each app startup and whenever a new token is generated.
  }
}
