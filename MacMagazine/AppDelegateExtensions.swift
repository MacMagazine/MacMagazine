//
//  AppDelegateExtensions.swift
//  MacMagazine
//
//  Created by Cassio Rossi on 23/05/2019.
//  Copyright © 2019 MacMagazine. All rights reserved.
//

import CoreSpotlight
import Kingfisher
import StoreKit
import UIKit

// MARK: - Notification Definitions -

extension Notification.Name {
	static let shortcutActionLastPost = Notification.Name("shortcutActionLastPost")
	static let shortcutActionRecentPost = Notification.Name("shortcutActionRecentPost")
	static let reloadWeb = Notification.Name("reloadWeb")
	static let scrollToTop = Notification.Name("scrollToTop")
	static let favoriteUpdated = Notification.Name("favoriteUpdated")
	static let updateSelectedPost = Notification.Name("updateSelectedPost")
    static let refreshAfterBackground = Notification.Name("refreshAfterBackground")
    static let reloadData = Notification.Name("reloadData")
    static let updateCookie = Notification.Name("updateCookie")
    static let reloadAfterLogin = Notification.Name("reloadAfterLogin")
}

// MARK: - Update content -

extension AppDelegate {
	func applicationWillEnterForeground(_ application: UIApplication) {
		NotificationCenter.default.post(name: .refreshAfterBackground, object: nil)

		// Check subscriptions and update status
		Subscriptions.shared.checkSubscriptions { response in
			var settings = Settings()
			settings.purchased = response
		}

		// Check if MM Live is active
		Settings().isMMLive { isLive in
			DispatchQueue.main.async {
				(UIApplication.shared.delegate as? AppDelegate)?.isMMLive = isLive
				if !isLive {
					TabBarController.shared.removeIndexes([0])
				} else {
					TabBarController.shared.resetTabs()
				}
			}
		}
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		if !Subscriptions.shared.isPurchasing {
			Settings().applyTheme()
		}
	}
}

// MARK: - Setup -

extension AppDelegate {
	func setup(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
		NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground),
											   name: UIApplication.willResignActiveNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground),
											   name: UIApplication.didEnterBackgroundNotification, object: nil)

		// Apply custom thmee (Dark/Light)
		Settings().applyTheme()

		// Apple Watch Session
		WatchSessionManager.shared.startSession()

		// AppStore Review
		if Settings().shouldAskForReview {
			if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
				DispatchQueue.main.async {
					SKStoreReviewController.requestReview(in: scene)
				}
			}
		}

		// Push Notification
		pushNotification = PushNotification()
		pushNotification?.setup(options: launchOptions)
	}
}

extension AppDelegate {
	@objc
	private func didEnterBackground() {
		Helper().showBadge()
	}
}

// MARK: - Splitview Delegate -

extension AppDelegate: UISplitViewControllerDelegate {
	func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
		guard let secondaryAsNavController = secondaryViewController as? UINavigationController,
			let topAsDetailController = secondaryAsNavController.topViewController as? PostsDetailViewController
			else {
				return false
		}
		return topAsDetailController.links.isEmpty
	}
}

// MARK: - Widget DeepLink -

extension AppDelegate {
    func application(_ application: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        widgetSpotlightPost = url.absoluteString
        return true
    }
}

// MARK: - Shortcut -

extension AppDelegate {
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        if shortcutItem.type == "openLastSeenPost" ||
            shortcutItem.type == "openMostRecentPost" {

            guard let tabController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.last?.rootViewController as? UITabBarController else {
                shortcutAction = shortcutItem.type == "openLastSeenPost" ? .shortcutActionLastPost : .shortcutActionRecentPost
                return
            }
            tabController.selectedIndex = 0
            NotificationCenter.default.post(name: shortcutItem.type == "openLastSeenPost" ? .shortcutActionLastPost : .shortcutActionRecentPost, object: nil)
        }
    }
}

// MARK: - Spotlight search -

extension AppDelegate {
	func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
		if userActivity.activityType == CSSearchableItemActionType {
			if let identifier = userActivity.userInfo? [CSSearchableItemActivityIdentifier] as? String {
                guard (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.last?.rootViewController as? UITabBarController != nil else {
                    widgetSpotlightPost = identifier
                    return true
                }
				showDetailController(with: identifier)
				return true
			}
		}
		return false
	}
}
