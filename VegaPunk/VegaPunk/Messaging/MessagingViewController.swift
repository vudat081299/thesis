//
//  ChatViewController.swift
//  Social Messaging
//
//  Created by Vũ Quý Đạt  on 21/04/2021.
//


// postgresql://vapor_username:vapor_password@localhost
import UIKit
import LocalAuthentication
import CryptoSwift

let iv = "4ca00ff4c898d61e1edbf1800618fb28".transformToArrayUInt8()
let key = "140b41b22a29beb4061bda66b6747e14".transformToArrayUInt8()

class MessagingViewController: UIViewController {
    
    
    // MARK: - Properties
    // Collection view config data.
    static let sectionHeaderElementKind = "section-header-element-kind"
    static let sectionFooterElementKind = "section-footer-element-kind"
    
    //
    let notificationCenter = NotificationCenter.default
    let imagePicker = UIImagePickerController()
    let managingChatBoxViewController = ManagingChatBoxViewController()
    
    //
    var dataSource: UICollectionViewDiffableDataSource<Int, ChatboxMessage>! = nil
    var user: User!
    var extractedChatBox: ChatBoxViewModel!
    var messageViewModel = [[ChatboxMessage]]()
    var members = [User]()
    var previousSendingPackage: WebSocketPackage!
    
    var keyboardHeight: CGFloat = 0.0
    var touchPosition: CGPoint = CGPoint(x: 0, y: 0)
    var heightInputContainerOnDeviceType: CGFloat = 50
    var avatarFileIds = [String?]()
    
    
    // MARK: - IBOutlet
    // Views
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var inputFieldViewContainer: UIVisualEffectView!
    
    @IBOutlet weak var pickedImageContainer: UIVisualEffectView!
    @IBOutlet weak var chatTextField: UITextField!
    @IBOutlet weak var pickedImage: UIImageView!
    @IBOutlet weak var removeSendingImageButton: UIButton!
    @IBOutlet weak var sendMessageButton: UIButton!
    
    // Constraints
    @IBOutlet weak var bottomSpaceCollectionView: NSLayoutConstraint!
    @IBOutlet weak var leadingAlignPickedImage: NSLayoutConstraint!
    @IBOutlet weak var widthTextField: NSLayoutConstraint!
    @IBOutlet weak var heightInputContainer: NSLayoutConstraint!
    
    var callVideoButton: UIBarButtonItem!
    
    // Gesture
    private lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureOnCollectionView(_:)))
        gesture.delegate = self
        gesture.cancelsTouchesInView = true
        return gesture
    }()
    
    // App default configuration
