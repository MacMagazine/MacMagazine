import Foundation
import SwiftUI
import UIComponentsLibrary

public struct Bubble {
	let background: String
	let text: String
}

public protocol AppColor {
	var user: Bubble { get }
	var assistant: Bubble { get }
	var tip: TipConfig { get }
}

public struct ThemeColor: Themeable & AppColor {
	public let main = MainColor(background: "MMGrey6",
								navigation: "MMBlack90",
								tint: "MMBlueWhite",
								shadow: "")

	public let secondary = SecondaryColor(background: "MMWhiteBlack")
	public let tertiary = SecondaryColor(background: "MMDarkGreyWhite")

	public let text = TextColor(primaryTab: "",
								primary: "MMBlueWhite",
								secondary: "MMWhiteGrey6",
								terciary: "MMLessDarkGreyWhite",
								error: "")

	public let button = ButtonColor(primary: "MMBlue",
									secondary: "MMBlueWhite",
									terciary: "",
									destructive: "TabascoDracula")

	public let tip = TipConfig(background: "MMBlue",
							   text: "MMBlack90")

	public let user = Bubble(background: "",
							 text: "")

	public let assistant = Bubble(background: "",
								  text: "")

	public init() {}
}

extension String {
	public var color: Color? {
		return Color(self, bundle: .module)
	}
}

extension EnvironmentValues {
    @Entry public var themeColor: ThemeColor = ThemeColor()
}
