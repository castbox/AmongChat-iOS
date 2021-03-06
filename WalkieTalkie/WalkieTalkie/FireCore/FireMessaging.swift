 //
 //  FireMessaging.swift
 //  Castbox
 //
 //  Created by ChenDong on 2017/6/1.
 //  Copyright © 2017年 Guru. All rights reserved.
 //
 
 import UIKit
 import UserNotifications
 import FirebaseMessaging
 import FirebaseInstanceID
 import RxSwift
 import CastboxDebuger
 
 /// https://firebase.google.com/docs/cloud-messaging/?authuser=0
 fileprivate let defaultHotTopic = ["hot-amongus"]
 private let oldHotTopic = ["hot"]

 
 fileprivate func cdPrint(_ message: Any) {
     Debug.info("[FireMessaging]-\(message)")
 }
 
 class FireMessaging: NSObject {
    
    static let shared = FireMessaging()
    
    override init() {
        super.init()
        /// https://firebase.google.com/docs/cloud-messaging/ios/client?authuser=0
        /// 对于运行 iOS 10 及更高版本的设备，您必须在应用完成启动之前将您的委托对象分配给 UNUserNotificationCenter 对象（以便接收显示通知）和 FIRMessaging 对象（以便接收数据消息）。例如，在 iOS 应用中，您必须在 applicationWillFinishLaunching: 或 applicationDidFinishLaunching: 方法中分配委托对象。
        //        Messaging.messaging().shouldEstablishDirectChannel = false
        Messaging.messaging().delegate = self
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }
        
        _ = NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification, object: nil)
            .asObservable()
            .subscribe(onNext: { _ in
                //如果已获得授权，则直接申请
                if self.grantedPushAuthorized {
                    self.requestPermissionIfNotGranted()
                }
            })
        
//        _ = Observable.combineLatest(fcmTokenValue(), Settings.shared.isOpenSubscribeHotTopic.replay())
//            .filter { $0.0.fcmToken != nil }
//            .map { $0.1 }
//            .debug()
//            .observeOn(MainScheduler.asyncInstance)
//            .subscribe(onNext: { value in
//                oldHotTopic.forEach { topic in
//                    Messaging.messaging().unsubscribe(fromTopic: topic)
//                }
//                defaultHotTopic.forEach { topic in
//                    if value {
//                        Messaging.messaging().subscribe(toTopic: topic) { error in
//                            cdPrint("[Messaging.messaging()] subscribe result: \(error.debugDescription)")
//                        }
//                    } else {
//                        Messaging.messaging().unsubscribe(fromTopic: topic) { error in
//                            cdPrint("[Messaging.messaging()] unsubscribe result: \(error.debugDescription)")
//                        }
//                    }
//                }
//            })
        
    }
    
    private let fcmTokenSubject = PublishSubject<FireMessaging>()
    private let anpsMessageSubject = PublishSubject<APNSMessage>()
    private let anpsMessageWillShowSubject = PublishSubject<APNSMessage>()
    
    private(set) var fcmToken: String? {
        didSet {
            if oldValue != fcmToken {
                fcmTokenSubject.onNext(self)
            }
        }
    }
    
    var apnsTokenString: String? {
        Messaging.messaging().apnsToken?.hexString
    }
    
    var grantedPushAuthorized: Bool {
        let sem = DispatchSemaphore(value: 0)
        var result = false
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            result = settings.authorizationStatus == .authorized
            sem.signal()
        }
        _ = sem.wait(timeout: .distantFuture)
        return result
    }
    
    /// FCM token Observable，监听来告诉 Server Token 更新
    func fcmTokenValue() -> Observable<FireMessaging> {
        return fcmTokenSubject.startWith(self)
    }
    /// APNSMessage Observable，监听来处理 URI
    func anpsMessageValue() -> Observable<APNSMessage> {
        return anpsMessageSubject
    }
    /// APNSMessage will show Observable，监听来处理 URI
    func anpsMessageWillShowValue() -> Observable<APNSMessage> {
        return anpsMessageWillShowSubject
    }
    
    func requestPermissionIfNotGranted() {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { (succeed, error) in
                cdPrint("[UNUserNotificationCenter.requestAuthorization] \(succeed ? "request succeed": "request failed")")
                mainQueueDispatchAsync {
                    UIApplication.shared.registerForRemoteNotifications()
                    
                    //follow
                    mainQueueDispatchAsync(after: 1) {
                        UIApplication.appDelegate?.followInvitedUserhandler?()
                        UIApplication.appDelegate?.followInvitedUserhandler = nil
                    }
                }
                //
            })
        }
    }
    