//    override var prefersStatusBarHidden: Bool {
//        return true
//    }
    
    // MARK: - Video call setup.
    private let config = Config.default
    private func buildMainViewController() -> UIViewController {
        let webRTCClient = WebRTCClient(iceServers: self.config.webRTCIceServers)
        let signalClient = self.buildSignalingClient()
        let mainViewController = MainViewController(signalClient: signalClient, webRTCClient: webRTCClient)
        mainViewController.user = self.user
        mainViewController.extractedChatBox = self.extractedChatBox
        mainViewController.modalPresentationStyle = .fullScreen
        let navViewController = UINavigationController(rootViewController: mainViewController)
        if #available(iOS 11.0, *) {
            navViewController.navigationBar.prefersLargeTitles = true
        }
        else {
            navViewController.navigationBar.isTranslucent = false
        }
        return navViewController
    }
    
    private func buildSignalingClient() -> SignalingClient {
        // iOS 13 has native websocket support. For iOS 12 or lower we will use 3rd party library.
        let webSocketProvider: WebSocketProvider
        if #available(iOS 13.0, *) {
            webSocketProvider = NativeWebSocket(url: self.config.signalingServerUrl)
        } else {
            webSocketProvider = StarscreamWebSocket(url: self.config.signalingServerUrl)
        }
        return SignalingClient(webSocket: webSocketProvider)
    }
    
    
    // MARK: - Life cycles
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        prepareView()
        
        // Configure collection view
        configureHierarchy()
        configureDataSource()
        
        // Observer
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(websocketReceivedMessagePackage(_:)), name: .WebsocketReceivedMessagePackage, object: nil)
        notificationCenter.addObserver(self, selector: #selector(websocketReceivedCallPackage(_:)), name: .WebsocketReceivedCallPackage, object: nil)
        
        
        // Delegate
        imagePicker.delegate = self
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Prepare data
        user = AuthenticatedUser.retrieve()?.data
        fetch()
        
        // Prepare view
        tabBarController?.tabBar.isHidden = true
        setUpNavigationBar()
        setTitle()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollToBottom(of: collectionView)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        hidePickedImageContainer()
        self.chatTextField.resignFirstResponder()
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        scrollToTop(of: collectionView)
    }
    deinit {
        notificationCenter.removeObserver(self, name: .WebsocketReceivedMessagePackage, object: nil)
        notificationCenter.removeObserver(self, name: .WebsocketReceivedCallPackage, object: nil)
        
    }
    
    
    // MARK: - Tasks
    /// This method fetch data from local and then fetch data from server.
    /// - Note: This method must call after collection view is set up because the reload collection view method is called in this function.
    /// - Usage: Fetch data for messaging view controller. It's destination is transform fetched data to `[[Message]]`.
    func fetch() {
        let chatBox = self.extractedChatBox.chatBox
        self.members = self.extractedChatBox.members.retrieveUsers()
        
        // fetch from local
        setUp(for: chatBox.id)
        
        // fetch from server
        var time: String!
        if self.messageViewModel.count > 0 {
            time = self.messageViewModel.last?.last?.createdAt
        }
        if time == nil { time = "0" }
        RequestEngine.fetchMessages(from: time, in: chatBox.id) { resolveMessages in
            if (resolveMessages.count == 0) { return }
            setUp(for: chatBox.id)
        }
        func setUp(for chatBoxId: UUID) {
            self.messageViewModel.retrieve(from: chatBoxId)
            self.markLastestSeenMessage()
            self.applySnapshot()
        }
    }
    func prepareView() {
        view.clipsToBounds = true
        view.backgroundColor = .systemBackground
        pickedImage.contentMode = .scaleAspectFit
        pickedImageContainer.border(8)
        pickedImageContainer.dropShadow()
        let myContext = LAContext()
        myContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        if myContext.biometryType == .touchID {
            heightInputContainerOnDeviceType = 50
        } else {
            heightInputContainerOnDeviceType = 84
        }
        heightInputContainer.constant = heightInputContainerOnDeviceType
        hidePickedImageContainer()
    }
    func hidePickedImageContainer() {
        leadingAlignPickedImage.constant = -160
        UIView.animate(withDuration: 0.3,
                       animations: { [self] in
            view.layoutIfNeeded()
        }, completion: { [self] isCompleted in
            if isCompleted {
                pickedImage.image = nil
                pickedImageContainer.isHidden = true
            }
        })
    }
    @objc func websocketReceivedMessagePackage(_ notification: Notification) {
//        guard let package = notification.userInfo?["package"] as? WebSocketPackage
//        else {
//            return
//        }
//        if (navigationController?.topViewController != self ||
//            package.message.chatboxId != extractedChatBox.chatbox.id) {
//            return
//        }
//        messages.receive([package.convertToMessage()])
//        updateDataSource()
        
        if navigationController?.topViewController == self {
            let chatBoxId = extractedChatBox.chatBox.id
            var storedMessaged = Messages.retrieve(with: chatBoxId).messages
            self.messageViewModel = storedMessaged.transformStructure()
            markLastestSeenMessage()
            applySnapshot()
        }
    }
    
    @objc func websocketReceivedCallPackage(_ notification: Notification) {
        guard let sender = notification.userInfo?["sender"] as? UUID else {
            return
        }
        if members.count == 1 && members.first?.id == sender {
            callVideoButton.tintColor = .systemGreen
            FeedBackTapEngine.tapped(style: .medium)
        }
    }
    
    
    // MARK: - Mini tasks
    func resetData() {
        members = []
        messageViewModel = []
        user = nil
    }
    func markLastestSeenMessage() {
        DispatchQueue.main.async {
            if self.navigationController?.topViewController == self {
                self.messageViewModel.last?.last?.store(.lastestSeenMessage)
            }
        }
    }
    func getUser(with userId: UUID) -> User? {
        if userId == user.id { return user }
        return members.first {
            $0.id == userId
        }
    }
    func checkIsSender(_ userId: UUID) -> Bool {
        if userId == user.id { return true }
        return false
    }
    
    
    // MARK: - IBAction
    @IBAction func sendMessage(_ sender: UIButton) {
        FeedBackTapEngine.tapped(style: .medium)
        if pickedImage.image != nil {
            sendMessageButton.isEnabled = false
            RequestEngine.upload((pickedImage.image?.resized(to: 720).pngData())!) { [self] fileId in
                do {
                    let aes = try AES(key: key, blockMode: CBC(iv: iv), padding: .pkcs7)
                    let encrypted = try aes.encrypt(fileId.bytes)
                    let cipherText = encrypted.transformToHex()
                    
                    previousSendingPackage = WebSocketPackage(type: .message, message: WebSocketPackageMessage(sender: user.id, chatboxId: extractedChatBox.chatBox.id, mediaType: .file, content: cipherText))
                    NotificationCenter.default.post(name: .WebsocketSendPackage, object: nil, userInfo: ["package": previousSendingPackage!])
                    hidePickedImageContainer()
                    sendMessageButton.isEnabled = true
                } catch {
                    
                }
            }
        } else {
            if (chatTextField.text == nil || chatTextField.text?.count == 0) { return }
            do {
                let aes = try AES(key: key, blockMode: CBC(iv: iv), padding: .pkcs7)
                let encrypted = try aes.encrypt(chatTextField.text!.bytes)
                let cipherText = encrypted.transformToHex()
                
                previousSendingPackage = WebSocketPackage(type: .message, message: WebSocketPackageMessage(sender: user.id, chatboxId: extractedChatBox.chatBox.id, mediaType: .text, content: cipherText))
                chatTextField.text = ""
                NotificationCenter.default.post(name: .WebsocketSendPackage, object: nil, userInfo: ["package": previousSendingPackage!])
            } catch {
                
            }
        }
    }
    @IBAction func pickImage(_ sender: UIButton) {
        FeedBackTapEngine.tapped(style: .medium)
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = ["public.image", "public.movie"]
        self.present(imagePicker, animated: true, completion: nil)
    }
    @IBAction func removeSendingImageAction(_ sender: UIButton) {
        FeedBackTapEngine.tapped(style: .medium)
        hidePickedImageContainer()
    }
}


