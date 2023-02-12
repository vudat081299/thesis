//
//  MainTapBarController.swift
//  VegaPunk
//
//  Created by Dat Vu on 08/01/2023.
//

import UIKit
import Starscream

let imageUrl = "http://192.168.1.24:8080/api/files/63e28ee8c6b2f7c2a220cc04"

struct ViewControllerData {
    let title: String
    let iconNormal: String
    let selectedIcon: String
    let viewController: UINavigationController
    
    
    // MARK: - Data.
    static var viewControllerDatas: [ViewControllerData] = {
        let array = [
//            ViewControllerData(title: "Profile", iconNormal: "person", selectedIcon: "person.fill", viewController: UINavigationController(rootViewController: ViewController())),
            ViewControllerData(title: "Chat box", iconNormal: "message", selectedIcon: "message.fill", viewController: UINavigationController(rootViewController: ChatBoxViewController())),
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
    var socket: WebSocket!
    var isConnected = false
    
    // MARK: - Life cycle.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        ViewControllerData.viewControllerDatas.forEach {
            viewControllers?.append($0.viewController)
        }
        
        connectWebSocket()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
        print("\(#function)")
        let userMappingId = (AuthenticatedUser.retrieve()?.data?.mappingId?.uuidString) ?? ""
        let domain = RouteCoordinator.websocket.url()! + userMappingId
        print(domain)
        var request = URLRequest(url: URL(string: domain)!)
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket.delegate = self
        socket.connect()
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
            isConnected = true
            print("Web socket is connected: \(headers)")
        case .disconnected(let reason, let code):
            isConnected = false
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
                var storedMessages = Messages.retrieve(with: webSocketPackage.message.chatBoxId!).messages
                storedMessages.receive([webSocketPackage.convertToMessage()])
                Messages(storedMessages).store()
//                NotificationCenter.default.post(name: .WebsocketReceivedPackage, object: nil, userInfo: ["package": webSocketPackage])
                NotificationCenter.default.post(name: .WebsocketReceivedPackage, object: nil)
                
            case .chatBox:
                break
            case .user:
                break
            }
            print(webSocketPackage.message)
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
            isConnected = false
            connectWebSocket()
        case .error(let error):
            print("error")
            isConnected = false
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
}
