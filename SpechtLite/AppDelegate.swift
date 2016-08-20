import Cocoa
import NEKit
import Sparkle

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    var barItem: NSStatusItem!
    var configurations: [String: (String, Bool)] = [:]
    var currentConfiguration: String?

    var currentProxyPort = 9090
    var currentProxies: [ProxyServer] = []

    var configFolder: String {
        let path = (NSHomeDirectory() as NSString).stringByAppendingPathComponent(".SpechtLite")
        var isDir: ObjCBool = false
        let exist = NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDir)
        if exist && !isDir {
            try! NSFileManager.defaultManager().removeItemAtPath(path)
            try! NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
        }
        if !exist {
            try! NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
        }
        return path
    }


    func applicationDidFinishLaunching(aNotification: NSNotification) {
        reloadAllConfigurationFiles()
        initMenuBar()

        let sharedUpdater = SUUpdater.sharedUpdater()
        // force to update since this app is very likely to be buggy.
        sharedUpdater.automaticallyChecksForUpdates = true
        // check for updates every hour
        sharedUpdater.updateCheckInterval = 3600

        setUpAutostart()
        ProxyHelper.install()
        if Preference.setProxy {
            setProxy(Preference.setProxy)
        }
    }

    func initMenuBar() {
        let icon = NSImage(named: "StatusIcon")
        icon?.template = true
        barItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
        barItem.image = icon
        barItem.menu = NSMenu()
        barItem.menu!.delegate = self
    }

    func menuNeedsUpdate(menu: NSMenu) {
        menu.removeAllItems()

        for (name, info) in configurations {
            let item = buildMenuItemForManager(name, valid: info.1)
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separatorItem())
        menu.addItemWithTitle("Disconnect", action: #selector(AppDelegate.disconnect(_:)), keyEquivalent: "d")
        menu.addItemWithTitle("Open config folder", action: #selector(AppDelegate.openConfigFolder(_:)), keyEquivalent: "c")
        menu.addItemWithTitle("Reload config", action: #selector(AppDelegate.reloadClicked(_:)), keyEquivalent: "r")
        menu.addItem(NSMenuItem.separatorItem())
        let proxyItem = NSMenuItem(title: "Set as system proxy", action: #selector(AppDelegate.didSetProxy(_:)), keyEquivalent: "")
        if Preference.setProxy {
            proxyItem.state = NSOnState
        }
        menu.addItem(proxyItem)
        menu.addItemWithTitle("Copy shell export command", action: #selector(AppDelegate.copyCommand(_:)), keyEquivalent: "")
        menu.addItem(NSMenuItem.separatorItem())
        let item = NSMenuItem(title: "Autostart at login", action: #selector(AppDelegate.autostartClicked(_:)), keyEquivalent: "")
        if Preference.autostart {
            item.state = NSOnState
        }
        menu.addItem(item)
        menu.addItemWithTitle("Check for updates", action: #selector(AppDelegate.update(_:)), keyEquivalent: "u")
        menu.addItemWithTitle("About", action: #selector(AppDelegate.showAbout(_:)), keyEquivalent: "")
        menu.addItem(NSMenuItem.separatorItem())
        menu.addItemWithTitle("Exit", action: #selector(AppDelegate.terminate(_:)), keyEquivalent: "q")
    }

    func buildMenuItemForManager(name: String, valid: Bool) -> NSMenuItem {
        let item = NSMenuItem(title: name, action: #selector(AppDelegate.startConfiguration(_:)), keyEquivalent: "")

        if name == currentConfiguration {
            item.state = NSOnState
        }

        if !valid {
            item.action = nil
        }

        return item
    }

    func startConfiguration(sender: NSMenuItem) {
        if sender.title == currentConfiguration {
            disconnect()
            return
        }

        disconnect()

        runConfiguration(sender.title)
    }

    func runConfiguration(name: String) -> Bool {
        let configuration = Configuration()

        guard let config = configurations[name] else {
            return false
        }

        guard config.1 else {
            return false
        }

        try! configuration.load(fromConfigString: config.0)
        RuleManager.currentManager = configuration.ruleManager
        let proxyPort = configuration.proxyPort ?? 9090

        let httpServer = GCDHTTPProxyServer(address: IPv4Address(fromString: "127.0.0.1"), port: Port(port: UInt16(proxyPort)))
        let socks5Server = GCDSOCKS5ProxyServer(address: IPv4Address(fromString: "127.0.0.1"), port: Port(port: UInt16(proxyPort + 1)))

        do {
            try httpServer.start()
            try socks5Server.start()
        } catch let error {
            alertError("Encounter an error when starting proxy server. \(error)")
            return false
        }

        currentProxyPort = proxyPort
        currentConfiguration = name
        currentProxies.append(httpServer)
        currentProxies.append(socks5Server)

        saveCurrentConfigurationToDefaults()
        return true
    }

    func disconnect(sender: AnyObject? = nil) {
        for proxyServer in currentProxies {
            proxyServer.stop()
        }
        currentProxies = []

        currentConfiguration = nil
    }

    func openConfigFolder(sender: AnyObject) {
        NSWorkspace.sharedWorkspace().openFile(configFolder)
    }

    func reloadClicked(sender: AnyObject) {
        reloadAllConfigurationFiles()
    }

    func didSetProxy(sender: AnyObject) {
        Preference.setProxy = !Preference.setProxy
        if let item = sender as? NSMenuItem {
            item.state = Preference.setProxy ? NSOnState : NSOffState
        }
        setProxy(Preference.setProxy)
    }

    func setProxy(enable: Bool) {
        ProxyHelper.setSystemProxy(currentProxyPort, enable: enable)
    }

    func copyCommand(sender: AnyObject) {
        let pasteboard = NSPasteboard.generalPasteboard()
        pasteboard.declareTypes([NSStringPboardType], owner: nil)
        pasteboard.setString("export https_proxy=http://127.0.0.1:\(currentProxyPort);export http_proxy=http://127.0.0.1:\(currentProxyPort)", forType: NSStringPboardType)
    }

    func autostartClicked(sender: AnyObject) {
        Preference.autostart = !Preference.autostart
        setUpAutostart()
    }

    func setUpAutostart() {
        if Preference.autostart {
            Autostart.enable()
        } else {
            Autostart.disable()
        }
    }

    func reloadAllConfigurationFiles(runDefault: Bool = true) {
        let paths = try! NSFileManager.defaultManager().contentsOfDirectoryAtPath(configFolder).filter {
            ($0 as NSString).pathExtension == "yaml"
        }

        for path in paths {
            let name = ((path as NSString).lastPathComponent as NSString).stringByDeletingPathExtension

            let fullpath = (configFolder as NSString).stringByAppendingPathComponent(path)

            var content: String
            do {
                content = try String(contentsOfFile: fullpath, encoding: NSUTF8StringEncoding)
            } catch let error {
                alertError("Error when loading config file: \(fullpath). \(error)")
                configurations[name] = ("", false)
                continue
            }

            let configuration = Configuration()
            do {
                try configuration.load(fromConfigString: content)
            } catch let error {
                alertError("Error when parsing config file: \(fullpath). \(error)")
                configurations[name] = ("", false)
                continue
            }

            configurations[name] = (content, true)
        }

        disconnect()
        if runDefault {
            runConfigurationInDefaults()
        }
    }

    func saveCurrentConfigurationToDefaults() {
        Preference.defaultConfiguration = currentConfiguration
    }

    func runConfigurationInDefaults() -> Bool {
        guard let configName = Preference.defaultConfiguration else {
            return false
        }

        return runConfiguration(configName)
    }

    func update(sender: AnyObject? = nil) {
        SUUpdater.sharedUpdater().checkForUpdates(sender)
    }

    func showAbout(sender: AnyObject? = nil) {
        NSApplication.sharedApplication().activateIgnoringOtherApps(true)
        NSApplication.sharedApplication().orderFrontStandardAboutPanel(sender)
    }

    func alertError(errorDescription: String) {
        let alert = NSAlert()
        alert.messageText = errorDescription
        alert.runModal()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        setProxy(false)
        disconnect()
    }

    func terminate(sender: AnyObject? = nil) {
        NSApp.terminate(self)
    }
}
