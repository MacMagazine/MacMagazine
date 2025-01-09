import UIComponentsLibrary
import SwiftUI

public enum HeaderButtonType {
    case text(String)
    case image(String)
    case none
}

public struct HeaderView: View {
    private let title: String
    private let type: HeaderButtonType
	private let theme: ThemeColor
	private let action: () -> Void

	public init(title: String,
                type: HeaderButtonType,
				theme: ThemeColor,
				action: @escaping () -> Void) {
		self.title = title
        self.type = type
		self.theme = theme
		self.action = action
	}

	public var body: some View {
		HStack {
			Text(title)
				.font(.largeTitle)
				.foregroundColor(theme.text.terciary.color)

			Spacer()

            switch type {
            case .image(let image):
                Button(action: { action() },
                       label: {
                    Image(systemName: image)
                        .tint(theme.tertiary.background.color)
                        .imageScale(.large)
                })

            case .text(let text):
                Button(action: { action() },
                       label: {
                    Text(text.uppercased())
                        .borderedFullSize(color: theme.tertiary.background.color ?? .blue,
                                          stroke: theme.tertiary.background.color ?? .blue)
                        .frame(maxWidth: 120)
                })

            case .none: EmptyView()
            }
		}
    }
}

public struct HeaderFullView: View {
	private let title: String
	private let theme: ThemeColor
	private let action: () -> Void

	public init(title: String,
				theme: ThemeColor,
				action: @escaping () -> Void) {
		self.title = title
		self.theme = theme
		self.action = action
	}

	public var body: some View {
		HStack {
			Button(action: { action() },
				   label: {
				Image(systemName: "arrow.left.circle.fill")
					.tint(theme.tertiary.background.color)
					.imageScale(.large)
			})

			Text(title)
				.font(.largeTitle)
				.foregroundColor(theme.text.terciary.color)

			Spacer()
		}
	}
}
