import FirebaseAnalytics
import Foundation

public struct Analytics {
	static public func log(settings: [String: AnyObject]) {
		FirebaseAnalytics.Analytics.logEvent("Settings", parameters: settings)
	}
}
