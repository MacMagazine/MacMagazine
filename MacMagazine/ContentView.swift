import SwiftUI
import Videos

struct ContentView: View {

    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            VideosFullView()
                .environmentObject(VideosViewModel())
                .tabItem { Label("Videos", systemImage: "play.rectangle.fill") }
                .tag(0)
        }
    }
}

#Preview {
    ContentView()
}
