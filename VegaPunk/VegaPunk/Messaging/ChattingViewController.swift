//
//  ChatViewController.swift
//  Social Messaging
//
//  Created by Vũ Quý Đạt  on 21/04/2021.
//

import UIKit
import Alamofire
import Starscream

class ChattingViewController: UIViewController, UIImagePickerControllerDelegate, WebSocketDelegate, UINavigationControllerDelegate {
    func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocket) {
        switch event {
        case .connected(let headers):
            print("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            let jsonData = string.data(using: .utf8)!
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
//                decoder.dateDecodingStrategy = .secondsSince1970
                let resolvedData = try decoder.decode(WebSocketMessage.self, from: jsonData)
                print("Resolved WS Data successful!")
                self.receiveMessage(message: resolvedData)
                
            } catch {
                print(error.localizedDescription)
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
            break
        default:
            break
        }
    }
    
    // MARK: - App default configuration
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - CV config data.
    // Collection view config data.
    static let sectionHeaderElementKind = "section-header-element-kind"
    static let sectionFooterElementKind = "section-footer-element-kind"

    /// Datasource of main collectionview (chat content view).
    var dataSource: UICollectionViewDiffableDataSource<Int, Int>! = nil
    
    
    
    // MARK: - UI.
//    var chatView: UICollectionView! = nil
    let imagePicker = UIImagePickerController()
    
    
    
    // MARK: - IBOutlet.
    // Views.
    @IBOutlet weak var containChattingView: UIVisualEffectView!
    @IBOutlet weak var sendingImageViewContainer: UIView!
    
    @IBOutlet weak var chatView: UICollectionView!
    @IBOutlet weak var chatTextField: UITextField!
    @IBOutlet weak var sendingImage: UIImageView!
    @IBOutlet weak var removeSendingImageButton: UIButton!
    // Constraints.
    @IBOutlet weak var bottomAlignCollectionViewCS: NSLayoutConstraint!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var leadingOfTextFieldCS: NSLayoutConstraint!
    
    
    
    // MARK: - Variables.
    var keyboardHeight: CGFloat = 0.0
    var touchPosition: CGPoint = CGPoint(x: 0, y: 0)
    var messagesOfBox: [WebSocketMessage] = []
    var socket: WebSocket!
    
    var data: UserExtractedData?
    
    
    
    // MARK: - Closures.
    private lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureOnTable(_:)))
        gesture.delegate = self
        gesture.cancelsTouchesInView = true
        return gesture
    }()
    
    
    
    // MARK: - Set up methods.
    func setUpNavigationBar() {
        // BarButtonItem.
        let rightBarItem: UIBarButtonItem = {
            let bt = UIBarButtonItem(image: UIImage(systemName: "video.circle.fill"), style: .plain, target: self, action: #selector(rightBarItemAction))
            return bt
        }()
        navigationItem.rightBarButtonItem = rightBarItem
    }
    
    @objc func rightBarItemAction() {
        print("Right bar button was pressed!")
//        self.present(buildMainViewController(), animated: true)
    }
    
    
    
    // MARK: - Video call setup.
//    private let config = Config.default
//    private func buildMainViewController() -> UIViewController {
//
//        let webRTCClient = WebRTCClient(iceServers: self.config.webRTCIceServers)
//        let signalClient = self.buildSignalingClient()
//        let mainViewController = MainViewController(signalClient: signalClient, webRTCClient: webRTCClient)
//        let navViewController = UINavigationController(rootViewController: mainViewController)
//        navViewController.navigationBar.prefersLargeTitles = true
//        return navViewController
//    }
//
//    private func buildSignalingClient() -> SignalingClient {
//
//        // iOS 13 has native websocket support. For iOS 12 or lower we will use 3rd party library.
//        let webSocketProvider: WebSocketProvider
//
//        if #available(iOS 13.0, *) {
//            webSocketProvider = NativeWebSocket(url: self.config.signalingServerUrl)
//        } else {
//            webSocketProvider = StarscreamWebSocket(url: self.config.signalingServerUrl)
//        }
//
//        return SignalingClient(webSocket: webSocketProvider)
//    }
    
    
    
    // MARK: - Life cycle.
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setUpNavigationBar()
        configureHierarchy()
        prepareWebSocket()
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        imagePicker.delegate = self
        self.view.sendSubviewToBack(sendingImage)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
        fetchBoxesData {
//            self.configureDataSource()
            DispatchQueue.main.async { [self] in
                self.configureDataSource()
                self.scrollToBottom(of: chatView)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    // MARK: - Methods
    func receiveMessage(message: WebSocketMessage) {
        messagesOfBox.append(message)
        setUpDataSource()
    }
    
    func hideSendingImageViewContainer() {
        sendingImage.image = nil
        self.view.sendSubviewToBack(sendingImageViewContainer)
    }
    
    func prepareWebSocket() {
        print("ws://192.168.1.24:8080/api/messages/listen/" + (userDataGlobal?.mappingId!.uuidString)!)
        var request = URLRequest(url: URL(string: "ws://192.168.1.24:8080/api/messages/listen/" + (userDataGlobal?.mappingId!.uuidString)!)!)
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket.delegate = self
        socket.connect()

    }
    
    
    // MARK: - Request API.
    func fetchBoxesData(completion: @escaping () -> Void) {
        RequestEngine.getMessagesOfChatBox((data?.chatBox!.id)!) { messagesOfBox in
            self.messagesOfBox = messagesOfBox
            completion()
        }
    }
    
//    func getImageMess(fileObjectId: String) -> UIImage? {
//        do {
//            return UIImage(data: try Data(contentsOf: URL(string: "\(baseURL)messaging/getfile/\(fileObjectId)")!))
//        } catch {
//            print(error.localizedDescription)
//        }
//        return nil
//    }
    
//    func fetchFriendData(completion: @escaping () -> Void) {
//        let request_mess = ResourceRequest<User>(resourcePath: "mess/messesinbox/\(boxId)")
//        request_mess.getArray(token: Auth.token) { result in
//            switch result {
//            case .success(let data):
//                let sortMessages = data.sorted(by: { $0.creationDate < $1.creationDate })
//                if sortMessages.count > 0 {
//                    if messages[sortMessages[0].boxId] != nil {
//                        (messages[sortMessages[0].boxId])! = sortMessages
//                    } else {
//                        messages[sortMessages[0].boxId] = []
//                        (messages[sortMessages[0].boxId])! = sortMessages
//                    }
//                    if messages[self.boxId] != nil {
//                        self.messagesOfBox = messages[self.boxId]!
//                    }
//                }
//                completion()
//            case .failure:
//                break
//            }
//        }
//    }
    
    // MARK: - Delegate methods.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            sendingImage.contentMode = .scaleAspectFit
            sendingImage.image = pickedImage
            self.view.bringSubviewToFront(sendingImageViewContainer)
        }

        dismiss(animated: true, completion: nil)
    }
    
    
    
    // MARK: - IBAction
    @IBAction func sendMessage(_ sender: UIButton) {
//        push
//        delegate?.sendMessage(data: data)
        FeedBackTapEngine.tapped(style: .medium)
        guard let content = chatTextField.text else { return }
        let messageObject = Message(id: nil, createdAt: Date().iso8601String, sender: (userDataGlobal?.mappingId)!, chatBoxId: (data?.chatBox!.id)!, mediaType: .text, content: content)
        RequestEngine.createMessage(messageObject)
//        let encoder = JSONEncoder()
//        guard let data = try? encoder.encode(messageObject) else { return }
//        socket.write(string: String(data: data, encoding: .utf8)!, completion: nil)
        
            
        
        
        
        
//        var messageSendWSData = MessageSendWS(type: .newMess, majorData: majorData)
//        let request = ResourceRequest<MessageSendWS, MessageSendWS>(resourcePath: "messaging/send/mess")
//
//        if sendingImage.image != nil {
//            let fileUploadData = FileUpload(file: sendingImage.image?.pngData())
//            let postImageRequest = ResourceRequest<FileUpload, FileUpload>(resourcePath: "messaging/postfile")
//            postImageRequest.postFile(token: true, fileUploadData) { result in
//                switch result {
//                case .success(let data):
//                    messageSendWSData.majorData.fileId = data.fileObjectId
//                    messageSendWSData.majorData.type = .png
//                    request.post(token: true, messageSendWSData) { result in
//                        switch result {
//                        case .success(let data):
//                            DispatchQueue.main.async {
//                                self.hideSendingImageViewContainer()
//                                self.chatTextField.text = ""
//                            }
//                            break
//                        case .failure:
//                            break
//                        }
//                    }
//                    break
//                case .failure:
//                    break
//                }
//            }
//        } else if (messageSendWSData.majorData.text != nil) {
//            request.post(token: true, messageSendWSData) { result in
//                switch result {
//                case .success:
//                    DispatchQueue.main.async {
//                        self.chatTextField.text = ""
//                    }
//                    break
//                case .failure:
//                    break
//                }
//            }
//        }
    }
    
    @IBAction func pickImage(_ sender: UIButton) {
        FeedBackTapEngine.tapped(style: .medium)
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func removeSendingImageAction(_ sender: UIButton) {
        FeedBackTapEngine.tapped(style: .medium)
        hideSendingImageViewContainer()
    }
    

    // MARK: - Gesture.
    /// Pan Gesture on collection chat view. Using for swipe showing time stamp.
    @objc func panGestureOnTable(_ sender: UIPanGestureRecognizer) {
        let touchPoint = sender.location(in: chatView)
        if sender.state == .ended {
            chatView.visibleCells.forEach {
                if let cell = $0 as? FirstMessContentCellForSection {
                    UIView.animate(withDuration: 0.3, delay: 0.03,
                                   options: [.curveEaseOut],
                                   animations: { [weak self] in
                                    cell.constraint.constant = 0
                                    self?.view.layoutIfNeeded()
                                   }, completion: nil)
                }
                if let cell = $0 as? MessContentCell {
                    UIView.animate(withDuration: 0.3, delay: 0.03,
                                   options: [.curveEaseOut],
                                   animations: { [weak self] in
                                    cell.constraint.constant = 0
                                    self?.view.layoutIfNeeded()
                                   }, completion: nil)
                }
            }
            chatView.visibleSupplementaryViews(ofKind: ChattingViewController.sectionHeaderElementKind).forEach {
                if let cell = $0 as? HeaderSessionChat {
                    UIView.animate(withDuration: 0.3, delay: 0.03,
                                   options: [.curveEaseOut],
                                   animations: { [weak self] in
                                    cell.constraint.constant = 0
                                    self?.view.layoutIfNeeded()
                                   }, completion: nil)
                }
            }
        } else if sender.state == .began {
            touchPosition = touchPoint
        } else if sender.state == .changed {
            chatView.visibleCells.forEach {
                if let cell = $0 as? FirstMessContentCellForSection {
                    cell.constraint.constant = (touchPosition.x - touchPoint.x) < 75 ? ((touchPosition.x - touchPoint.x) > 0 ? (touchPosition.x - touchPoint.x) : 0) : 75
                }
                if let cell = $0 as? MessContentCell {
                    cell.constraint.constant = (touchPosition.x - touchPoint.x) < 75 ? ((touchPosition.x - touchPoint.x) > 0 ? (touchPosition.x - touchPoint.x) : 0) : 75
                }
            }
            chatView.visibleSupplementaryViews(ofKind: ChattingViewController.sectionHeaderElementKind).forEach {
                if let cell = $0 as? HeaderSessionChat {
                    cell.constraint.constant = (touchPosition.x - touchPoint.x) < 75 ? ((touchPosition.x - touchPoint.x) > 0 ? (touchPosition.x - touchPoint.x) : 0) : 75
                }
            }
        }
    }
    
}



// MARK: - Extensions.
extension ChattingViewController {
    
    
    
    // MARK: - Layout for collection view.
    /// - Tag: PinnedHeader
    func createLayout() -> UICollectionViewLayout {
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 1
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 5
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .estimated(45)),
            elementKind: ChattingViewController.sectionHeaderElementKind,
            alignment: .top)
        let sectionFooter = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .estimated(30)),
            elementKind: ChattingViewController.sectionFooterElementKind,
            alignment: .bottom)
        sectionHeader.pinToVisibleBounds = true
        sectionHeader.zIndex = 2
        section.boundarySupplementaryItems = [sectionHeader]

        let layout = UICollectionViewCompositionalLayout(section: section, configuration: config)
        return layout
        
