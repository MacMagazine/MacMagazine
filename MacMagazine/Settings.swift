//
//  Settings.swift
//  MacMagazine
//
//  Created by Cassio Rossi on 02/03/2019.
//  Copyright © 2019 MacMagazine. All rights reserved.
//

import OneSignalFramework
import UIKit

// MARK: -

enum Appearance: Int {
    case light = 0
    case dark
    case native
}

struct Settings {

	// MARK: - Device -

	var isPhone: Bool {
        return (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.last?.rootViewController?.traitCollection.horizontalSizeClass == .compact
    }

	var isPad: Bool {
        return (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.last?.rootViewController?.traitCollection.horizontalSizeClass == .regular
    }

	var orientations: UIInterfaceOrientationMask {
		return isPhone ? .portrait : .all
	}

	// MARK: - Dark Mode -

    var appearance: Appearance {
        guard let mode = UserDefaults.standard.object(forKey: Definitions.darkMode) as? Int else {
            guard let darkMode = UserDefaults.standard.object(forKey: Definitions.darkMode) as? Bool else {
                return .light
            }
            return darkMode ? .dark : .light
        }
        return Appearance(rawValue: mode) ?? .light
    }

    var isDarkMode: Bool {
        if appearance == .native {
            return (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.last?.rootViewController?.traitCollection.userInterfaceStyle == .dark
        }
        return appearance == .dark
    }

	var darkModeUserAgent: String {
		return isDarkMode ? "true" : "false"
	}

    var darkModeColor: UIColor {
        return isDarkMode ? .white : .black
    }

    var theme: Theme {
        return isDarkMode ? DarkTheme() : LightTheme()
    }

    // MARK: - Fonts -

	var fontSizeUserAgent: String {
        let contentSize: UIContentSizeCategory = UIApplication.shared.preferredContentSizeCategory
        if contentSize == .unspecified {
            return "large"
        }
        let size = contentSize.rawValue.replacingOccurrences(of: "UICTContentSizeCategory", with: "")
            .replacingOccurrences(of: "X", with: "Extra")
            .replacingOccurrences(of: "L", with: "Large")
            .replacingOccurrences(of: "S", with: "Small")
            .replacingOccurrences(of: "M", with: "Medium")
            .llamaCase()

        return size
	}

    // MARK: - Cookies -

	func updateCookies(based previousTraitCollection: UITraitCollection?) {
        let state = UIApplication.shared.applicationState
        if let style = previousTraitCollection?.userInterfaceStyle,
            state == .active,
            appearance == .native &&
                ((style == .dark && isDarkMode) ||
                (style == .light && !isDarkMode)) {
            NotificationCenter.default.post(name: .updateCookie, object: Definitions.darkMode)
        }
	}

    // MARK: - Read Intensity -

    var transparency: CGFloat {
        guard let transparency = UserDefaults.standard.object(forKey: Definitions.transparency) as? CGFloat else {
            return 0.4
        }
        return transparency
    }

    // MARK: - Patrão -

    var isPatrao: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Definitions.mmPatrao)
        }
        set(value) {
            UserDefaults.standard.set(value, forKey: Definitions.mmPatrao)
            UserDefaults.standard.synchronize()
        }
    }

    var loginPatrao: String {
        return isPatrao ? "Logoff de patrão" : "Login para patrões"
    }

    // MARK: - Assinatura -

