import Cocoa
import NEKit
import CocoaLumberjackSwift

class SPObserverFactory: ObserverFactory {

    override func getObserverForAdapterSocket(_ socket: AdapterSocket) -> Observer<AdapterSocketEvent>? {
        return SPAdapterSocketObserver()
    }

    class SPAdapterSocketObserver: Observer<AdapterSocketEvent> {

        override func signal(_ event: AdapterSocketEvent) {
            switch event {
            case .socketOpened(let socket, let request):
                DDLogInfo("Request: \(request.host) Type: \(socket.typeName) Rule: \(request.matchedRule?.description ?? "")")
                break
            default:
                break
            }
        }
    }
}
