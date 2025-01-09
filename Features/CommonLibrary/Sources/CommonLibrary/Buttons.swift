import SwiftUI

public struct PlainButtonTextStyle: ViewModifier {
	let color: Color
	let font: Font

	public init(color: Color,
				font: Font) {
		self.color = color
		self.font = font
	}

	public func body(content: Content) -> some View {
		content
			.font(font.weight(.bold))
			.foregroundColor(color)
			.padding(8)
	}
}

extension Text {
    @MainActor
    public func plain(color: Color = .primary,
					  font: Font = .caption) -> some View {
		modifier(PlainButtonTextStyle(color: color, font: font))
	}
}
