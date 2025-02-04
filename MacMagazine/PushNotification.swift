//
//  PushNotification.swift
//  MacMagazine
//
//  Created by Cassio Rossi on 21/04/2019.
//  Copyright © 2019 MacMagazine. All rights reserved.
//

import Kingfisher
import OneSignalFramework
import UIKit
import UserNotifications
import WidgetKit

class PushNotification: NSObject, ObservableObject {
	@Published var newContentAvailable: String?

	func setup(options: [UIApplication.LaunchOptionsKey: Any]?) {
        let key: [UInt8] = [37, 68, 65, 114, 92, 85, 93, 84, 76, 70, 82, 120, 100, 98, 86, 91, 80, 83, 89, 121, 69, 66, 38, 72, 91, 92, 86, 88, 18, 7, 127, 106, 120, 91, 14, 83]

		OneSignal.initialize(Obfuscator().reveal(key: key), withLaunchOptions: options)
		OneSignal.Notifications.addForegroundLifecycleListener(self)
		OneSignal.Notifications.addClickListener(self)

		OneSignal.Notifications.requestPermission({ [weak self] _ in
			self?.setLocalNotification()
		}, fallbackToSettings: false)
	}
}

class Database {
	func update(onCompletion: (() -> Void)? = nil) {
		var images: [String] = []
		API().getPosts(page: 0) { post in

			DispatchQueue.main.async {
				guard let post = post else {
					// Prefetch images to be able to sent to Apple Watch
					let urls = images.compactMap { URL(string: $0) }
					let prefetcher = ImagePrefetcher(urls: urls)
					prefetcher.start()

                    WidgetCenter.shared.reloadAllTimelines()

                    onCompletion?()
                    return
				}
				images.append(post.artworkURL)
				CoreDataStack.shared.save(post: post)
			}
		}
	}
}

// MARK: - Local notification -

extension PushNotification: UNUserNotificationCenterDelegate {
    func setLocalNotification(for event: MMLive? = nil) {
        UNUserNotificationCenter.current().delegate = self

        var localEvent = event
        if event == nil {
            guard let saved = UserDefaults.standard.object(forKey: Definitions.mmLive) as? Data,
                  let decoded = try? JSONDecoder().decode(MMLive.self, from: saved) else {
                return
            }
            localEvent = decoded
        }

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {

                guard let event = localEvent  else {
                    return
                }

                let startInterval = event.inicio.timeIntervalSince(Date())
                if startInterval > 0 {
                    let start = UNMutableNotificationContent()
                    start.title = "MM Live irá começar"
                    start.subtitle = "Acompanhe o evento ao vivo!"
                    start.sound = UNNotificationSound.default

                    // show this notification five seconds from `inicio`
                    let startTrigger = UNTimeIntervalNotificationTrigger(timeInterval: startInterval, repeats: false)

                    // choose a random identifier
                    let startRequest = UNNotificationRequest(identifier: "MMLiveWillStart", content: start, trigger: startTrigger)

                    // add our notification request
                    UNUserNotificationCenter.current().add(startRequest)
                }

                let endInterval = event.fim.timeIntervalSince(Date())
                if endInterval > 0 {
                    let end = UNMutableNotificationContent()
                    end.title = "MM Live foi encerrado"
                    end.subtitle = "Obrigado por nos acompanhar!"
                    end.sound = UNNotificationSound.default

                    // show this notification five seconds from `fim`
                    let endTrigger = UNTimeIntervalNotificationTrigger(timeInterval: endInterval, repeats: false)

                    // choose a random identifier
                    let endRequest = UNNotificationRequest(identifier: "MMLiveEnded", content: end, trigger: endTrigger)

                    // add our notification request
                    UNUserNotificationCenter.current().add(endRequest)
                }
            }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        handleMMLive()
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
		Database().update { [weak self] in
			self?.handleMMLive(true)
			completionHandler()
		}
    }

    func handleMMLive(_ select: Bool = false) {
        Settings().isMMLive { isLive in
            DispatchQueue.main.async {
                (UIApplication.shared.delegate as? AppDelegate)?.isMMLive = isLive
                if isLive {
                    TabBarController.shared.resetTabs()
                } else {
                    TabBarController.shared.removeIndexes([0])
                }
                if select {
                    TabBarController.shared.selectIndex(0)
                }
            }
        }
    }
}

extension PushNotification: OSNotificationLifecycleListener {
	func onWillDisplay(event: OSNotificationWillDisplayEvent) {
		event.preventDefault()
        logD("")
		Database().update {
			event.notification.display()
		}
	}
}

extension PushNotification: OSNotificationClickListener {
	func onClick(event: OSNotificationClickEvent) {
		let notification: OSNotification = event.notification
        logD(notification)
		guard let additionalData = notification.additionalData,
			  let content = additionalData as? [String: String] else {
			return
		}
		logD(content["url"])
        Database().update { [weak self] in
            self?.newContentAvailable = content["url"]
        }
	}
}