//        let config = UICollectionLayoutListConfiguration(appearance: .plain)
//        return UICollectionViewCompositionalLayout.list(using: config)
    }
}



extension ChattingViewController {
    
    
    
    // MARK: - Config collection view.
    func configureHierarchy() {
        
        // Work with infile collection view.
//        chatView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        // Work with xib collection view.
        chatView.frame = view.bounds
        chatView.collectionViewLayout = createLayout()
        
        chatView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        chatView.backgroundColor = .systemGray6
        view.addSubview(chatView)
        chatView.delegate = self
        chatView.register(UINib(nibName: MessContentCell.reuseIdentifier, bundle: nil), forCellWithReuseIdentifier: MessContentCell.reuseIdentifier)
        chatView.register(UINib(nibName: FirstMessContentCellForSection.reuseIdentifier, bundle: nil), forCellWithReuseIdentifier: FirstMessContentCellForSection.reuseIdentifier)
        chatView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell_at_last_section")
        chatView.register(UINib(nibName: HeaderSessionChat.reuseIdentifier, bundle: nil), forSupplementaryViewOfKind: ChattingViewController.sectionHeaderElementKind, withReuseIdentifier: HeaderSessionChat.reuseIdentifier)
        chatView.register(UINib(nibName: HeaderSessionChat.reuseIdentifier, bundle: nil), forSupplementaryViewOfKind: ChattingViewController.sectionFooterElementKind, withReuseIdentifier: HeaderSessionChat.reuseIdentifier)
        chatView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: ChattingViewController.sectionFooterElementKind, withReuseIdentifier: "footer")
        chatView.addGestureRecognizer(panGesture)
        view.bringSubviewToFront(containChattingView)
    }
    
    // MARK: - Config datasource.
    /// - Tag: PinnedHeaderRegistration
    func configureDataSource() {
            
        self.dataSource = UICollectionViewDiffableDataSource<Int, Int>(collectionView: chatView) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: Int) -> UICollectionViewCell? in
            if indexPath.section == self.messagesOfBox.count {
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "cell_at_last_section",
                        for: indexPath)
                return cell
            }
            if indexPath.row == 0 {
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: FirstMessContentCellForSection.reuseIdentifier,
                        for: indexPath) as? FirstMessContentCellForSection else { fatalError("Cannot create new cell") }
                let message = self.messagesOfBox[indexPath.section]
                
                if message.sender.uuidString == userDataGlobal?.mappingId?.uuidString {
                    cell.senderName.text = userDataGlobal?.userInformation?.name
                    cell.senderName.textColor = .orange
                } else {
                    cell.senderName.text = self.data?.user.name
                    cell.senderName.textColor = .link
                }
                cell.timeLabel.text = message.createdAt.toDate().iso8601StringShortDateTime
                cell.contentTextLabel.text = message.message
                return cell
            }
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MessContentCell.reuseIdentifier,
                for: indexPath) as? MessContentCell else { fatalError("Cannot create new cell") }
            let message = self.messagesOfBox[indexPath.section]
            cell.contentTextLabel.text = message.message
            cell.timeLabel.text = message.createdAt.toDate().iso8601StringShortDateTime
            return cell
        }
        
        dataSource.supplementaryViewProvider = { [self] (collectionView, elementKind, indexPath) in
            let sec = indexPath.section
            if sec == self.messagesOfBox.count {
                guard let header = collectionView.dequeueReusableSupplementaryView(
                    ofKind: elementKind,
                    withReuseIdentifier: HeaderSessionChat.reuseIdentifier,
                    for: indexPath
                ) as? HeaderSessionChat else { fatalError("Cannot create new header!") }
                header.frame.size.height = 0
                return header
            }
            if elementKind == ChattingViewController.sectionHeaderElementKind {
                guard let header = collectionView.dequeueReusableSupplementaryView(
                    ofKind: elementKind,
                    withReuseIdentifier: HeaderSessionChat.reuseIdentifier,
                    for: indexPath
                ) as? HeaderSessionChat else { fatalError("Cannot create new header!") }
                let message = self.messagesOfBox[sec]
                return header
            } else {
                let supplementaryView = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: "footer", for: indexPath)
                if (sec == self.messagesOfBox.count - 1) {
                    supplementaryView.frame.size.height = 84
                } else {
                    supplementaryView.frame.size.height = 0
                }
                return supplementaryView
            }
