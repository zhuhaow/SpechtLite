import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var menuController: MenuBarController!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        LoggerManager.setUp()
        
        PreferenceManager.setUp()
        
        UpdateManager.setUp()
        ProxySettingManager.setUp()
        ProfileManager.setUp()
        AutostartManager.setUp()
        
        menuController = MenuBarController()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        ProfileManager.stopProxyServer()
        ProxySettingManager.clear()
    }
}
