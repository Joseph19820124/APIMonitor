import SwiftUI
import AppKit

@main
struct APIMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // 无主窗口，纯菜单栏 app
        Settings { EmptyView() }
    }
}
