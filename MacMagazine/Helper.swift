//
//  Helper.swift
//  MacMagazine
//
//  Created by Cassio Rossi on 24/09/2022.
//  Copyright © 2022 MacMagazine. All rights reserved.
//

import UIKit

// MARK: -

enum Definitions {
    static let darkMode = "darkMode"
    static let fontSize = "font-size-settings"
    static let icon = "icon"
    static let watch = "watch"
    static let askForReview = "askForReview"
    static let all_posts_pushes = "all_posts_pushes"
    static let pushPreferences = "pushPreferences"
    static let transparency = "transparency"
    static let mm_patrao = "mm_patrao"
    static let purchased = "purchased"
    static let whatsnew = "whatsnew"
    static let deleteAllCookies = "deleteAllCookies"
    static let mmLive = "mmLive"
    static let badge = "badge"
}

struct Helper {
    var badgeCount: Int = {
        let count = CoreDataStack.shared.numberOfUnreadPosts()
        return count
    }()

	func manageBadge() {
		if UserDefaults.standard.bool(forKey: Definitions.badge) {
			showBadge()
		} else {
			resetBadge()
		}
	}

	func resetBadge() {
#if !WIDGET
		UIApplication.shared.applicationIconBadgeNumber = 0
#endif
	}

	func showBadge() {
#if !WIDGET
		if UserDefaults.standard.bool(forKey: Definitions.badge) {
			delay(0.4) {
				UIApplication.shared.applicationIconBadgeNumber = badgeCount
			}
		}
#endif
    }
}