// MARK: - NavigationBar
extension MessagingViewController {
    @objc func callVideoAction() {
        FeedBackTapEngine.tapped(style: .medium)
        present(buildMainViewController(), animated: true)
    }
    @objc func manageChatBoxAction() {
        FeedBackTapEngine.tapped(style: .medium)
        managingChatBoxViewController.users[0] = members.sortWithJoin()
        managingChatBoxViewController.users[1] = members.getOtherUsers().sortWithJoin()
        managingChatBoxViewController.chatBoxId = extractedChatBox.chatBox.id
        managingChatBoxViewController.navigationController?.modalPresentationStyle = .fullScreen
        navigationController?.pushViewController(managingChatBoxViewController, animated: true)
    }
    func setUpNavigationBar() {
        navigationItem.largeTitleDisplayMode = .never
//        navigationItem.largeTitleDisplayMode = .never
//        self.title = extractedChatBox.chatbox.name
//        navigationController?.navigationBar.prefersLargeTitles = false
//        self.navigationController?.modalPresentationStyle = .fullScreen
        
        /// Call video BarButtonItem.
        callVideoButton = {
            let bt = UIBarButtonItem(image: UIImage(systemName: "video.circle.fill"), style: .plain, target: self, action: #selector(callVideoAction))
            return bt
        }()
        callVideoButton.tintColor = .systemBlue
        let addMemberButton: UIBarButtonItem = {
            let bt = UIBarButtonItem(image: UIImage(systemName: "plus.bubble.fill"), style: .plain, target: self, action: #selector(manageChatBoxAction))
            return bt
        }()
        if members.count == 1 {
            navigationItem.rightBarButtonItems = [addMemberButton, callVideoButton]
        } else {
            navigationItem.rightBarButtonItems = [addMemberButton]
        }
        
    }
    func setTitle() {
        if members.count == 0 {
            title = user.name
        } else if members.count == 1 {
            title = members.first?.name
        } else {
            title = extractedChatBox.chatBox.name
        }
    }
}

    
// MARK: - Pan gesture.
extension MessagingViewController: UIGestureRecognizerDelegate {
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
    /// Pan Gesture on collection chat view. Using for swipe showing time stamp.
    @objc func panGestureOnCollectionView(_ sender: UIPanGestureRecognizer) {
        let touchPoint = sender.location(in: collectionView)
        if sender.state == .ended {
            collectionView.visibleCells.forEach {
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
            collectionView.visibleSupplementaryViews(ofKind: MessagingViewController.sectionHeaderElementKind).forEach {
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
            collectionView.visibleCells.forEach {
                if let cell = $0 as? FirstMessContentCellForSection {
                    cell.constraint.constant = (touchPosition.x - touchPoint.x) < 120 ? ((touchPosition.x - touchPoint.x) > 0 ? (touchPosition.x - touchPoint.x) : 0) : 120
                }
                if let cell = $0 as? MessContentCell {
                    cell.constraint.constant = (touchPosition.x - touchPoint.x) < 120 ? ((touchPosition.x - touchPoint.x) > 0 ? (touchPosition.x - touchPoint.x) : 0) : 120
                }
            }
            collectionView.visibleSupplementaryViews(ofKind: MessagingViewController.sectionHeaderElementKind).forEach {
                if let cell = $0 as? HeaderSessionChat {
                    cell.constraint.constant = (touchPosition.x - touchPoint.x) < 120 ? ((touchPosition.x - touchPoint.x) > 0 ? (touchPosition.x - touchPoint.x) : 0) : 120
                }
            }
        }
    }
}


// MARK: - Image picker
extension MessagingViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true, completion: nil)
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            pickedImage.image = image
            leadingAlignPickedImage.constant = 8
            pickedImageContainer.isHidden = false
            UIView.animate(withDuration: 0.1) { [self] in
                view.layoutIfNeeded()
            }
        }
    }
}


