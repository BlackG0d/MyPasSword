import SwiftUI

@main
struct LockScreenApp: App {
    var body: some Scene {
        WindowGroup {
            if UIDevice.current.userInterfaceIdiom == .phone {
                LockScreenView()
            } else {
                Text("This app is designed for iPhone only")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
        }
    }
} 