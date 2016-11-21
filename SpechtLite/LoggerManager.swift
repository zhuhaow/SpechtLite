import Foundation
import CocoaLumberjack
import NEKit

class LoggerManager {
    static var logger: DDLogger!
    
    static func setUpFileLogger() {
        DDLog.addLogger(DDTTYLogger.sharedInstance(), withLevel: .Info)
        
        let logger = DDFileLogger()
        logger.rollingFrequency = 60*60*3
        logger.logFileManager.maximumNumberOfLogFiles = 1
        DDLog.addLogger(logger, withLevel: .Info)
        self.logger = logger
        
        ObserverFactory.currentFactory = SPObserverFactory()
    }
}
