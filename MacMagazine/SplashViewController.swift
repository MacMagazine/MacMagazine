//
//  SplashViewController.swift
//  MacMagazine
//
//  Created by Cassio Rossi on 08/06/2019.
//  Copyright © 2019 MacMagazine. All rights reserved.
//

import UIKit

class SplashViewController: UIViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        view.backgroundColor = Settings().isDarkMode ? .black : .white

        // Check subscriptions and update status
        Subscriptions.shared.checkSubscriptions { response in
            var settings = Settings()
            settings.purchased = response
        }

		Settings().isMMLive { isLive in
            DispatchQueue.main.async {
                (UIApplication.shared.delegate as? AppDelegate)?.isMMLive = isLive
            }

            delay(0.6) {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)

                guard let controller = storyboard.instantiateViewController(withIdentifier: "main") as? UITabBarController,
                      let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                      let splitViewController = controller.viewControllers?[1] as? UISplitViewController,
                      let window = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.last else {
                    return
                }

                splitViewController.delegate = appDelegate
				splitViewController.preferredDisplayMode = UISplitViewController.DisplayMode.oneBesideSecondary
                splitViewController.preferredPrimaryColumnWidthFraction = 0.33

                UIView.transition(with: window,
                                  duration: 0.4,
                                  options: .transitionCrossDissolve,
                                  animations: {
                    window.rootViewController = controller
                    if !isLive {
                        TabBarController.shared.removeIndexes([0])
                    }
                },
                                  completion: { finished in
                    if finished &&
                        (UIApplication.shared.delegate as? AppDelegate)?.widgetSpotlightPost != nil {
                        TabBarController.shared.selectIndex(isLive ? 1 : 0)
                    }
                })
            }
        }
	}
}
