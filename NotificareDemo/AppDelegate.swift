//
//  AppDelegate.swift
//  NotificareDemo
//
//  Created by Donka Nesheva on 19.11.24.
//

import UIKit
import CoreLocation
import NotificareKit
import NotificareGeoKit
import NotificarePushKit
import NotificarePushUIKit
import OneSignal

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private let locationManager = CLLocationManager()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let servicesInfo = NotificareServicesInfo(contentsOfFile: "NotificareServices.plist")
        Notificare.shared.configure(servicesInfo: servicesInfo)
        
        Notificare.shared.delegate = self
        Notificare.shared.geo().delegate = self
        Notificare.shared.push().delegate = self
        
        let notificationOpenedBlock: OSNotificationOpenedBlock = { result in
            // This block gets called when the user reacts to a notification received
            let notification: OSNotification = result.notification
            print("Received Notification: ", notification.notificationId ?? "no id")
            print("launchURL: ", notification.launchURL ?? "no launch url")

        }
        
        UNUserNotificationCenter.current().delegate = self
        OneSignal.setLaunchURLsInApp(true)
        OneSignal.setProvidesNotificationSettingsView(false)
        OneSignal.pause(inAppMessages: true)
        OneSignal.initWithLaunchOptions(launchOptions)
        OneSignal.setAppId("key")
        OneSignal.setNotificationOpenedHandler(notificationOpenedBlock)
        OneSignal.setLogLevel(.LL_VERBOSE, visualLevel: .LL_NONE)
        OneSignal.setExternalUserId("1234")
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications()
    }

}

extension AppDelegate {
    func enableTalkOnTheRoad(userTriggered: Bool = true)  {
        
        let authorizationStatus = CLLocationManager.authorizationStatus()
        
        if authorizationStatus == .denied || authorizationStatus == .restricted {
            disableTalkOnTheRoad()
            return
        }
        
        if authorizationStatus != .authorizedWhenInUse || authorizationStatus != .authorizedAlways {
            locationManager.requestWhenInUseAuthorization()
        }

        if authorizationStatus != .authorizedAlways {
            locationManager.requestAlwaysAuthorization()
        }
        
        Task { await enableNotificare() }
    }
    
    private func enableNotificare() async {
        
        if #available(iOS 14.0, *) {
            Notificare.shared.push().presentationOptions = [.banner, .badge, .sound, .list]
        } else {
            Notificare.shared.push().presentationOptions = [.alert, .badge, .sound]
        }
        
        Task {
            do {
                try await Notificare.shared.launch()
                
                self.setUserData()
                
                let _ = try await Notificare.shared.push().enableRemoteNotifications()
                Notificare.shared.geo().enableLocationUpdates()
            } catch {
                print("Error enabling Notificare. ", error)
            }
        }
    }
    
    private func setUserData() {
        Notificare.shared.device().updateUser(userId: "demo-user", userName: nil) { result in
            print(result)
            
            var userData: NotificareUserData = [String: String]()

            userData["panelistID"] = "dee17ce0-2aee-11ee-b24f-058dafc55441"
            userData["country"] = "Austria"
            userData["gender"] = "female"
            userData["birthday"] = "01-06-1990"
            userData["province"] = "Salzburg"
            
            Notificare.shared.device().updateUserData(userData) { _ in }
        }
    }
    
    func disableTalkOnTheRoad() { 
        Task { await disableNotificare(relaunchOS: true) }
    }
    
    func disableNotificare(relaunchOS: Bool = false) async {
        Task {
            do {
                if Notificare.shared.push().hasRemoteNotificationsEnabled {
                    try await Notificare.shared.push().disableRemoteNotifications()
                    
                    // re-enable OneSignal because it stops receiving notifications
                    if relaunchOS {
                        OneSignal.initWithLaunchOptions()
                    }
                }
                if Notificare.shared.geo().hasLocationServicesEnabled {
                    Notificare.shared.geo().disableLocationUpdates()
                }
            } catch {}
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // We need this because OneSignal makes ThirdPartyApplicationDelegate to be UNUserNotificationCenter delegate
    // https://docs.notifica.re/sdk/v3/ios/customizations/#disable-unusernotificationcenter-delegate
//
    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Notificare.shared.push().application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Notificare.shared.push().application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }

    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Notificare.shared.push().application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
    }
    
    @MainActor
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        // Pass the event to Notificare.
        await Notificare.shared.push().userNotificationCenter(center, didReceive: response)
    }

    @MainActor
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        let _ = await Notificare.shared.push().userNotificationCenter(center, willPresent: notification)
        
        if #available(iOS 14.0, *) {
            return [.banner, .badge, .sound, .list]
        } else {
            return [.badge, .sound]
        }
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        Notificare.shared.push().userNotificationCenter(center, openSettingsFor: notification)
    }
}

extension AppDelegate: NotificareDelegate {
    public func notificare(_ notificare: Notificare, onReady application: NotificareApplication) {
        print("Notificare OnReady State")
    }
}

extension AppDelegate: NotificarePushDelegate {
    
    public func notificare(_ notificare: NotificarePush, didOpenNotification notification: NotificareNotification) {
        print(notification)
    }
}

extension AppDelegate: NotificareGeoDelegate {
    public func notificare(_: NotificareGeo, didUpdateLocations locations: [NotificareLocation]) {
        print("-----> Locations updated = \(locations)")
    }

    public func notificare(_: NotificareGeo, didFailWith error: Error) {
        print("-----> Location services failed = \(error)")
    }
}
