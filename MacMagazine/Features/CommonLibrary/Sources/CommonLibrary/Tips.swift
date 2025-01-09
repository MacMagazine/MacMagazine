import TipKit

public struct TipConfig {
	public let background: String
	let text: String
}

public enum TipContext {
	case feature
	case highlightFeature
}

public protocol TipType: CaseIterable, Equatable {
	associatedtype AssocType: View
	func tipView(with theme: ThemeColor) -> AssocType
	func invalidate()
	func show()
}

@available(iOS 17, *)
extension TipType {
	public func add(next: ((any TipType) -> Void)?) -> [Tip.Action] {
		if self.isLast { [] } else {
            [Tip.Action(id: UUID().uuidString, perform: { next?(self.next) }, {
				Text("Próxima dica")
			})]
		}
	}
}

@available(iOS 17, *)
struct MMTipViewStyle: TipViewStyle {
	func makeBody(configuration: Configuration) -> some View {
		VStack(alignment: .leading, spacing: 20) {
			HStack(alignment: .top) {
				(configuration.image ?? Image(systemName: "info.bubble"))
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(width: 28, height: 28)
					.padding(.top, 4)
					.accessibilityHidden(true)

				configuration.title
					.font(.title2)
					.fontWeight(.bold)
					.accessibilityHint(Text("Dica de como usar o aplicativo."))

				Spacer(minLength: 30)

				Button(action: {
					configuration.tip.invalidate(reason: .tipClosed)
				}, label: {
					Image(systemName: "xmark")
						.padding(.top, 4)
				})
				.accessibilityLabel("Fechar dica")
			}

			configuration.message

			ForEach(configuration.actions, id: \.id) { action in
				Button(action: {
					configuration.tip.invalidate(reason: .actionPerformed)
					action.handler()
				}, label: {
					action.label()
						.fontWeight(.bold)
				})
			}
		}
		.foregroundColor(.white)
		.tint(.white)
		.padding()
	}
}

extension View {
	@available(iOS 17, *)
	public func style(theme: ThemeColor) -> some View {
		self.modifier(CustomTipView(theme: theme))
	}
}

@available(iOS 17, *)
struct CustomTipView: ViewModifier {
	private let theme: ThemeColor

	init(theme: ThemeColor) {
		self.theme = theme
	}

	func body(content: Content) -> some View {
		content
			.tipViewStyle(MMTipViewStyle())
			.tipBackground(theme.tip.background.color ?? .blue)
	}
}
