import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var menuController: MenuBarController!
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        UpdaterManager.setUpAutoUpdate()
        
        LoggerManager.setUpFileLogger()

        menuController = MenuBarController()
    
        if Preference.setUpSystemProxy {
            menuController.setUpSystemProxy()
        }
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        if Preference.setUpSystemProxy {
            ProxyHelper.setUpSystemProxy(0, enabled: false)
        }
        ConfigurationManager.singletonInstance.stopProxyServer()
    }
    
    func terminate(sender: AnyObject? = nil) {
        NSApp.terminate(self)
    }
}