    var purchased: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Definitions.purchased)
        }
        set(value) {
            UserDefaults.standard.set(value, forKey: Definitions.purchased)
            UserDefaults.standard.synchronize()
        }
    }

    // MARK: - What's New -

    var whatsNew: String {
        get {
            return UserDefaults.standard.string(forKey: Definitions.whatsnew) ?? ""
        }
        set(value) {
            UserDefaults.standard.set(value, forKey: Definitions.whatsnew)
            UserDefaults.standard.synchronize()
        }
    }

    // MARK: - Check MM Live -

    func isMMLive(_ onCompletion: ((Bool) -> Void)?) {
        guard let event = UserDefaults.standard.object(forKey: Definitions.mmLive) as? Data,
              let decoded = try? JSONDecoder().decode(MMLive.self, from: event),
              let lastChecked = decoded.lastChecked else {
            getMMLive { isLive in
                onCompletion?(isLive)
            }
            return
        }
        if Date() > lastChecked.addingTimeInterval(86400) {    // 24 hours
            getMMLive { isLive in
                onCompletion?(isLive)
            }
        } else {
            let isLive = Date() > decoded.inicio && Date() < decoded.fim
            onCompletion?(isLive)
        }
    }

    fileprivate func getMMLive(_ onCompletion: ((Bool) -> Void)?) {
        API.mmLive { event in
            guard var event = event else {
                onCompletion?(false)
                return
            }

            let isLive = Date() > event.inicio && Date() < event.fim
            event.lastChecked = Date()

            // Set Local Push Notifications
            PushNotification().setLocalNotification(for: event)

            if let encoded = try? JSONEncoder().encode(event) {
                UserDefaults.standard.set(encoded, forKey: Definitions.mmLive)
            }

            onCompletion?(isLive)
        }
    }

	// MARK: - Review -

	var shouldAskForReview: Bool {
		guard let askForReview = UserDefaults.standard.object(forKey: Definitions.askForReview) as? Int else {
			UserDefaults.standard.set(1, forKey: Definitions.askForReview)
			UserDefaults.standard.synchronize()

			return false
		}
		UserDefaults.standard.set(askForReview + 1, forKey: Definitions.askForReview)
		UserDefaults.standard.synchronize()

		return askForReview % 50 == 0
	}
}

// MARK: - Theme -

extension Settings {
	func applyTheme() {
		theme.apply(for: UIApplication.shared)
        NotificationCenter.default.post(name: .reloadWeb, object: nil)
	}

	func applyLightTheme() {
		if isDarkMode {
            (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.last?.tintColor = LightTheme().tint
		}
	}
}

// MARK: - Push -

enum PushPreferences {
	static let featured = "featured_posts"
	static let all = "all_posts"
}

extension Settings {
	// 0 -> All posts
	// 1 -> Featured only
	var pushPreference: Int {
		guard let pushPreferences = UserDefaults.standard.object(forKey: Definitions.pushPreferences) as? Int else {
			// There is no Push Notification Preference or is old style
			guard let pushPreferences = UserDefaults.standard.object(forKey: Definitions.allPostsPushes) as? Bool else {
				// There is no Push Notification Preference
				return 0
			}
			// Remove old preference
			UserDefaults.standard.removeObject(forKey: Definitions.allPostsPushes)
			UserDefaults.standard.synchronize()

			return pushPreferences ? 0 : 1
		}
		return pushPreferences
	}

	func updatePushPreference(_ segment: Int) {
		UserDefaults.standard.set(segment, forKey: Definitions.pushPreferences)
		UserDefaults.standard.synchronize()

		OneSignal.User.addTag(key: "notification_preferences", value: segment == 0 ? PushPreferences.all : PushPreferences.featured)
	}
}

// MARK: - Others -

extension Settings {
    class AsClass {}
    var appVersion: String {
        let bundle = Bundle(for: Settings.AsClass.self)
        let appVersion = bundle.infoDictionary?["CFBundleShortVersionString"] as? String
        return "\(appVersion ?? "0")"
    }
}

extension Settings {
    func getMetricBoldFont(forTextStyle: UIFont.TextStyle) -> UIFont {
        let font = UIFont.boldSystemFont(ofSize: 22)
        let fontMetrics = UIFontMetrics(forTextStyle: forTextStyle)
        return fontMetrics.scaledFont(for: font)
    }
}

extension Settings {
    func createLabel(message: String, size: CGSize) -> UILabel {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.isAccessibilityElement = true
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.textColor = .label
        label.text = message

        return label
    }
}