// MARK: - Configure collection view
extension MessagingViewController {
    // MARK: - Layout for collection view
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
                                              heightDimension: .estimated(50)),
            elementKind: MessagingViewController.sectionHeaderElementKind,
            alignment: .top)
        let sectionFooter = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .estimated(8)),
            elementKind: MessagingViewController.sectionFooterElementKind,
            alignment: .bottom)
        
        sectionHeader.pinToVisibleBounds = true
        sectionHeader.zIndex = 2
        section.boundarySupplementaryItems = [sectionHeader, sectionFooter]

        let layout = UICollectionViewCompositionalLayout(section: section, configuration: config)
        return layout
    }
    
    
    // MARK: - Config collection view
    func configureHierarchy() {
        collectionView.collectionViewLayout = createLayout()
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemGray6
        collectionView.delegate = self
        collectionView.addGestureRecognizer(panGesture)
        
        collectionView.register(UINib(nibName: MessContentCell.reuseIdentifier, bundle: nil), forCellWithReuseIdentifier: MessContentCell.reuseIdentifier)
        collectionView.register(UINib(nibName: FirstMessContentCellForSection.reuseIdentifier, bundle: nil), forCellWithReuseIdentifier: FirstMessContentCellForSection.reuseIdentifier)
        collectionView.register(UINib(nibName: HeaderSessionChat.reuseIdentifier, bundle: nil), forSupplementaryViewOfKind: MessagingViewController.sectionHeaderElementKind, withReuseIdentifier: HeaderSessionChat.reuseIdentifier)
        collectionView.register(UINib(nibName: FooterMessage.reuseIdentifier, bundle: nil), forSupplementaryViewOfKind: MessagingViewController.sectionFooterElementKind, withReuseIdentifier: FooterMessage.reuseIdentifier)
        collectionView.addGestureRecognizer(panGesture)
    }
    
    
    // MARK: - Config datasource
    /// - Tag: PinnedHeaderRegistration
    func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, ChatboxMessage>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, message: ChatboxMessage) -> UICollectionViewCell? in
            let row = indexPath.row
            if row == 0 {
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: FirstMessContentCellForSection.reuseIdentifier,
                    for: indexPath) as? FirstMessContentCellForSection else { fatalError("Cannot create new cell") }
                cell.prepare(message)
                cell.creationDate.text = message.createdAt.toDate().iso8601StringShortDateTime
                if let user = self.getUser(with: message.sender!) {
                    cell.senderName.text = user.name
                }
                if self.checkIsSender(message.sender!) {
                    cell.senderName.textColor = .systemGreen
                }
                
                return cell
            } else {
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: MessContentCell.reuseIdentifier,
                    for: indexPath) as? MessContentCell else { fatalError("Cannot create new cell") }
                cell.prepare(message)
                return cell
            }
        }
        
        dataSource.supplementaryViewProvider = { [self] (view, kind, index) in
            if kind == MessagingViewController.sectionHeaderElementKind {
                guard let supplementaryView = view.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HeaderSessionChat.reuseIdentifier, for: index) as? HeaderSessionChat else { fatalError("Cannot create HeaderSessionChat!") }
                let avatarFileId = getUser(with: messageViewModel[index.section][0].sender!)?.avatar
                supplementaryView.prepare(avatarFileId)
                return supplementaryView
            } else {
                guard let supplementaryView = view.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: FooterMessage.reuseIdentifier, for: index) as? FooterMessage else { fatalError("Cannot create FooterMessage!") }
                if (index.section == self.messageViewModel.count - 1) {
                    
                    supplementaryView.frame.size.height = 8
//                    supplementaryView.frame.size.height = 50 + 16
                }
                return supplementaryView
            }
        }
    }
    func applySnapshot() {
        var sections = Array(0..<0)
        if (messageViewModel.count > 0) {
            sections = Array(0..<messageViewModel.count)
        }
        var snapshot = NSDiffableDataSourceSnapshot<Int, ChatboxMessage>()
        sections.forEach {
//            avatarFileIds.append(getUser(with: messageViewModel[$0][0].sender!)!.avatar)
            snapshot.appendSections([$0])
            snapshot.appendItems(messageViewModel[$0])
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.dataSource.apply(snapshot, animatingDifferences: true)
            self.collectionView.layoutIfNeeded()
        }
    }
    
    
    // MARK: - Tasks.
    func scrollToBottom(of collectionView: UICollectionView) {
        // method 1
        if messageViewModel.count > 0 && messageViewModel.last!.count > 0 {
            collectionView.scrollToItem(at: IndexPath(item: messageViewModel.last!.count - 1, section: messageViewModel.count - 1), at: .bottom, animated: true)
            self.view.layoutIfNeeded()
        }
        
        // method 2
//        print(collectionView.contentSize.height)
//        print(collectionView.contentInset.bottom)
//        print(collectionView.frame.height)
//        let point = CGPoint(x: 0, y: collectionView.contentSize.height - collectionView.bounds.height)
//        if point.y >= 0 {
//            collectionView.setContentOffset(point, animated: true)
//        }
    }
    func scrollToTop(of collectionView: UICollectionView) {
        // method 1
        if messageViewModel.count > 0 && messageViewModel.last!.count > 0 {
            collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
            self.view.layoutIfNeeded()
        }
        
        // method 2
//        print(collectionView.contentSize.height)
//        print(collectionView.contentInset.bottom)
//        print(collectionView.frame.height)
//        let point = CGPoint(x: 0, y: collectionView.contentSize.height - collectionView.bounds.height)
//        if point.y >= 0 {
//            collectionView.setContentOffset(point, animated: true)
//        }
    }
}
extension MessagingViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        collectionView.deselectItem(at: indexPath, animated: true)
    }
}


// MARK: - Keyboard.
extension MessagingViewController {
    @objc func keyboardWillShow(_ notification: NSNotification) {
        if let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            UIView.animate(withDuration: 0.1) { [self] in
                widthTextField.constant = 240
                heightInputContainer.constant = 50
                keyboardHeight = keyboardRect.height
                bottomSpaceCollectionView.constant = keyboardHeight
                self.view.layoutIfNeeded()
//                scrollToBottom(of: collectionView)
            }
        }
    }
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            UIView.animate(withDuration: 0.1) { [self] in
                widthTextField.constant = 160
                heightInputContainer.constant = heightInputContainerOnDeviceType
                keyboardHeight = keyboardRect.height
                bottomSpaceCollectionView.constant = 0
                self.view.layoutIfNeeded()
            }
        }
    }
}
