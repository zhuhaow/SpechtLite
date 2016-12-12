import Foundation
import CocoaLumberjack
import NEKit

class LoggerManager {
    static var logger: DDLogger!
    
    static func setUp() {
        DDLog.add(DDTTYLogger.sharedInstance(), with: .info)
        
        let logger = DDFileLogger()
        logger?.rollingFrequency = TimeInterval(60*60*3)
        logger?.logFileManager.maximumNumberOfLogFiles = 1
        DDLog.add(logger, with: .info)
        self.logger = logger
        
        ObserverFactory.currentFactory = SPObserverFactory()
    }
}
