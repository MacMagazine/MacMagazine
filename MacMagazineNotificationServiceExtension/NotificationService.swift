//
//  NotificationService.swift
//  MacMagazineNotificationServiceExtension
//
//  Created by Cassio Rossi on 20/04/2019.
//  Copyright © 2019 MacMagazine. All rights reserved.
//

import OneSignalExtension
import UserNotifications
import WidgetKit

class NotificationService: UNNotificationServiceExtension {

	var contentHandler: ((UNNotificationContent) -> Void)?
	var receivedRequest: UNNotificationRequest?
	var bestAttemptContent: UNMutableNotificationContent?

	override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
		self.receivedRequest = request
		self.contentHandler = contentHandler
		bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        WidgetCenter.shared.reloadAllTimelines()

        if let bestAttemptContent = bestAttemptContent,
		   let receivedRequest = receivedRequest {
			OneSignalExtension.didReceiveNotificationExtensionRequest(receivedRequest, with: bestAttemptContent, withContentHandler: contentHandler)
		}
	}

	override func serviceExtensionTimeWillExpire() {
		// Called just before the extension will be terminated by the system.
		// Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
		if let contentHandler = contentHandler,
           let bestAttemptContent = bestAttemptContent,
           let receivedRequest = receivedRequest {
			OneSignalExtension.serviceExtensionTimeWillExpireRequest(receivedRequest, with: bestAttemptContent)
			contentHandler(bestAttemptContent)
		}
	}

}