//            if sec == self.messagesOfBox.count {
//                guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: HeaderSessionChat.reuseIdentifier, for: indexPath) as? HeaderSessionChat else { fatalError("Cannot create new header!") }
//                header.frame.size.height = 0
//                return header
//            }
//            if elementKind == ChattingViewController.sectionHeaderElementKind {
//                guard let supplementaryView = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: HeaderSessionChat.reuseIdentifier, for: indexPath) as? HeaderSessionChat else { fatalError("Cannot create new cell") }
//
//                let message = self.messagesOfBox[index.section]
//
//                supplementaryView.avatar.image = nil
//                if message.senderId == self.authUser?.id.uuidString {
//                } else {
//
//                }
//
//                return supplementaryView
//            } else {
//                let supplementaryView = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: "footer", for: indexPath)
//                if (index.section == self.messagesOfBox.count - 1) {
//                    supplementaryView.frame.size.height = 84
//                } else {
//                    supplementaryView.frame.size.height = 0
//                }
//                return supplementaryView
//            }
        }
        
        setUpDataSource()
    }
    
    func setUpDataSource() {
            var sections = Array(0..<messagesOfBox.count)
        var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
        sections.forEach {
            snapshot.appendSections([$0])
            snapshot.appendItems([$0])
        }
        dataSource.apply(snapshot, animatingDifferences: true)
        scrollToBottom(of: chatView)
    }
    
    func scrollToBottom(of collectionView: UICollectionView) {
        if messagesOfBox.count > 0 {
            chatView.scrollToItem(at: IndexPath(item: 0, section: messagesOfBox.count - 1), at: .bottom, animated: true)
        }
        self.view.layoutIfNeeded()
    }
}



// MARK: - Select cells.
extension ChattingViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        collectionView.deselectItem(at: indexPath, animated: true)
    }
}



// MARK: - Config gesture recognizer.
extension ChattingViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return [gestureRecognizer, otherGestureRecognizer].contains(panGesture)
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let gesture = gestureRecognizer as? UIPanGestureRecognizer, gesture == panGesture {
            let translation = gesture.translation(in: gesture.view)
            return (abs(translation.x) > abs(translation.y)) && (gesture == panGesture)
        }
        return true
    }
    
    @IBAction func hideKeyBoardTap(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
}



// MARK: - Keyboard.
extension ChattingViewController: UITextFieldDelegate {
    @objc func keyboardWillShow(_ notification: NSNotification) {
        if let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            leadingOfTextFieldCS.constant = 8
            keyboardHeight = keyboardRect.height
            self.bottomAlignCollectionViewCS.constant = keyboardHeight
            self.view.layoutIfNeeded()
            scrollToBottom(of: chatView)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            leadingOfTextFieldCS.constant = 120
            keyboardHeight = keyboardRect.height
            self.bottomAlignCollectionViewCS.constant = 0
            self.view.layoutIfNeeded()
            scrollToBottom(of: chatView)
        }
    }
}
