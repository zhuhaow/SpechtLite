import Cocoa
import CocoaLumberjack
import Sparkle

class MenuBarController: NSObject, NSMenuDelegate {
    var barItem: NSStatusItem!
    let configurationManager: ConfigurationManager
    
    override init() {
        configurationManager = ConfigurationManager.singletonInstance
        
        super.init()
        
        configurationManager.reloadAllConfigurationFiles()
        
        let icon = NSImage(named: "StatusIcon")!
        icon.template = true
        barItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
        barItem.image = icon
        barItem.menu = NSMenu()
        barItem.menu!.delegate = self
    }
    
    func menuNeedsUpdate(menu: NSMenu) {
        menu.removeAllItems()
        
        configurationManager.enumerateInOrder { name, valid in
            let item = self.buildMenuItemForManager(name, valid: valid)
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separatorItem())
        
        menu.addItemWithTitle("Stop proxy server", action: #selector(stopProxyServerClicked(_:)), keyEquivalent: "d").target = self
        menu.addItemWithTitle("Open config folder", action: #selector(openConfigFolderClicked(_:)), keyEquivalent: "c").target = self
        menu.addItemWithTitle("Reload config", action: #selector(reloadConfigClicked(_:)), keyEquivalent: "r").target = self
        
        menu.addItem(NSMenuItem.separatorItem())
        
        let proxyItem = NSMenuItem(title: "Set as system proxy", action: #selector(setAsSystemProxyClicked(_:)), keyEquivalent: "")
        proxyItem.target = self
        if Preference.setUpSystemProxy {
            proxyItem.state = NSOnState
        }
        menu.addItem(proxyItem)
        
        menu.addItemWithTitle("Copy shell export command", action: #selector(copyShellExportCommandClicked(_:)), keyEquivalent: "").target = self
        
        let lanItem = NSMenuItem(title: "Allow Clients From Lan", action: #selector(allowClientsFromLanClicked(_:)), keyEquivalent: "")
        lanItem.target = self
        if Preference.allowFromLan {
            lanItem.state = NSOnState
        }
        menu.addItem(lanItem)
        
        menu.addItemWithTitle("Speed test", action: #selector(speedTestClicked(_:)), keyEquivalent: "").target = self
        
        menu.addItem(NSMenuItem.separatorItem())
        
        let autostartItem = NSMenuItem(title: "Autostart at login", action: #selector(autostartAtLoginClicked(_:)), keyEquivalent: "")
        autostartItem.target = self
        if Preference.autostart {
            autostartItem.state = NSOnState
        }
        menu.addItem(autostartItem)
        
        let devItem = NSMenuItem(title: "Use dev channel", action: #selector(useDevChannelClicked(_:)), keyEquivalent: "")
        devItem.target = self
        if Preference.useDevChannel {
            devItem.state = NSOnState
        }
        menu.addItem(devItem)
        
        menu.addItemWithTitle("Check for updates", action: #selector(checkForUpdatesClicked(_:)), keyEquivalent: "u").target = self
        menu.addItemWithTitle("Show log", action: #selector(showLogFileClicked(_:)), keyEquivalent: "").target = self
        menu.addItemWithTitle("Help", action: #selector(helpClicked(_:)), keyEquivalent: "").target = self
        menu.addItemWithTitle("About", action: #selector(aboutClicked(_:)), keyEquivalent: "").target = self
        
        menu.addItem(NSMenuItem.separatorItem())
        
        menu.addItemWithTitle("Exit", action: #selector(exitClicked(_:)), keyEquivalent: "q").target = self
    }
    
    func buildMenuItemForManager(name: String, valid: Bool) -> NSMenuItem {
        let item = NSMenuItem(title: name, action: #selector(configurationClicked(_:)), keyEquivalent: "")
        item.target = self
        
        if name == configurationManager.currentConfiguration {
            item.state = NSOnState
        }
        
        if !valid {
            item.action = nil
        }
        
        return item
    }
    
    func configurationClicked(sender: NSMenuItem) {
        configurationManager.toggleConfiguration(sender.title)
    }
    
    func stopProxyServerClicked(sender: AnyObject) {
        configurationManager.stopProxyServer()
    }
    
    func openConfigFolderClicked(sender: AnyObject) {
        configurationManager.openConfigFolder()
    }
    
    func reloadConfigClicked(sender: AnyObject) {
        configurationManager.reloadAllConfigurationFiles()
    }
    
    func setAsSystemProxyClicked(sender: AnyObject) {
        Preference.setUpSystemProxy = !Preference.setUpSystemProxy
        setUpSystemProxy()
    }
    
    func copyShellExportCommandClicked(sender: AnyObject) {
        let pasteboard = NSPasteboard.generalPasteboard()
        pasteboard.clearContents()
        pasteboard.setString("export https_proxy=http://127.0.0.1:\(configurationManager.currentProxyPort);export http_proxy=http://127.0.0.1:\(configurationManager.currentProxyPort)", forType: NSStringPboardType)
    }
    
    func allowClientsFromLanClicked(sender: AnyObject) {
        Preference.allowFromLan = !Preference.allowFromLan
        configurationManager.restartCurrentProxyServer()
    }
    
    func speedTestClicked(sender: AnyObject) {
        let t1 = NSDate().timeIntervalSince1970
        let proxySessionConfiguration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        proxySessionConfiguration.connectionProxyDictionary = [
            kCFNetworkProxiesHTTPSEnable: 1,
            kCFNetworkProxiesHTTPSPort: configurationManager.currentProxyPort,
            kCFNetworkProxiesHTTPSProxy: "127.0.0.1"
        ]
        let urlSession = NSURLSession(configuration: proxySessionConfiguration)
        let task = urlSession.dataTaskWithURL(NSURL(string: "https://www.google.com/generate_204")!) {
            (data, response, error) in
            let notification = NSUserNotification()
            notification.soundName = NSUserNotificationDefaultSoundName
            notification.title = "Speed Test"
            if let res = response as? NSHTTPURLResponse where res.statusCode == 204 {
                let time = Int((NSDate().timeIntervalSince1970 - t1) * 1000)
                notification.informativeText = "Response time: \(time)ms"
            } else {
                print("HTTP Request Failed")
                print(error)
                notification.informativeText = "Speed test failed!"
            }
            NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
        }
        task.resume()
    }
    
    func useDevChannelClicked(sender: AnyObject) {
        Preference.useDevChannel = !Preference.useDevChannel
        UpdaterManager.setUpAutoUpdate()
    }
    
    func autostartAtLoginClicked(sender: AnyObject) {
        Preference.autostart = !Preference.autostart
        func setUpAutostart() {
            if Preference.autostart {
                Autostart.enable()
            } else {
                Autostart.disable()
            }
        }
    }
    
    func showLogFileClicked(sender: AnyObject) {
        if let logfile = (LoggerManager.logger as? DDFileLogger)?.logFileManager?.sortedLogFilePaths()?.first as? String {
            NSWorkspace.sharedWorkspace().openFile(logfile)
        }
    }
    
    func checkForUpdatesClicked(sender: AnyObject) {
        SUUpdater.sharedUpdater().checkForUpdates(sender)
    }
    
    func aboutClicked(sender: AnyObject) {
        NSApplication.sharedApplication().activateIgnoringOtherApps(true)
        NSApplication.sharedApplication().orderFrontStandardAboutPanel(sender)
    }
    
    func helpClicked(sender: AnyObject) {
        NSWorkspace.sharedWorkspace().openURL(NSURL(string: "https://github.com/zhuhaow/SpechtLite")!)
    }
    
    func exitClicked(sender: AnyObject) {
        NSApp.terminate(sender)
    }
    
    func setUpSystemProxy() {
        if !ProxyHelper.install() {
            Utils.alertError("Failed to install helper script to set up system proxy.")
            Preference.setUpSystemProxy = false
        } else {
            if !ProxyHelper.setUpSystemProxy(configurationManager.currentProxyPort, enabled: Preference.setUpSystemProxy) {
                Utils.alertError("Failed to set up system proxy.")
                Preference.setUpSystemProxy = false
            }
        }
    }
}
