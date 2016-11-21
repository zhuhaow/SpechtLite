import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var menuController: MenuBarController!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        UpdaterManager.setUpAutoUpdate()
        
        LoggerManager.setUpFileLogger()

        menuController = MenuBarController()
    
        if Preference.setUpSystemProxy {
            menuController.setUpSystemProxy()
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        if Preference.setUpSystemProxy {
            _ = ProxyHelper.setUpSystemProxy(0, enabled: false)
        }
        ConfigurationManager.singletonInstance.stopProxyServer()
    }
}
