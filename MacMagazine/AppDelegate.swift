//
//  AppDelegate.swift
//  MacMagazine
//
//  Created by Cassio Rossi on 18/08/17.
//  Copyright © 2017 MacMagazine. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	// MARK: - Properties -

	var window: UIWindow?
	var previousController: UIViewController?
    var supportedInterfaceOrientation: UIInterfaceOrientationMask = .all
    var isMMLive: Bool = false
    var widgetSpotlightPost: String?
    var shortcutAction: Notification.Name?
	var pushNotification: PushNotification?
    var tabBarController: UITabBarController?

    // MARK: - Window lifecycle -

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		setup(launchOptions)
		return true
	}

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return supportedInterfaceOrientation
    }

}
