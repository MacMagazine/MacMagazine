import CommonLibrary
import SwiftUI

@main
struct MacMagazineApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.themeColor, ThemeColor())
        }
    }
}
