import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

// Helper function to handle background messages
// Must be a top-level function (not a class method)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  // await Firebase.initializeApp(); // Uncomment if you need to initialize Firebase here

  print("Handling a background message: ${message.messageId}");
  print('Message data: ${message.data}');
  if (message.notification != null) {
    print('Message also contained a notification: ${message.notification}');
  }
}

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission for iOS and web
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }

    // Get the FCM token
    String? fcmToken = await _firebaseMessaging.getToken();
    if (kDebugMode) {
      print("Firebase Messaging Token: $fcmToken");
    }
    // You would typically send this token to your server

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }

      if (message.notification != null) {
        if (kDebugMode) {
          print('Message also contained a notification: ${message.notification}');
        }
        // Here you could display a local notification using flutter_local_notifications
        // or update the UI directly.
      }
    });

    // Handle notification opened app from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) {
          print('Notification caused app to open from terminated state:');
          print('Message data: ${message.data}');
        }
        if (message.notification != null) {
          if (kDebugMode) {
            print('Message also contained a notification: ${message.notification}');
          }
        }
        // Navigate to a specific screen based on message data, if needed
        // _handleMessageNavigation(message.data);
      }
    });

    // Handle notification opened app from background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Notification caused app to open from background state:');
        print('Message data: ${message.data}');
      }
      if (message.notification != null) {
        if (kDebugMode) {
          print('Message also contained a notification: ${message.notification}');
        }
      }
      // Navigate to a specific screen based on message data, if needed
      // _handleMessageNavigation(message.data);
    });

    // Set the background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Example of how you might navigate based on message data
  // void _handleMessageNavigation(Map<String, dynamic> data) {
  //   if (data.containsKey('screen')) {
  //     String screen = data['screen'];
  //     // Use your navigation logic here, e.g., Navigator.pushNamed(context, screen);
  //     print("Navigate to screen: $screen");
  //   }
  // }

  Future<String?> getFcmToken() async {
    return await _firebaseMessaging.getToken();
  }
}
