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
        icon.isTemplate = true
        barItem = NSStatusBar.system().statusItem(withLength: -1)
        barItem.image = icon
        barItem.menu = NSMenu()
        barItem.menu!.delegate = self
    }
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        
        configurationManager.enumerateInOrder { name, valid in
            let item = self.buildMenuItemForManager(name, valid: valid)
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(withTitle: "Stop proxy server", action: #selector(stopProxyServerClicked(_:)), keyEquivalent: "d").target = self
        menu.addItem(withTitle: "Open config folder", action: #selector(openConfigFolderClicked(_:)), keyEquivalent: "c").target = self
        menu.addItem(withTitle: "Reload config", action: #selector(reloadConfigClicked(_:)), keyEquivalent: "r").target = self
        
        menu.addItem(NSMenuItem.separator())
        
        let proxyItem = NSMenuItem(title: "Set as system proxy", action: #selector(setAsSystemProxyClicked(_:)), keyEquivalent: "")
        proxyItem.target = self
        if Preference.setUpSystemProxy {
            proxyItem.state = NSOnState
        }
        menu.addItem(proxyItem)
        
        menu.addItem(withTitle: "Copy shell export command", action: #selector(copyShellExportCommandClicked(_:)), keyEquivalent: "").target = self
        
        let lanItem = NSMenuItem(title: "Allow Clients From Lan", action: #selector(allowClientsFromLanClicked(_:)), keyEquivalent: "")
        lanItem.target = self
        if Preference.allowFromLan {
            lanItem.state = NSOnState
        }
        menu.addItem(lanItem)
        
        menu.addItem(withTitle: "Speed test", action: #selector(speedTestClicked(_:)), keyEquivalent: "").target = self
        
        menu.addItem(NSMenuItem.separator())
        
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
        
        menu.addItem(withTitle: "Check for updates", action: #selector(checkForUpdatesClicked(_:)), keyEquivalent: "u").target = self
        menu.addItem(withTitle: "Show log", action: #selector(showLogFileClicked(_:)), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Help", action: #selector(helpClicked(_:)), keyEquivalent: "").target = self
        menu.addItem(withTitle: "About", action: #selector(aboutClicked(_:)), keyEquivalent: "").target = self
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(withTitle: "Exit", action: #selector(exitClicked(_:)), keyEquivalent: "q").target = self
    }
    
    func buildMenuItemForManager(_ name: String, valid: Bool) -> NSMenuItem {
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
    
    func configurationClicked(_ sender: NSMenuItem) {
        configurationManager.toggleConfiguration(sender.title)
    }
    
    func stopProxyServerClicked(_ sender: AnyObject) {
        configurationManager.stopProxyServer()
    }
    
    func openConfigFolderClicked(_ sender: AnyObject) {
        configurationManager.openConfigFolder()
    }
    
    func reloadConfigClicked(_ sender: AnyObject) {
        configurationManager.reloadAllConfigurationFiles()
    }
    
    func setAsSystemProxyClicked(_ sender: AnyObject) {
        Preference.setUpSystemProxy = !Preference.setUpSystemProxy
        setUpSystemProxy()
    }
    
    func copyShellExportCommandClicked(_ sender: AnyObject) {
        let pasteboard = NSPasteboard.general()
        pasteboard.clearContents()
        pasteboard.setString("export https_proxy=http://127.0.0.1:\(configurationManager.currentProxyPort);export http_proxy=http://127.0.0.1:\(configurationManager.currentProxyPort)", forType: NSStringPboardType)
    }
    
    func allowClientsFromLanClicked(_ sender: AnyObject) {
        Preference.allowFromLan = !Preference.allowFromLan
        configurationManager.restartCurrentProxyServer()
    }
    
    func speedTestClicked(_ sender: AnyObject) {
        let t1 = Date().timeIntervalSince1970
        let proxySessionConfiguration = URLSessionConfiguration.ephemeral
        proxySessionConfiguration.connectionProxyDictionary = [
            kCFNetworkProxiesHTTPSEnable as AnyHashable: 1,
            kCFNetworkProxiesHTTPSPort as AnyHashable: configurationManager.currentProxyPort,
            kCFNetworkProxiesHTTPSProxy as AnyHashable: "127.0.0.1"
        ]
        let urlSession = URLSession(configuration: proxySessionConfiguration)
        let task = urlSession.dataTask(with: URL(string: "https://www.google.com/generate_204")!, completionHandler: {
            (data, response, error) in
            let notification = NSUserNotification()
            notification.soundName = NSUserNotificationDefaultSoundName
            notification.title = "Speed Test"
            if let res = response as? HTTPURLResponse, res.statusCode == 204 {
                let time = Int((Date().timeIntervalSince1970 - t1) * 1000)
                notification.informativeText = "Response time: \(time)ms"
            } else {
                print("HTTP Request Failed")
                print(error!)
                notification.informativeText = "Speed test failed!"
            }
            NSUserNotificationCenter.default.deliver(notification)
        }) 
        task.resume()
    }
    
    func useDevChannelClicked(_ sender: AnyObject) {
        Preference.useDevChannel = !Preference.useDevChannel
        UpdaterManager.setUpAutoUpdate()
    }
    
    func autostartAtLoginClicked(_ sender: AnyObject) {
        Preference.autostart = !Preference.autostart
        func setUpAutostart() {
            if Preference.autostart {
                _ = Autostart.enable()
            } else {
                _ = Autostart.disable()
            }
        }
    }
    
    func showLogFileClicked(_ sender: AnyObject) {
        if let logfile = (LoggerManager.logger as? DDFileLogger)?.logFileManager?.sortedLogFilePaths?.first {
            NSWorkspace.shared().openFile(logfile)
        }
    }
    
    func checkForUpdatesClicked(_ sender: AnyObject) {
        SUUpdater.shared().checkForUpdates(sender)
    }
    
    func aboutClicked(_ sender: AnyObject) {
        NSApplication.shared().activate(ignoringOtherApps: true)
        NSApplication.shared().orderFrontStandardAboutPanel(sender)
    }
    
    func helpClicked(_ sender: AnyObject) {
        NSWorkspace.shared().open(URL(string: "https://github.com/zhuhaow/SpechtLite")!)
    }
    
    func exitClicked(_ sender: AnyObject) {
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
