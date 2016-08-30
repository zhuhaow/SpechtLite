//
//  SPObserverFactory.swift
//  SpechtLite
//
//  Created by 周斌佳 on 16/8/30.
//  Copyright © 2016年 Zhuhao Wang. All rights reserved.
//

import Cocoa
import NEKit
import CocoaLumberjackSwift

class SPObserverFactory: ObserverFactory {

    override func getObserverForAdapterSocket(socket: NEKit.AdapterSocket) -> NEKit.Observer<NEKit.AdapterSocketEvent>? {
        return SPAdapterSocketObserver()
    }

    class SPAdapterSocketObserver: Observer<AdapterSocketEvent> {
        override func signal(event: AdapterSocketEvent) {
            switch event {
            case .SocketOpened(let socket, let request):
                DDLogInfo("Request: \(request.host) Type: \(socket.type) Rule: \(request.matchedRule!)")
                break
            default:
                break
            }
        }
    }
}
