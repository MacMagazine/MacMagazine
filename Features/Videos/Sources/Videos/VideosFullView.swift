import CommonLibrary
import CoreData
import CoreLibrary
import SwiftUI
import UIComponentsLibrary
import YouTubeLibrary

public struct VideosFullView: View {
    @Environment(\.themeColor) private var theme
	@EnvironmentObject private var viewModel: VideosViewModel
	@State private var search: String?

	public init() {}

	public var body: some View {
		ZStack {
			(theme.main.background.color ?? .black)
			.edgesIgnoringSafeArea(.all)

			VStack {
				HStack {
                    Button(action: {
                        withAnimation {
                            viewModel.options = .home
                        }
                    }, label: {
                        Image(systemName: "arrow.left.circle.fill")
                            .tint(theme.tertiary.background.color)
                            .imageScale(.large)
                    })

                    Text("Vídeos")
                        .font(.largeTitle)
                        .foregroundColor(theme.text.terciary.color)

                    Spacer()
				}

				ErrorView(message: viewModel.status.reason)
					.padding(.top)
				VideosFullscreenView(api: viewModel.youtube,
									 favorite: viewModel.options == .favorite,
									 search: search,
									 theme: theme)
				Spacer()
			}
			.padding([.leading, .trailing, .top])
			.task {
				try? await viewModel.youtube.getVideos()
			}
		}
		.environment(\.managedObjectContext, viewModel.context)
	}
}

struct VideosFullView_Previews: PreviewProvider {
	static var previews: some View {
		VideosFullView()
			.environmentObject(VideosViewModel())
			.environment(\.theme, ThemeColor())
	}
}
