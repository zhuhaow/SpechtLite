import Cocoa
import Sparkle
import ReactiveCocoa
import ReactiveSwift
import enum Result.NoError
import CocoaLumberjackSwift

class MenuBarController: NSObject, NSMenuDelegate {
    let barItem: NSStatusItem
    
    let profileAction: CocoaAction<NSMenuItem> = {
        let action = Action<String, Void, NoError> { name in
            return SignalProducer { observer, _ in
                ProfileManager.currentProfile.swap(name)
                observer.sendCompleted()
            }
        }
        return CocoaAction(action) {
            return $0.title
        }
    }()
    
    let stopProxyServerAction: CocoaAction<Any> = {
        let action = Action<Void, Void, NoError> {
            ProfileManager.currentProfile.swap(nil)
            return SignalProducer.empty
        }
        return CocoaAction(action)
    }()
    
    let openProfileFolderAction: CocoaAction<Any> = {
        let action = Action<Void, Void, NoError> {
            ProfileManager.openProfileFolder()
            return SignalProducer.empty
        }
        return CocoaAction(action)
    }()
    
    let reloadProfileAction: CocoaAction<Any> = {
        let action = Action<Void, Void, NoError> {
            ProfileManager.reloadAllProfileFiles()
            return SignalProducer.empty
        }
        return CocoaAction(action)
    }()
    
    let setAsSystemProxyAction: CocoaAction<Any> = {
        let action = Action<Void, Void, NoError> {
            ProxySettingManager.setAsSystemProxy.modify {
                $0 = !$0
            }
            return SignalProducer.empty
        }
        return CocoaAction(action)
    }()
    
    let copyShellCommandAction: CocoaAction<Any> = {
        let action = Action<Void, Void, NoError> {
            let pasteboard = NSPasteboard.general()
            pasteboard.clearContents()
            if let port = ProfileManager.currentProxyPort.value {
                pasteboard.setString("export https_proxy=http://127.0.0.1:\(port);export http_proxy=http://127.0.0.1:\(port)", forType: NSStringPboardType)
            } else {
                pasteboard.setString("export https_proxy=;export http_proxy=", forType: NSStringPboardType)
            }
            return SignalProducer.empty
        }
        return CocoaAction(action)
    }()
    
    let allowClientFromLanAction: CocoaAction<Any> = {
        let action = Action<Void, Void, NoError> {
            ProfileManager.allowFromLan.modify {
                $0 = !$0
            }
            return SignalProducer.empty
        }
        return CocoaAction(action)
    }()
    
    let speedTestAction: CocoaAction<Any> = {
        let action = Action<Void, Void, NoError> {
            let t1 = Date().timeIntervalSince1970
            let proxySessionConfiguration = URLSessionConfiguration.ephemeral
            if ProfileManager.currentProxyPort.value != nil {
                proxySessionConfiguration.connectionProxyDictionary = [
                    kCFNetworkProxiesHTTPSEnable as AnyHashable: 1,
                    kCFNetworkProxiesHTTPSPort as AnyHashable: ProfileManager.currentProxyPort.value!,
                    kCFNetworkProxiesHTTPSProxy as AnyHashable: "127.0.0.1"
                ]
            }
            
            let urlSession = URLSession(configuration: proxySessionConfiguration)
            let request = URLRequest(url: URL(string: "https://www.gstatic.com/generate_204")!)
            urlSession.reactive.data(with: request).startWithResult {
                let notification = NSUserNotification()
                notification.soundName = NSUserNotificationDefaultSoundName
                notification.title = "Speed Test"
                switch $0 {
                case .success(let data):
                    let time = Int((Date().timeIntervalSince1970 - t1) * 1000)
                    notification.informativeText = "Response time: \(time)ms"
                case .failure(let error):
                    Utils.alertError("Speed test failed: \(error)")
                    notification.informativeText = "Speed test failed!"
                }
                NSUserNotificationCenter.default.deliver(notification)
            }
            return SignalProducer.empty
        }
        return CocoaAction(action)
    }()
    
    let autostartAtLoginAction: CocoaAction<Any> = {
        let action = Action<Void, Void, NoError> {
            AutostartManager.autostartAtLogin.modify {
                $0 = !$0
            }
            return SignalProducer.empty
        }
        return CocoaAction(action)
    }()
    
    let useDevChannelAction: CocoaAction<Any> = {
        let action = Action<Void, Void, NoError> {
            UpdateManager.useDevChannel.modify {
                $0 = !$0
            }
            return SignalProducer.empty
        }
        return CocoaAction(action)
    }()
    
    let checkForUpdatesAction: CocoaAction<Any> = {
        let action = Action<Any, Void, NoError> {
            SUUpdater.shared().checkForUpdates($0)
            return SignalProducer.empty
        }
        return CocoaAction(action) { $0 }
    }()
    
