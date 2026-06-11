import SwiftUI
import GoogleMobileAds
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct SozBilApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        MobileAds.shared.start { _ in }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