//    private func scheduleNotifications()
//    {
//        for notification in notifications
//        {
//            let content      = UNMutableNotificationContent()
//            content.title    = notification.title
//            content.sound    = .default
//
//            let trigger = UNCalendarNotificationTrigger(dateMatching: notification.datetime, repeats: false)
//
//            let request = UNNotificationRequest(identifier: notification.id, content: content, trigger: trigger)
//
//            UNUserNotificationCenter.current().add(request) { error in
//
//                guard error == nil else { return }
//
//                print("Notification scheduled! --- ID = \(notification.id)")
//            }
//        }
//    }

    
    func openAppSettingUrlIfNeed() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            mainQueueDispatchAsync {
                if settings.authorizationStatus == .notDetermined {
                    self.requestPermissionIfNotGranted()
                } else if settings.authorizationStatus == .denied {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:]) { _ in
                        
                    }
                }
            }
        }
    }
    
    func handleRemoteNotificationPayload(_ userInfo: [AnyHashable: Any]!, withActionIdentifier actionIdentifier: String? = nil) {
        guard let msg = APNSMessage(userInfo) else { return }
        // 打开推送 埋点
        let uriList = msg.uri.split(separator: "/")
        if let type = uriList.safe(0), let id = uriList.safe(1) {
//            Analytics.log(event: "push_open", category: String(type), name: String(id), value: nil)
//            Logger.PageShow.logger("push_open", String(type), String(id), nil)
//            if type == "live"{
//                Logger.PageShow.logger("lv_rm_imp", "lv_notifi", String(id), nil)
//            }
        }
        anpsMessageSubject.onNext(msg)
        let _ = Request.pushEvent(.DeviceOpen, notiUserInfo: userInfo)
            .subscribe()
        addPushLogger(.open, msg: msg)
    }
 }
 
 /// iOS 10 之前的通知处理
 /*
  1. app 未启动时，发送通知，点击通知 body 打开 app，didFinishLaunchingWithOptions 方法中的 launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey] 会有值，其后
  “会“ 调用 didReceiveRemoteNotification 方法
  2. app 未启动时，发送通知，点击通知 action 打开 app，didFinishLaunchingWithOptions 方法中的 launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey] 无值，但其后
  “会“ 调用 handleActionWithIdentifier 方法
  3. app 启动，在后台时，点击通知 body 打开 app，直接调用 didReceiveRemoteNotification 方法
  4. app 启动，在后台时，点击通知 action 打开 app，直接调用 handleActionWithIdentifier 方法
  5. app 启动，在前台时，直接调用 didReceiveRemoteNotification 方法
  */
 extension FireMessaging {
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let aps = userInfo["aps"] as? [AnyHashable: Any],
            let strCtntAvlbl = aps["content-available"] as? String,
            let iCtntAvlbl = Int(strCtntAvlbl),
            iCtntAvlbl == 1 {
            //静默推送处理分支
            var state: String = "unknown"
            switch application.applicationState {
            case .active:
                state = "active"
            case .inactive:
                state = "inactive"
            case .background:
                state = "background"
            default:
                ()
            }
            GuruAnalytics.log(event: "silent_push", category: state, name: nil, value: nil)
            NSLog("Silent Push Detected")
        } else {
            handleRemoteNotificationPayload(userInfo)
        }
        let _ = Request.pushEvent(.DeviceReceive, notiUserInfo: userInfo)
            .subscribe()
        addPushLogger(.receive, msg: APNSMessage(userInfo))
        completionHandler(.noData)
    }
    
    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [AnyHashable: Any], withResponseInfo responseInfo: [AnyHashable: Any], completionHandler: @escaping () -> Void) {
        /// 目前没有支持 action
        assertionFailure("received unexpected notification cation")
    }
 }
 
 /// iOS 10 之后的通知处理
 /*
  1. app 未启动时，发送通知，点击通知打开 app，didFinishLaunchingWithOptions 方法中的 launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey] 会有值，其后还会调用 didReceiveNotificationResponse 方法
  2. app 启动，在后台时，点击通知打开 app，直接调用 didReceiveNotificationResponse 方法
  3. app 启动，在前台时，首先会调用 willPresentNotification 方法，询问通过什么样的方式弹出通知。如果弹出通知后，其后还会调用 didReceiveNotificationResponse 方法
  */
 extension FireMessaging: UNUserNotificationCenterDelegate {
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        cdPrint("userNotificationCenter willPresent- \(notification.request.content.userInfo)")
        let nilableMessage = APNSMessage(notification.request.content.userInfo)
        addPushLogger(.receive, msg: nilableMessage)
        guard let msg = nilableMessage else {
            return
        }
        anpsMessageWillShowSubject.onNext(msg)
        
        let _ = Request.pushEvent(.DeviceReceive, notiUserInfo: notification.request.content.userInfo).subscribe(onSuccess: { (_) in })
        
        if nilableMessage?.canShowWhenActive == true {
            addPushLogger(.impression, msg: nilableMessage)
            completionHandler([.alert, .badge, .sound])
        } else {
            completionHandler([])
        }
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let payload = response.notification.request.content.userInfo
        cdPrint("userNotificationCenter didReceive- \(payload)")
        handleRemoteNotificationPayload(payload, withActionIdentifier: response.actionIdentifier)
        completionHandler()
    }
    
    func addPushLogger(_ event: Logger.Push.Event, msg: APNSMessage?) {
//        var category: Logger.Push.Category {
//            msg?.uri != nil ? .hot : .recommend
//        }
//        let home = URI.Homepage(msg?.uri.url?.queryParameters ?? [:])
//        Logger.Push.log(category, home?.channelName)
        Logger.Push.log(event: event, source: msg?.pushSourceType)
    }
 }
 
 extension FireMessaging: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        /// 应用启动时会调用一次
        /// FCM token 更新，也可监听 Notification.Name.MessagingRegistrationTokenRefreshed 通知，读取 Messaging.messaging().fcmToken 属性
        self.fcmToken = fcmToken
        cdPrint("fcmToken: \(fcmToken)")
    }
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        /// 接收 data 消息，不是通知消息，因此这个方法目前不应当被调用
        assertionFailure("received unexpected data message from FCM")
    }
 }
 
 extension FireMessaging {
    struct APNSMessage {
        let uri: String
        let userInfo: [AnyHashable: Any]
        
        init?(_ userInfo: [AnyHashable: Any]) {
            guard let uri = userInfo["uri"] as? String else { return nil }
            self.userInfo = userInfo
            self.uri = uri
        }
        
        var pushSourceType: String {
            let queries: [String : Any] = uri.url?.queryParameters ?? [:]
            let sourceType = queries["push_source_type"] as? String ?? ""
            return sourceType
        }
        
        //消息得最小支持版本，小余此版本则提示升级
        var version: String? {
            let queries: [String : Any] = uri.url?.queryParameters ?? [:]
            return queries["version"] as? String
        }
        
        var canShowWhenActive: Bool {
            !["invite_join_room", "invite_join_group", "new_group_room", "new_dm"].contains(pushSourceType)
        }
    }
 }
