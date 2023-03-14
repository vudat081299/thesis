//
//  MainTapBarController.swift
//  VegaPunk
//
//  Created by Dat Vu on 08/01/2023.
//

import UIKit
import Starscream
import Nuke

let imageUrl = "http://\(configureIp):8080/api/files/63e28ee8c6b2f7c2a220cc04"

struct ViewControllerData {
    let title: String
    let iconNormal: String
    let selectedIcon: String
    let viewController: UINavigationController
    
    
    // MARK: - Data.
    static var viewControllerDatas: [ViewControllerData] = {
        let array = [
//            ViewControllerData(title: "Profile", iconNormal: "person", selectedIcon: "person.fill", viewController: UINavigationController(rootViewController: ViewController())),
            ViewControllerData(title: "Nhắn tin", iconNormal: "message", selectedIcon: "message.fill", viewController: UINavigationController(rootViewController: ChatBoxViewController())),
            ViewControllerData(title: "Thông tin cá nhân", iconNormal: "person", selectedIcon: "person.fill", viewController: UINavigationController(rootViewController: UserProfileViewController())),
        ]
        var dataList: [ViewControllerData] = []
        array.forEach {
            $0.viewController.topViewController?.title = $0.title
            $0.viewController.tabBarItem.image = UIImage(systemName: $0.iconNormal)
            $0.viewController.tabBarItem.selectedImage = UIImage(systemName: $0.selectedIcon)
//            $0.viewController.navigationBar.prefersLargeTitles = true
            $0.viewController.navigationBar.sizeToFit()
            $0.viewController.navigationItem.largeTitleDisplayMode = .always
            dataList.append($0)
        }
        return dataList
    }()
}


class MainTabBarController: UITabBarController {
    
    //
    let notificationCenter = NotificationCenter.default
    var socket: WebSocket!
    
    
    // MARK: - Life cycle.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        ViewControllerData.viewControllerDatas.forEach {
            viewControllers?.append($0.viewController)
        }
        connectWebSocket()
        notificationCenter.addObserver(self, selector: #selector(send(_:)), name: .WebsocketSendPackage, object: nil)
        
        DataLoader.sharedUrlCache.diskCapacity = 0
        let pipeline = ImagePipeline {
            let dataCache = try? DataCache(name: "com.raywenderlich.Far-Out-Photos.datacache")
            dataCache?.sizeLimit = 200 * 1024 * 1024
            $0.dataCache = dataCache
        }
        ImagePipeline.shared = pipeline
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    deinit {
        notificationCenter.removeObserver(self, name: .WebsocketSendPackage, object: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    // MARK: - Mini tasks
    func connectWebSocket() {
        releaseWebSocket()
        print("\(#function)")
        let userId = (AuthenticatedUser.retrieve()?.data?.id?.uuidString) ?? ""
        let domain = RouteCoordinator.websocket.url()! + userId
        var request = URLRequest(url: URL(string: domain)!)
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket.delegate = self
        socket.connect()
    }
    func releaseWebSocket() {
        if socket != nil {
            socket.disconnect()
    //        socket.forceDisconnect()
            socket = nil
        }
    }
    
    
    // MARK: - App default configuration
//    override var prefersStatusBarHidden: Bool {
//        return true
//    }
}


// MARK: - WebSocket
extension MainTabBarController: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            print("Web socket is connected: \(headers)")
        case .disconnected(let reason, let code):
            print("Web socket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            let decoder = JSONDecoder()
            guard let data = string.data(using: .utf8),
                  let webSocketPackage = try? decoder.decode(WebSocketPackage.self, from: data)
            else {
                print("Web socket cannot decode web socket package!")
                return
            }
            switch webSocketPackage.type {
            case .message:
                if let message = webSocketPackage.convertToMessage() {
                    Messages([message]).store()
                    NotificationCenter.default.post(name: .WebsocketReceivedMessagePackage, object: nil)
                }
                break
            case .chatbox:
                NotificationCenter.default.post(name: .WebsocketReceivedChatBoxPackage, object: nil)
                break
            case .user:
                NotificationCenter.default.post(name: .WebsocketReceivedUserPackage, object: nil)
                break
            case .call:
                let userInfo: [String: UUID?] = ["sender": webSocketPackage.message.sender]
                NotificationCenter.default.post(name: .WebsocketReceivedCallPackage, object: nil, userInfo: userInfo as [AnyHashable : Any])
            }
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            print("reconnectSuggested")
            connectWebSocket()
            break
        case .cancelled:
            print("cancelled")
            connectWebSocket()
        case .error(let error):
            print("error")
            handleError(error)
            connectWebSocket()
        }
    }
    func handleError(_ error: Error?) {
        if let e = error as? WSError {
            print("websocket encountered an error: \(e.message)")
        } else if let e = error {
            print("websocket encountered an error: \(e.localizedDescription)")
        } else {
            print("websocket encountered an error")
        }
    }
    @objc func send(_ notification: Notification) {
        guard let package = notification.userInfo?["package"] as? WebSocketPackage else {
            return
        }
        do {
            try socket.write(string: package.json())
        } catch {
            
        }
//        socket.write(string: """
//{
//                     "type": 0,
//                     "message": {
//                       "sender":"B0A9FBBE-6350-43FE-A3E6-C11CBC974B2D",
//                       "chatboxId":"7F7A0D37-956B-49F8-8735-45B8141B10B6",
//                       "mediaType":"text",
//                       "content":"This function get’s called when we press the button. The‘.goingAway’ is the close code where as the reason is that you provide to user.Where are we going to call all these three functions ???The closeSession is already added as the target for the button we created earlier. Where as the send & receive will be called under the didOpenWithProtocol protocol.Download the full source code HERE. I hope I was able to explain well. If I did then please do follow me and share my article with your friends. This really motivates me to kee"
//                     }
//                  }
//""")
    }
}
