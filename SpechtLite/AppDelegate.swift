import Cocoa
import NEKit
import Sparkle

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var menuController: MenuBarController!
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        setUpAutoUpdate()
        
        LoggerManager.setUpFileLogger()

        menuController = MenuBarController()
    
        if Preference.setUpSystemProxy {
            menuController.setUpSystemProxy()
        }
    }
    
    func setUpAutoUpdate() {
        let updater = SUUpdater.sharedUpdater()
        // force to update since this app is very likely to be buggy.
        updater.automaticallyChecksForUpdates = true
        // check for updates every hour
        updater.updateCheckInterval = 3600
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
