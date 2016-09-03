import Cocoa
import NEKit
import CocoaLumberjackSwift

class SPObserverFactory: ObserverFactory {

    override func getObserverForAdapterSocket(socket: AdapterSocket) -> Observer<AdapterSocketEvent>? {
        return SPAdapterSocketObserver()
    }

    class SPAdapterSocketObserver: Observer<AdapterSocketEvent> {

        override func signal(event: AdapterSocketEvent) {
            switch event {
            case .SocketOpened(let socket, let request):
                DDLogInfo("Request: \(request.host) Type: \(socket.type) Rule: \(request.matchedRule?.description ?? "")")
                break
            default:
                break
            }
        }
    }
}
