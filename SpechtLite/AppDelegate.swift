import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var menuController: MenuBarController!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        PreferenceManager.setup()
        UpdateManager.setup()
        ProxySettingManager.setup()
        ProfileManager.setup()
        
        menuController = MenuBarController()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        ProfileManager.stopProxyServer()
    }
}
