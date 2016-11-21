import Foundation
import SystemConfiguration

let version = "0.2.0"

func main(_ args: [String]) {
    var port: Int = 0
    var flag: Bool = false
    
    if args.count > 2 {
        guard let _port = Int(args[1]) else {
            print("ERROR: port is invalid.")
            exit(EXIT_FAILURE)
        }
        guard args[2] == "enable" || args[2] == "disable" else {
            print("ERROR: flag is invalid.")
            exit(EXIT_FAILURE)
        }
        port = _port
        flag = args[2] == "enable"
    } else if args.count == 2 {
        if args[1] == "version" {
            print(version)
            exit(EXIT_SUCCESS)
        }
    } else {
        print("Usage: ProxyConfig <port> <enable/disable>")
        exit(EXIT_FAILURE)
    }
    
    var authRef: AuthorizationRef? = nil
    let authFlags: AuthorizationFlags = [.extendRights, .interactionAllowed, .preAuthorize]
    
    let authErr = AuthorizationCreate(nil, nil, authFlags, &authRef)
    
    guard authErr == noErr else {
        print("Error: Failed to create administration authorization due to error \(authErr).")
        exit(EXIT_FAILURE)
    }
    
    guard authRef != nil else {
        print("Error: No authorization has been granted to modify network configuration.")
        exit(EXIT_FAILURE)
    }
    
    if let prefRef = SCPreferencesCreateWithAuthorization(nil, "SpechtLite" as CFString, nil, authRef),
        let sets = SCPreferencesGetValue(prefRef, kSCPrefNetworkServices) {
        
        for key in sets.allKeys {
            let dict = sets.object(forKey: key) as? NSDictionary
            let hardware = ((dict?["Interface"]) as? NSDictionary)?["Hardware"] as? String
            if hardware == "AirPort" || hardware == "Ethernet" {
                let ip = flag ? "127.0.0.1" : ""
                let port0 = flag ? port : 0
                let port1 = flag ? port + 1 : 0
                let enableInt = flag ? 1 : 0
                let settings = [
                    kCFNetworkProxiesHTTPProxy as String : ip,
                    kCFNetworkProxiesHTTPPort as String : port0,
                    kCFNetworkProxiesHTTPEnable as String : enableInt,
                    kCFNetworkProxiesHTTPSProxy as String : ip,
                    kCFNetworkProxiesHTTPSPort as String : port0,
                    kCFNetworkProxiesHTTPSEnable as String : enableInt,
                    kCFNetworkProxiesSOCKSProxy as String : ip,
                    kCFNetworkProxiesSOCKSPort as String : port1,
                    kCFNetworkProxiesSOCKSEnable as String : enableInt,
                    kCFNetworkProxiesExceptionsList as String : [
                        "192.168.0.0/16":
                        "10.0.0.0/8",
                        "172.16.0.0/12":
                        "127.0.0.1",
                        "localhost":
                        "*.local"
                    ]
                ] as [String : Any]
                let proxySettings = settings as CFDictionary
                
                let path = "/\(kSCPrefNetworkServices)/\(key)/\(kSCEntNetProxies)"
                SCPreferencesPathSetValue(prefRef, path as CFString, proxySettings)
            }
        }
        
        SCPreferencesCommitChanges(prefRef)
        SCPreferencesApplyChanges(prefRef)
    }
    
    AuthorizationFree(authRef!, AuthorizationFlags())
    
    exit(EXIT_SUCCESS)
}

main(CommandLine.arguments)