    let showLogAction: CocoaAction<Any> = {
        let action = Action<Void, Void, NoError> {
            if let logfile = (LoggerManager.logger as? DDFileLogger)?.logFileManager?.sortedLogFilePaths?.first {
                NSWorkspace.shared().openFile(logfile)
            }
            return SignalProducer.empty
        }
        return CocoaAction(action)
    }()
    
    let helpAction: CocoaAction<Any> = {
        let action = Action<Void, Void, NoError> {
            NSWorkspace.shared().open(URL(string: "https://github.com/zhuhaow/SpechtLite")!)
            return SignalProducer.empty
        }
        return CocoaAction(action)
    }()
    
    let aboutAction: CocoaAction<Any> = {
        let action = Action<Any, Void, NoError> {
            NSApplication.shared().activate(ignoringOtherApps: true)
            NSApplication.shared().orderFrontStandardAboutPanel($0)
            return SignalProducer.empty
        }
        return CocoaAction(action) { $0 }
    }()
    
    let exitAction: CocoaAction<Any> = {
        let action = Action<Any, Void, NoError> {
            NSApp.terminate($0)
            return SignalProducer.empty
        }
        return CocoaAction(action) { $0 }
    }()
    
    override init() {
        let icon = NSImage(named: "StatusIcon")!
        icon.isTemplate = true
        barItem = NSStatusBar.system().statusItem(withLength: -1)
        barItem.image = icon
        barItem.menu = NSMenu()
        
        super.init()
        
        barItem.menu!.delegate = self
    }
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        
        let currentProfile = ProfileManager.currentProfile.value
        for profile in ProfileManager.profileNames.value {
            let item = self.buildMenuItemForProfile(name: profile, running: profile == currentProfile)
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(withTitle: "Stop proxy server", action: CocoaAction<Any>.selector, keyEquivalent: "d").target = stopProxyServerAction
        menu.addItem(withTitle: "Open profile folder", action: CocoaAction<Any>.selector, keyEquivalent: "c").target = openProfileFolderAction
        menu.addItem(withTitle: "Reload profile", action: CocoaAction<Any>.selector, keyEquivalent: "r").target = reloadProfileAction
        
        menu.addItem(NSMenuItem.separator())
        
        let proxyItem = NSMenuItem(title: "Set as system proxy", action: CocoaAction<Any>.selector, keyEquivalent: "")
        proxyItem.target = setAsSystemProxyAction
        if ProxySettingManager.setAsSystemProxy.value {
            proxyItem.state = NSOnState
        }
        menu.addItem(proxyItem)
        
        menu.addItem(withTitle: "Copy shell export command", action: CocoaAction<Any>.selector, keyEquivalent: "").target = copyShellCommandAction
        
        let lanItem = NSMenuItem(title: "Allow Clients From Lan", action: CocoaAction<Any>.selector, keyEquivalent: "")
        lanItem.target = allowClientFromLanAction
        if ProfileManager.allowFromLan.value {
            lanItem.state = NSOnState
        }
        menu.addItem(lanItem)
        
        menu.addItem(withTitle: "Speed test", action: CocoaAction<Any>.selector, keyEquivalent: "").target = speedTestAction
        
        menu.addItem(NSMenuItem.separator())
        
        let autostartItem = NSMenuItem(title: "Autostart at login", action: CocoaAction<Any>.selector, keyEquivalent: "")
        autostartItem.target = autostartAtLoginAction
        if AutostartManager.autostartAtLogin.value {
            autostartItem.state = NSOnState
        }
        menu.addItem(autostartItem)
        
        let devItem = NSMenuItem(title: "Use dev channel", action: CocoaAction<Any>.selector, keyEquivalent: "")
        devItem.target = useDevChannelAction
        if UpdateManager.useDevChannel.value {
            devItem.state = NSOnState
        }
        menu.addItem(devItem)
        
        menu.addItem(withTitle: "Check for updates", action: CocoaAction<Any>.selector, keyEquivalent: "u").target = checkForUpdatesAction
        menu.addItem(withTitle: "Show log", action: CocoaAction<Any>.selector, keyEquivalent: "").target = showLogAction
        menu.addItem(withTitle: "Help", action: CocoaAction<Any>.selector, keyEquivalent: "").target = helpAction
        menu.addItem(withTitle: "About", action: CocoaAction<Any>.selector, keyEquivalent: "").target = aboutAction
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(withTitle: "Exit", action: CocoaAction<Any>.selector, keyEquivalent: "q").target = exitAction
    }
    
    func buildMenuItemForProfile(name: String, running: Bool) -> NSMenuItem {
        let item = NSMenuItem(title: name, action: CocoaAction<NSMenuItem>.selector, keyEquivalent: "")
        item.target = profileAction
        
        if running {
            item.state = NSOnState
        }
        
        return item
    }
}
