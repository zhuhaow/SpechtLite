import Cocoa
import NEKit
import Sparkle

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    @IBOutlet weak var updater: SUUpdater!
    var barItem: NSStatusItem!
    var configurations: [String: (String, Bool)] = [:]
    var currentConfiguration: String?

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
        // force to update since this app is very likely to be buggy.
        updater.automaticallyChecksForUpdates = true
        // check for updates every hour
        updater.updateCheckInterval = 3600

        setUpAutostart()
    }

    func initMenuBar() {
        barItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
        barItem.title = "Sp"
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
        updater.checkForUpdates(sender)
    }

    func showAbout(sender: AnyObject? = nil) {
        NSApplication.sharedApplication().orderFrontStandardAboutPanel(sender)
    }

    func alertError(errorDescription: String) {
        let alert = NSAlert()
        alert.messageText = errorDescription
        alert.runModal()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        disconnect()
    }

    func terminate(sender: AnyObject? = nil) {
        NSApp.terminate(self)
    }
}
