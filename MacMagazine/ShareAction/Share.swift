//
//  Share.swift
//  MacMagazine
//
//  Created by Cassio Rossi on 15/04/2019.
//  Copyright © 2019 MacMagazine. All rights reserved.
//

import UIKit

struct Share {
    func present<T>(at location: T?, using items: [Any], activities: [UIActivityExtensions]? = nil) {
		let safari = UIActivityExtensions(title: "Abrir no Safari", image: UIImage(systemName: "safari")) { items in
			for item in items {
				guard let url = URL(string: "\(item)") else {
					continue
				}
				if UIApplication.shared.canOpenURL(url) {
					UIApplication.shared.open(url, options: [:], completionHandler: nil)
				}
			}
		}

		let chrome = UIActivityExtensions(title: "Abrir no Chrome", image: UIImage(named: "chrome")) { items in
			for item in items {
				guard let url = URL(string: "\(item)".replacingOccurrences(of: "http", with: "googlechrome")) else {
					continue
				}
				if UIApplication.shared.canOpenURL(url) {
					UIApplication.shared.open(url, options: [:], completionHandler: nil)
				}
			}
		}
		var applicationActivities = [UIActivityExtensions]()
        if let activities = activities {
            applicationActivities.append(contentsOf: activities)
        }
        applicationActivities.append(safari)
		if let url = URL(string: "googlechrome://"),
			UIApplication.shared.canOpenURL(url) {
            applicationActivities.append(chrome)
		}

        let customCopy = UIActivityExtensions(title: "Copiar Link", image: UIImage(systemName: "link")) { items in
            for item in items {
                guard let url = URL(string: "\(item)") else {
                    continue
                }
                UIPasteboard.general.url = url
            }
        }
        applicationActivities.append(customCopy)

        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: applicationActivities)
		if let ppc = activityVC.popoverPresentationController {
			if location != nil {
				if let view = location as? UIView {
					ppc.sourceView = view
				}
				if let button = location as? UIBarButtonItem {
					ppc.barButtonItem = button
				}
			}
		}

        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.last?.rootViewController?.present(activityVC, animated: true)
	}
}
