import SwiftUI
import UIComponentsLibrary

public struct ShareObject {
	let message: String
	let title: String?
	let preview: Image?
	let placement: ToolbarItemPlacement

	public init(message: String,
				title: String? = nil,
				preview: Image? = nil,
				placement: ToolbarItemPlacement = .topBarLeading) {
		self.message = message
		self.title = title
		self.preview = preview
		self.placement = placement
	}
}

public struct NavigationStack<Content: View>: View {
	private let theme: ThemeColor
	private let background: Color?
	private let title: String?
	private let onDismiss: (() -> Void)?
	private let share: ShareObject?
	private let displayMode: NavigationBarItem.TitleDisplayMode
	
	@ViewBuilder
	private let content: Content

	public init(theme: ThemeColor,
				displayMode: NavigationBarItem.TitleDisplayMode = .inline,
				title: String? = nil,
				background: Color? = nil,
				@ViewBuilder content: () -> Content,
				share: ShareObject? = nil,
				onDismiss: (() -> Void)? = nil) {
		self.theme = theme
		self.title = title
		self.displayMode = displayMode
		self.background = background
		self.content = content()
		self.share = share
		self.onDismiss = onDismiss

		if let color = theme.main.tint.color {
			UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(color)]
			UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(color)]
		}
	}

	public var body: some View {
		SwiftUI.NavigationStack {
			ZStack {
				theme.main.navigation.color
					.edgesIgnoringSafeArea(.all)

				ZStack {
					(background ?? theme.main.background.color)
						.edgesIgnoringSafeArea([.leading, .trailing, .bottom])

					content
				}
			}
			.navigationTitle(title ?? "")
			.navigationBarTitleDisplayMode(displayMode)
			.toolbar {
				if let share = share {
					ToolbarItem(placement: share.placement) {
						ShareLink(item: share.message,
								  preview: SharePreview(share.title ?? "Chat",
														image: share.preview ?? Image("logo", bundle: .module))) {
							Image(systemName: "square.and.arrow.up")
								.font(.system(size: 18))
						}
					}
				}

				ToolbarItem(placement: .principal) {
					if title == nil {
						Image("logo", bundle: .module)
							.resizable()
							.aspectRatio(contentMode: .fit)
							.frame(width: 42)
					}
				}

				if onDismiss != nil {
					ToolbarItem(placement: .topBarTrailing) {
						Button(action: { onDismiss?() }, label: {
							Image(systemName: "xmark.circle.fill")
						})
					}
				}
			}
		}
		.accentColor(theme.main.tint.color)
	}
}


#Preview("No title") {
	NavigationStack(theme: ThemeColor(), content: {
		VStack {
			Text("Cassio")
			Spacer()
		}
		.padding()
	}, share: ShareObject(message: "shareAction",
						  title: "My Chat"))
}

#Preview("Custom Background") {
	NavigationStack(theme: ThemeColor(),
					displayMode: .large,
					title: "Navigation Title",
					background: .red) {
		VStack {
			Text("Cassio")
			Spacer()
		}
		.padding()
	}
}

#Preview("Default") {
	NavigationStack(theme: ThemeColor(),
					title: "Navigation Title", content: {
		VStack {
			Text("Cassio")
			Spacer()
		}
		.padding()
	}, onDismiss: { print("onDismiss") })
}
