import Foundation

/*
 //
 //  ChatViewController.swift
 //  Social Messaging
 //
 //  Created by Vũ Quý Đạt  on 21/04/2021.
 //

 import UIKit

 class MessagingViewController: UIViewController {
     
     
     // MARK: - Properties
     // Collection view config data.
     static let sectionHeaderElementKind = "section-header-element-kind"
     static let sectionFooterElementKind = "section-footer-element-kind"
     
     let notificationCenter = NotificationCenter.default
     var dataSource: UICollectionViewDiffableDataSource<Int, Message>! = nil
     let imagePicker = UIImagePickerController()
     var user: User!
     var extractedChatBox: ChatBoxExtractedData!
     var messages = [[Message]]()
     var members = [User]()
     
     var keyboardHeight: CGFloat = 0.0
     var touchPosition: CGPoint = CGPoint(x: 0, y: 0)
     
     
     // MARK: - IBOutlet
     // Views
     @IBOutlet weak var collectionView: UICollectionView!
     @IBOutlet weak var inputFieldViewContainer: UIVisualEffectView!
     
     @IBOutlet weak var pickedImageContainer: UIView!
     @IBOutlet weak var chatTextField: UITextField!
     @IBOutlet weak var pickedImage: UIImageView!
     @IBOutlet weak var removeSendingImageButton: UIButton!
     
     // Constraints
     @IBOutlet weak var bottomSpaceCollectionView: NSLayoutConstraint!
     @IBOutlet weak var leadingAlignPickedImage: NSLayoutConstraint!
     @IBOutlet weak var widthTextField: NSLayoutConstraint!
     
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
     
     
     // MARK: - Life cycles
     override func viewDidLoad() {
         super.viewDidLoad()
         
         // Do any additional setup after loading the view.
         setUpNavigationBar()
         prepareView()
         
         // Configure collection view
         configureHierarchy()
         configureDataSource()
         
         // Preapre data
         fetch()
         
         // Observer
         notificationCenter.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
         notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
         notificationCenter.addObserver(self, selector: #selector(websocketReceivedPackage(_:)), name: .WebsocketReceivedPackage, object: nil)

         
         // Delegate
         imagePicker.delegate = self
     }
     override func viewWillAppear(_ animated: Bool) {
         super.viewWillAppear(animated)
         
         tabBarController?.tabBar.isHidden = true
     }
     override func viewDidDisappear(_ animated: Bool) {
         super.viewDidDisappear(animated)
     }
     deinit {
         notificationCenter.removeObserver(self, name: .WebsocketReceivedPackage, object: nil)
     }
     
     
     // MARK: - Set up methods
     func setUpNavigationBar() {
         navigationItem.largeTitleDisplayMode = .never
         title = extractedChatBox.chatBox.name
 //        navigationItem.largeTitleDisplayMode = .never
 //        self.title = extractedChatBox.chatBox.name
 //        navigationController?.navigationBar.prefersLargeTitles = false
 //        self.navigationController?.modalPresentationStyle = .fullScreen
         
         /// Call video BarButtonItem.
         let rightBarItem: UIBarButtonItem = {
             let bt = UIBarButtonItem(image: UIImage(systemName: "video.circle.fill"), style: .plain, target: self, action: #selector(rightBarItemAction))
             return bt
         }()
         navigationItem.rightBarButtonItem = rightBarItem
     }
     @objc func rightBarItemAction() {
         FeedBackTapEngine.tapped(style: .medium)
     }
     
     
     // MARK: - Tasks
     func fetch() {
         let queue = DispatchQueue(label: "fetch")
         queue.async { [self] in
             user = AuthenticatedUser.retrieve()?.data
             extractedChatBox = extractedChatBox
             let chatBox = extractedChatBox.chatBox
             members = extractedChatBox.members.retrieveUsers()
             var storedMessaged = Messages.retrieve(with: chatBox.id).messages
             messages = storedMessaged.transformStructure()
         }
         DispatchQueue.main.async { [self] in
             markLastestSeenMessage()
             setUpDataSource()
             scrollToBottom(of: collectionView)
         }
     }
     func hidePickedImageContainer() {
         leadingAlignPickedImage.constant = -160
         UIView.animate(withDuration: 0.3,
                        animations: { [self] in
             view.layoutIfNeeded()
         }, completion: { [self] isCompleted in
             if isCompleted {
                 pickedImage.image = nil
             }
         })
     }
     func prepareView() {
         view.clipsToBounds = true
         view.backgroundColor = .systemBackground
         leadingAlignPickedImage.constant = -160
         pickedImage.contentMode = .scaleAspectFit
         pickedImageContainer.border(4)
         pickedImageContainer.dropShadow()
     }
     @objc func websocketReceivedPackage(_ notification: Notification) {
 //        guard let package = notification.userInfo?["package"] as? WebSocketPackage
 //        else {
 //            return
 //        }
 //        if (navigationController?.topViewController != self ||
 //            package.message.chatboxId != extractedChatBox.chatBox.id) {
 //            return
 //        }
 //        messages.receive([package.convertToMessage()])
 //        updateDataSource()
         
         if navigationController?.topViewController == self {
             let chatboxId = extractedChatBox.chatBox.id
             var storedMessaged = Messages.retrieve(with: chatboxId).messages
             self.messages = storedMessaged.transformStructure()
             markLastestSeenMessage()
             setUpDataSource()
             
             scrollToBottom(of: collectionView)
         }
     }
     
     
     // MARK: - Mini tasks
     func markLastestSeenMessage() {
         if navigationController?.topViewController == self {
             messages.last?.last?.store(.lastestSeenMessage)
         }
     }
     func user(_ id: UUID) -> User? {
         members.first {
             $0.mappingId == id
         }
     }
     
     
     // MARK: - IBAction
     @IBAction func sendMessage(_ sender: UIButton) {
         FeedBackTapEngine.tapped(style: .medium)
         let webSocketPackage = WebSocketPackage(type: .message, message: WebSocketPackageMessage(sender: user.mappingId, chatboxId: extractedChatBox.chatBox.id, mediaType: .text, content: chatTextField.text))
         NotificationCenter.default.post(name: .WebsocketSendPackage, object: nil, userInfo: ["package": webSocketPackage])
     }
     @IBAction func pickImage(_ sender: UIButton) {
         FeedBackTapEngine.tapped(style: .medium)
         imagePicker.allowsEditing = true
         imagePicker.sourceType = .photoLibrary
         self.present(imagePicker, animated: true, completion: nil)
     }
     @IBAction func removeSendingImageAction(_ sender: UIButton) {
         FeedBackTapEngine.tapped(style: .medium)
         hidePickedImageContainer()
     }
 }

     
 // MARK: - Pan esture.
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
                                               heightDimension: .estimated(45)),
             elementKind: MessagingViewController.sectionHeaderElementKind,
             alignment: .top)
         let sectionFooter = NSCollectionLayoutBoundarySupplementaryItem(
             layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(66)),
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
         dataSource = UICollectionViewDiffableDataSource<Int, Message>(collectionView: collectionView) {
             (collectionView: UICollectionView, indexPath: IndexPath, message: Message) -> UICollectionViewCell? in
             if indexPath.row == 0 {
                 guard let cell = collectionView.dequeueReusableCell(
                     withReuseIdentifier: FirstMessContentCellForSection.reuseIdentifier,
                     for: indexPath) as? FirstMessContentCellForSection else { fatalError("Cannot create new cell") }
                 cell.prepare(message)
                 cell.delegate = self
                 return cell
             } else {
                 guard let cell = collectionView.dequeueReusableCell(
                     withReuseIdentifier: MessContentCell.reuseIdentifier,
                     for: indexPath) as? MessContentCell else { fatalError("Cannot create new cell") }
                 cell.prepare(message)
                 return cell
             }
         }
         
         dataSource.supplementaryViewProvider = { (view, kind, index) in
             if kind == MessagingViewController.sectionHeaderElementKind {
                 guard let supplementaryView = view.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HeaderSessionChat.reuseIdentifier, for: index) as? HeaderSessionChat else { fatalError("Cannot create HeaderSessionChat!") }
                 return supplementaryView
             } else {
                 guard let supplementaryView = view.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: FooterMessage.reuseIdentifier, for: index) as? FooterMessage else { fatalError("Cannot create FooterMessage!") }
                 if (index.section == self.messages.count - 1) {
 //                    supplementaryView.frame.size.height = self.containChattingView.frame.size.height + 16
                     supplementaryView.frame.size.height = 50 + 16
                 } else {
                     supplementaryView.frame.size.height = 0
                 }
                 return supplementaryView
             }
         }
     }
     func setUpDataSource() {
         var sections = Array(0..<0)
         if (messages.count > 0) {
             sections = Array(0..<messages.count)
         }
         var snapshot = NSDiffableDataSourceSnapshot<Int, Message>()
         sections.forEach {
             snapshot.appendSections([$0])
             snapshot.appendItems(messages[$0])
         }
         dataSource.apply(snapshot, animatingDifferences: true)
     }
     func updateDataSource() {
         var sections = Array(0..<0)
         if (messages.count > 0) {
             sections = Array(0..<messages.count)
         }
         var snapshot = NSDiffableDataSourceSnapshot<Int, Message>()
         sections.forEach {
             snapshot.appendSections([$0])
             snapshot.appendItems(messages[$0])
         }
         dataSource.apply(snapshot, animatingDifferences: true)
     }
     
     
     // MARK: - Tasks.
     func scrollToBottom(of collectionView: UICollectionView) {
         // method 1
         if messages.count > 0 && messages.last!.count > 0 {
             collectionView.scrollToItem(at: IndexPath(item: messages.last!.count - 1, section: messages.count - 1), at: .bottom, animated: true)
             self.view.layoutIfNeeded()
         }
             
         // method 2
 //        let point = CGPoint(x: 0, y: collectionView.contentSize.height + collectionView.contentInset.bottom - collectionView.frame.height)
 //        if point.y >= 0 {
 //            collectionView.setContentOffset(point, animated: true)
 //        }
     }
 }


 // MARK: - Collection view delegate
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
                 keyboardHeight = keyboardRect.height
                 bottomSpaceCollectionView.constant = keyboardHeight
                 self.view.layoutIfNeeded()
                 scrollToBottom(of: collectionView)
             }
         }
     }
     @objc func keyboardWillHide(notification: NSNotification) {
         if let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
             UIView.animate(withDuration: 0.1) { [self] in
                 widthTextField.constant = 160
                 keyboardHeight = keyboardRect.height
                 bottomSpaceCollectionView.constant = 0
                 self.view.layoutIfNeeded()
             }
         }
     }
 }

 */



















/*
 //
 //  ChatViewController.swift
 //  Social Messaging
 //
 //  Created by Vũ Quý Đạt  on 21/04/2021.
 //

 import UIKit

 class MessagingViewController: UIViewController {
     
     
     // MARK: - Properties
     // Collection view config data.
     static let sectionHeaderElementKind = "section-header-element-kind"
     static let sectionFooterElementKind = "section-footer-element-kind"
     
     let notificationCenter = NotificationCenter.default
     var dataSource: UICollectionViewDiffableDataSource<Int, Message>! = nil
     let imagePicker = UIImagePickerController()
     var user: User!
     var extractedChatBox: ChatBoxExtractedData!
     var messages = [[Message]]()
     var members = [User]()
     
     var keyboardHeight: CGFloat = 0.0
     var touchPosition: CGPoint = CGPoint(x: 0, y: 0)
     
     
     // MARK: - IBOutlet
     // Views
     @IBOutlet weak var collectionView: UICollectionView!
     @IBOutlet weak var inputFieldViewContainer: UIVisualEffectView!
     
     @IBOutlet weak var pickedImageContainer: UIView!
     @IBOutlet weak var chatTextField: UITextField!
     @IBOutlet weak var pickedImage: UIImageView!
     @IBOutlet weak var removeSendingImageButton: UIButton!
     
     // Constraints
     @IBOutlet weak var bottomSpaceCollectionView: NSLayoutConstraint!
     @IBOutlet weak var leadingAlignPickedImage: NSLayoutConstraint!
     @IBOutlet weak var widthTextField: NSLayoutConstraint!
     
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
     
     
     // MARK: - Life cycles
     override func viewDidLoad() {
         super.viewDidLoad()
         
         // Do any additional setup after loading the view.
         setUpNavigationBar()
         prepareView()
         
         // Configure collection view
         configureHierarchy()
         configureDataSource()
         
         // Preapre data
         fetch()
         
         // Observer
         notificationCenter.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
         notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
         notificationCenter.addObserver(self, selector: #selector(websocketReceivedPackage(_:)), name: .WebsocketReceivedPackage, object: nil)

         
         // Delegate
         imagePicker.delegate = self
     }
     override func viewWillAppear(_ animated: Bool) {
         super.viewWillAppear(animated)
         
         tabBarController?.tabBar.isHidden = true
     }
     override func viewDidDisappear(_ animated: Bool) {
         super.viewDidDisappear(animated)
     }
     deinit {
         notificationCenter.removeObserver(self, name: .WebsocketReceivedPackage, object: nil)
     }
     
     
     // MARK: - Set up methods
     func setUpNavigationBar() {
         navigationItem.largeTitleDisplayMode = .never
         title = extractedChatBox.chatBox.name
 //        navigationItem.largeTitleDisplayMode = .never
 //        self.title = extractedChatBox.chatBox.name
 //        navigationController?.navigationBar.prefersLargeTitles = false
 //        self.navigationController?.modalPresentationStyle = .fullScreen
         
         /// Call video BarButtonItem.
         let rightBarItem: UIBarButtonItem = {
             let bt = UIBarButtonItem(image: UIImage(systemName: "video.circle.fill"), style: .plain, target: self, action: #selector(rightBarItemAction))
             return bt
         }()
         navigationItem.rightBarButtonItem = rightBarItem
     }
     @objc func rightBarItemAction() {
         FeedBackTapEngine.tapped(style: .medium)
     }
     
     
     // MARK: - Tasks
     func fetch() {
         let queue = DispatchQueue(label: "fetch")
         queue.async { [self] in
             user = AuthenticatedUser.retrieve()?.data
             extractedChatBox = extractedChatBox
             let chatBox = extractedChatBox.chatBox
             members = extractedChatBox.members.retrieveUsers()
             var storedMessaged = Messages.retrieve(with: chatBox.id).messages
             messages = storedMessaged.transformStructure()
         }
         DispatchQueue.main.async { [self] in
             markLastestSeenMessage()
             setUpDataSource()
             scrollToBottom(of: collectionView)
         }
     }
     func hidePickedImageContainer() {
         leadingAlignPickedImage.constant = -160
         UIView.animate(withDuration: 0.3,
                        animations: { [self] in
             view.layoutIfNeeded()
         }, completion: { [self] isCompleted in
             if isCompleted {
                 pickedImage.image = nil
             }
         })
     }
     func prepareView() {
         view.clipsToBounds = true
         view.backgroundColor = .systemBackground
         leadingAlignPickedImage.constant = -160
         pickedImage.contentMode = .scaleAspectFit
         pickedImageContainer.border(4)
         pickedImageContainer.dropShadow()
     }
     @objc func websocketReceivedPackage(_ notification: Notification) {
 //        guard let package = notification.userInfo?["package"] as? WebSocketPackage
 //        else {
 //            return
 //        }
 //        if (navigationController?.topViewController != self ||
 //            package.message.chatboxId != extractedChatBox.chatBox.id) {
 //            return
 //        }
 //        messages.receive([package.convertToMessage()])
 //        updateDataSource()
         
         if navigationController?.topViewController == self {
             let chatboxId = extractedChatBox.chatBox.id
             var storedMessaged = Messages.retrieve(with: chatboxId).messages
             self.messages = storedMessaged.transformStructure()
             markLastestSeenMessage()
             setUpDataSource()
             
             scrollToBottom(of: collectionView)
         }
     }
     
     
     // MARK: - Mini tasks
     func markLastestSeenMessage() {
         if navigationController?.topViewController == self {
             messages.last?.last?.store(.lastestSeenMessage)
         }
     }
     func user(_ id: UUID) -> User? {
         members.first {
             $0.mappingId == id
         }
     }
     
     
     // MARK: - IBAction
     @IBAction func sendMessage(_ sender: UIButton) {
         FeedBackTapEngine.tapped(style: .medium)
         let webSocketPackage = WebSocketPackage(type: .message, message: WebSocketPackageMessage(sender: user.mappingId, chatboxId: extractedChatBox.chatBox.id, mediaType: .text, content: chatTextField.text))
         NotificationCenter.default.post(name: .WebsocketSendPackage, object: nil, userInfo: ["package": webSocketPackage])
     }
     @IBAction func pickImage(_ sender: UIButton) {
         FeedBackTapEngine.tapped(style: .medium)
         imagePicker.allowsEditing = true
         imagePicker.sourceType = .photoLibrary
         self.present(imagePicker, animated: true, completion: nil)
     }
     @IBAction func removeSendingImageAction(_ sender: UIButton) {
         FeedBackTapEngine.tapped(style: .medium)
         hidePickedImageContainer()
     }
 }

     
 // MARK: - Pan esture.
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
                                               heightDimension: .estimated(45)),
             elementKind: MessagingViewController.sectionHeaderElementKind,
             alignment: .top)
         let sectionFooter = NSCollectionLayoutBoundarySupplementaryItem(
             layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(66)),
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
         dataSource = UICollectionViewDiffableDataSource<Int, Message>(collectionView: collectionView) {
             (collectionView: UICollectionView, indexPath: IndexPath, message: Message) -> UICollectionViewCell? in
             if indexPath.row == 0 {
                 guard let cell = collectionView.dequeueReusableCell(
                     withReuseIdentifier: FirstMessContentCellForSection.reuseIdentifier,
                     for: indexPath) as? FirstMessContentCellForSection else { fatalError("Cannot create new cell") }
                 cell.prepare(message)
                 cell.delegate = self
                 return cell
             } else {
                 guard let cell = collectionView.dequeueReusableCell(
                     withReuseIdentifier: MessContentCell.reuseIdentifier,
                     for: indexPath) as? MessContentCell else { fatalError("Cannot create new cell") }
                 cell.prepare(message)
                 return cell
             }
         }
         
         dataSource.supplementaryViewProvider = { (view, kind, index) in
             if kind == MessagingViewController.sectionHeaderElementKind {
                 guard let supplementaryView = view.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HeaderSessionChat.reuseIdentifier, for: index) as? HeaderSessionChat else { fatalError("Cannot create HeaderSessionChat!") }
                 return supplementaryView
             } else {
                 guard let supplementaryView = view.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: FooterMessage.reuseIdentifier, for: index) as? FooterMessage else { fatalError("Cannot create FooterMessage!") }
                 if (index.section == self.messages.count - 1) {
 //                    supplementaryView.frame.size.height = self.containChattingView.frame.size.height + 16
                     supplementaryView.frame.size.height = 50 + 16
                 } else {
                     supplementaryView.frame.size.height = 0
                 }
                 return supplementaryView
             }
         }
     }
     func setUpDataSource() {
         var sections = Array(0..<0)
         if (messages.count > 0) {
             sections = Array(0..<messages.count)
         }
         var snapshot = NSDiffableDataSourceSnapshot<Int, Message>()
         sections.forEach {
             snapshot.appendSections([$0])
             snapshot.appendItems(messages[$0])
         }
         dataSource.apply(snapshot, animatingDifferences: true)
     }
     func updateDataSource() {
         var sections = Array(0..<0)
         if (messages.count > 0) {
             sections = Array(0..<messages.count)
         }
         var snapshot = NSDiffableDataSourceSnapshot<Int, Message>()
         sections.forEach {
             snapshot.appendSections([$0])
             snapshot.appendItems(messages[$0])
         }
         dataSource.apply(snapshot, animatingDifferences: true)
     }
     
     
     // MARK: - Tasks.
     func scrollToBottom(of collectionView: UICollectionView) {
         // method 1
         if messages.count > 0 && messages.last!.count > 0 {
             collectionView.scrollToItem(at: IndexPath(item: messages.last!.count - 1, section: messages.count - 1), at: .bottom, animated: true)
             self.view.layoutIfNeeded()
         }
             
         // method 2
 //        let point = CGPoint(x: 0, y: collectionView.contentSize.height + collectionView.contentInset.bottom - collectionView.frame.height)
 //        if point.y >= 0 {
 //            collectionView.setContentOffset(point, animated: true)
 //        }
     }
 }


 // MARK: - Collection view delegate
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
                 keyboardHeight = keyboardRect.height
                 bottomSpaceCollectionView.constant = keyboardHeight
                 self.view.layoutIfNeeded()
                 scrollToBottom(of: collectionView)
             }
         }
     }
     @objc func keyboardWillHide(notification: NSNotification) {
         if let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
             UIView.animate(withDuration: 0.1) { [self] in
                 widthTextField.constant = 160
                 keyboardHeight = keyboardRect.height
                 bottomSpaceCollectionView.constant = 0
                 self.view.layoutIfNeeded()
             }
         }
     }
 }

 */














// Sample data of MessagingViewController.swift
func sampleData(mappingId: UUID) -> [ChatboxMessage] {
    let contentSample = """
    This view hierarchy is useful for learning how HomeKit structures device data, which is slightly different than the way the Apple Home app refers to related concepts. It’s also useful for device developers who want to understand how HomeKit sees custom hardware.

    In a real app that you publish on the App Store, you would provide a user experience more like the one found in Configuring a Home Automation Device. For example, you would focus on the actions a user can take and hide the underlying technical details. For more tips about presenting HomeKit data to users, see the “Adjust the Interface for a Published App” section at the end of this article.
    """
    var sampleData = [
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "Hello essage from debugger: failed to send the k packet"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "Hello i'm datvu"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: contentSample),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "Load message cell"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "Did work successfull!"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: contentSample),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: contentSample),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: contentSample),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "Did work successfull!"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "Did work successfull!"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "Did work successfull!"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "Did work successfull!"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "Did work successfull!"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "Did work successfull!"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "Did work successfull!"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "Did work successfull!"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "Did work successfull!"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "Did work successfull!"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "Did work successfull!"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "Did work successfull!"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "Did work successfull!"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "Did work successfull!"),
        ChatboxMessage(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatboxId: UUID(), mediaType: .text, content: "Did work successfull!")
    ]
    return sampleData
}





















////
////  ChatViewController.swift
////  Social Messaging
////
////  Created by Vũ Quý Đạt  on 21/04/2021.
////
//
//import UIKit
//
//class MessagingViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
//    
//    // MARK: - Properties
//    // Collection view config data.
//    static let sectionHeaderElementKind = "section-header-element-kind"
//    static let sectionFooterElementKind = "section-footer-element-kind"
//
//    var dataSource: UICollectionViewDiffableDataSource<Int, Message>! = nil
//    let imagePicker = UIImagePickerController()
//    var user: User!
//    var extractedChatBox: ChatBoxExtractedData!
//    var messages = [[Message]]()
//    var members = [User]()
//    
//    var keyboardHeight: CGFloat = 0.0
//    var touchPosition: CGPoint = CGPoint(x: 0, y: 0)
//    
//    
//    // MARK: - IBOutlet.
//    // Views.
//    @IBOutlet weak var containChattingView: UIVisualEffectView!
//    @IBOutlet weak var sendingImageViewContainer: UIView!
//    
//    @IBOutlet weak var chatView: UICollectionView!
//    @IBOutlet weak var chatTextField: UITextField!
//    @IBOutlet weak var sendingImage: UIImageView!
//    @IBOutlet weak var removeSendingImageButton: UIButton!
//    // Constraints.
//    @IBOutlet weak var bottomAlignCollectionViewCS: NSLayoutConstraint!
//    @IBOutlet weak var leadingOfTextFieldCS: NSLayoutConstraint!
//    
//    
//    // MARK: - Gesture.
//    private lazy var panGesture: UIPanGestureRecognizer = {
//        let gesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureOnTable(_:)))
//        gesture.delegate = self
//        gesture.cancelsTouchesInView = true
//        return gesture
//    }()
//    
//    
//    // MARK: - Set up methods.
//    func setUpNavigationBar() {
//        self.title = extractedChatBox.chatBox.name
//        self.navigationController?.navigationBar.isHidden = true
////      self.navigationController?.navigationBar.prefersLargeTitles = false
//        self.navigationController?.modalPresentationStyle = .fullScreen
//        
//        /// Call video BarButtonItem.
//        let rightBarItem: UIBarButtonItem = {
//            let bt = UIBarButtonItem(image: UIImage(systemName: "video.circle.fill"), style: .plain, target: self, action: #selector(rightBarItemAction))
//            return bt
//        }()
//        navigationItem.rightBarButtonItem = rightBarItem
//    }
//    @objc func rightBarItemAction() {
//    }
//
//    
//    // MARK: - Life cycle.
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        // Do any additional setup after loading the view.
//        setUpNavigationBar()
//        configureHierarchy()
//        
//        let notificationCenter = NotificationCenter.default
//        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
//        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
//        
//        imagePicker.delegate = self
//        view.sendSubviewToBack(sendingImage)
//        
//        configureDataSource()
//        fetch()
//    }
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        self.tabBarController?.tabBar.isHidden = true
//    }
//    override func viewDidDisappear(_ animated: Bool) {
//        super.viewDidDisappear(animated)
//    }
//    
//    
//    // MARK: - Tasks
//    func hideSendingImageViewContainer() {
//        sendingImage.image = nil
//        self.view.sendSubviewToBack(sendingImageViewContainer)
//    }
//    
//    
//    // MARK: - Mini tasks
//    func fetch() {
//        DispatchQueue.main.async { [self] in
//            self.user = AuthenticatedUser.retrieve()?.data
//            self.extractedChatBox = extractedChatBox
//            let chatBox = extractedChatBox.chatBox
//            //        self.messages = Messages.retrieve(with: chatBox.id).messages
//            self.members = extractedChatBox.members.retrieveUsers()
//            let contentSample = """
//        This view hierarchy is useful for learning how HomeKit structures device data, which is slightly different than the way the Apple Home app refers to related concepts. It’s also useful for device developers who want to understand how HomeKit sees custom hardware.
//        
//        In a real app that you publish on the App Store, you would provide a user experience more like the one found in Configuring a Home Automation Device. For example, you would focus on the actions a user can take and hide the underlying technical details. For more tips about presenting HomeKit data to users, see the “Adjust the Interface for a Published App” section at the end of this article.
//"""
//            var sampleData = [
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "Hello essage from debugger: failed to send the k packet"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "Hello i'm datvu"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: contentSample),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "Load message cell"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "Did work successfull!"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: contentSample),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: contentSample),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: contentSample),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "Did work successfull!"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "Did work successfull!"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "Did work successfull!"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "Did work successfull!"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "Did work successfull!"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "Did work successfull!"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "Did work successfull!"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "Did work successfull!"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "Did work successfull!"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "Did work successfull!"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "Did work successfull!"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "Did work successfull!"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "Did work successfull!"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "adjustedContentInset: {64, 0, 0, 0}; layout:"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "Did work successfull!"),
//                Message(id: UUID(), createdAt: Date().dayTime, sender: mappingId, chatBoxId: UUID(), mediaType: .text, content: "Did work successfull!")
//            ]
//            self.messages = sampleData.transformStructure()
//            setUpDataSource()
//        }
//    }
//    
//    
//    // MARK: - IBAction
//    @IBAction func sendMessage(_ sender: UIButton) {
//
//    }
//    @IBAction func pickImage(_ sender: UIButton) {
//        FeedBackTapEngine.tapped(style: .medium)
//        imagePicker.allowsEditing = true
//        imagePicker.sourceType = .photoLibrary
//        self.present(imagePicker, animated: true, completion: nil)
//    }
//    @IBAction func removeSendingImageAction(_ sender: UIButton) {
//        FeedBackTapEngine.tapped(style: .medium)
//        hideSendingImageViewContainer()
//    }
//    
//    
//    // MARK: - Delegate methods.
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
//            sendingImage.contentMode = .scaleAspectFit
//            sendingImage.image = pickedImage
//            self.view.bringSubviewToFront(sendingImageViewContainer)
//        }
//
//        dismiss(animated: true, completion: nil)
//    }
//    
//
//    // MARK: - Gesture.
//    /// Pan Gesture on collection chat view. Using for swipe showing time stamp.
//    @objc func panGestureOnTable(_ sender: UIPanGestureRecognizer) {
//        let touchPoint = sender.location(in: chatView)
//        if sender.state == .ended {
//            chatView.visibleCells.forEach {
//                if let cell = $0 as? FirstMessContentCellForSection {
//                    UIView.animate(withDuration: 0.3, delay: 0.03,
//                                   options: [.curveEaseOut],
//                                   animations: { [weak self] in
//                                    cell.constraint.constant = 0
//                                    self?.view.layoutIfNeeded()
//                                   }, completion: nil)
//                }
//                if let cell = $0 as? MessContentCell {
//                    UIView.animate(withDuration: 0.3, delay: 0.03,
//                                   options: [.curveEaseOut],
//                                   animations: { [weak self] in
//                                    cell.constraint.constant = 0
//                                    self?.view.layoutIfNeeded()
//                                   }, completion: nil)
//                }
//            }
//            chatView.visibleSupplementaryViews(ofKind: MessagingViewController.sectionHeaderElementKind).forEach {
//                if let cell = $0 as? HeaderSessionChat {
//                    UIView.animate(withDuration: 0.3, delay: 0.03,
//                                   options: [.curveEaseOut],
//                                   animations: { [weak self] in
//                                    cell.constraint.constant = 0
//                                    self?.view.layoutIfNeeded()
//                                   }, completion: nil)
//                }
//            }
//        } else if sender.state == .began {
//            touchPosition = touchPoint
//        } else if sender.state == .changed {
//            chatView.visibleCells.forEach {
//                if let cell = $0 as? FirstMessContentCellForSection {
//                    cell.constraint.constant = (touchPosition.x - touchPoint.x) < 75 ? ((touchPosition.x - touchPoint.x) > 0 ? (touchPosition.x - touchPoint.x) : 0) : 75
//                }
//                if let cell = $0 as? MessContentCell {
//                    cell.constraint.constant = (touchPosition.x - touchPoint.x) < 75 ? ((touchPosition.x - touchPoint.x) > 0 ? (touchPosition.x - touchPoint.x) : 0) : 75
//                }
//            }
//            chatView.visibleSupplementaryViews(ofKind: MessagingViewController.sectionHeaderElementKind).forEach {
//                if let cell = $0 as? HeaderSessionChat {
//                    cell.constraint.constant = (touchPosition.x - touchPoint.x) < 75 ? ((touchPosition.x - touchPoint.x) > 0 ? (touchPosition.x - touchPoint.x) : 0) : 75
//                }
//            }
//        }
//    }
//}
//
//
//// MARK: - Extensions.
//extension MessagingViewController {
//    // MARK: - Layout for collection view.
//    /// - Tag: PinnedHeader
//    func createLayout() -> UICollectionViewLayout {
//        
//        let config = UICollectionViewCompositionalLayoutConfiguration()
//        config.interSectionSpacing = 1
//        
//        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44))
//        let item = NSCollectionLayoutItem(layoutSize: itemSize)
//        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44))
//        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
//        let section = NSCollectionLayoutSection(group: group)
//        section.interGroupSpacing = 5
//        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
//
//        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
//            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
//                                              heightDimension: .estimated(45)),
//            elementKind: MessagingViewController.sectionHeaderElementKind,
//            alignment: .top)
//        let sectionFooter = NSCollectionLayoutBoundarySupplementaryItem(
//            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
//                                              heightDimension: .estimated(30)),
//            elementKind: MessagingViewController.sectionFooterElementKind,
//            alignment: .bottom)
//        sectionHeader.pinToVisibleBounds = true
//        sectionHeader.zIndex = 2
//        section.boundarySupplementaryItems = [sectionHeader, sectionFooter]
//
//        let layout = UICollectionViewCompositionalLayout(section: section, configuration: config)
//        return layout
//    }
//    
//    
//    // MARK: - Config collection view.
//    func configureHierarchy() {
//        chatView.collectionViewLayout = createLayout()
//        chatView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        chatView.backgroundColor = .systemGray6
//        chatView.delegate = self
//        
//        chatView.register(UINib(nibName: MessContentCell.reuseIdentifier, bundle: nil), forCellWithReuseIdentifier: MessContentCell.reuseIdentifier)
//        chatView.register(UINib(nibName: FirstMessContentCellForSection.reuseIdentifier, bundle: nil), forCellWithReuseIdentifier: FirstMessContentCellForSection.reuseIdentifier)
//        chatView.register(UINib(nibName: HeaderSessionChat.reuseIdentifier, bundle: nil), forSupplementaryViewOfKind: MessagingViewController.sectionHeaderElementKind, withReuseIdentifier: HeaderSessionChat.reuseIdentifier)
//        chatView.register(UINib(nibName: FooterMessage.reuseIdentifier, bundle: nil), forSupplementaryViewOfKind: MessagingViewController.sectionFooterElementKind, withReuseIdentifier: FooterMessage.reuseIdentifier)
//    }
//    
//    
//    // MARK: - Config datasource.
//    /// - Tag: PinnedHeaderRegistration
//    func configureDataSource() {
//        dataSource = UICollectionViewDiffableDataSource<Int, Message>(collectionView: chatView) {
//            (collectionView: UICollectionView, indexPath: IndexPath, message: Message) -> UICollectionViewCell? in
//            if indexPath.row == 0 {
//                guard let cell = collectionView.dequeueReusableCell(
//                    withReuseIdentifier: FirstMessContentCellForSection.reuseIdentifier,
//                    for: indexPath) as? FirstMessContentCellForSection else { fatalError("Cannot create new cell") }
//                
//                
//                cell.creationDate.text = message.createdAt.toDate().iso8601StringShortDateTime
//                cell.timeLabel.text = ""
//                cell.contentTextLabel.text = message.content
//                return cell
//            } else {
//                guard let cell = collectionView.dequeueReusableCell(
//                    withReuseIdentifier: MessContentCell.reuseIdentifier,
//                    for: indexPath) as? MessContentCell else { fatalError("Cannot create new cell") }
//                cell.timeLabel.text = ""
//                cell.contentTextLabel.text = message.content
//                return cell
//            }
//        }
//        
//        dataSource.supplementaryViewProvider = { (view, kind, index) in
//            if kind == MessagingViewController.sectionHeaderElementKind {
//                guard let supplementaryView = view.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HeaderSessionChat.reuseIdentifier, for: index) as? HeaderSessionChat else { fatalError("Cannot create HeaderSessionChat!") }
//                return supplementaryView
//            } else {
//                guard let supplementaryView = view.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: FooterMessage.reuseIdentifier, for: index) as? FooterMessage else { fatalError("Cannot create FooterMessage!") }
//                if (index.section == self.messages.count - 1) {
//                    supplementaryView.frame.size.height = self.containChattingView.frame.size.height + 16
//                } else {
//                    supplementaryView.frame.size.height = 0
//                }
//                return supplementaryView
//            }
//        }
//        setUpDataSource()
//    }
//    func setUpDataSource() {
//        var sections = Array(0..<0)
//        if (messages.count > 0) {
//            sections = Array(0..<messages.count)
//        }
//        var snapshot = NSDiffableDataSourceSnapshot<Int, Message>()
//        sections.forEach {
//            snapshot.appendSections([$0])
//            snapshot.appendItems(messages[$0])
//        }
//        dataSource.apply(snapshot, animatingDifferences: true)
//        scrollToBottom(of: chatView)
//    }
//    
//    
//    // MARK: - Tasks.
//    func scrollToBottom(of collectionView: UICollectionView) {
//        DispatchQueue.main.async { [self] in
////            if messages.count > 0 && messages.last!.count > 0 {
////                chatView.scrollToItem(at: IndexPath(item: messages.last!.count - 1, section: messages.count - 1), at: .bottom, animated: true)
////                self.view.layoutIfNeeded()
////            }
//            
//            let point = CGPoint(x: 0, y: chatView.contentSize.height + chatView.contentInset.bottom - chatView.frame.height)
//            if point.y >= 0 {
//                chatView.setContentOffset(point, animated: true)
//            }
//        }
//    }
//}
//
//
//
//// MARK: - Select cells.
//extension MessagingViewController: UICollectionViewDelegate {
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
////        collectionView.deselectItem(at: indexPath, animated: true)
//    }
//}
//
//
//
//// MARK: - Config gesture recognizer.
//extension MessagingViewController: UIGestureRecognizerDelegate {
//    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        return [gestureRecognizer, otherGestureRecognizer].contains(panGesture)
//    }
//    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//        if let gesture = gestureRecognizer as? UIPanGestureRecognizer, gesture == panGesture {
//            let translation = gesture.translation(in: gesture.view)
//            return (abs(translation.x) > abs(translation.y)) && (gesture == panGesture)
//        }
//        return true
//    }
//    @IBAction func hideKeyBoardTap(_ sender: UITapGestureRecognizer) {
//        view.endEditing(true)
//    }
//}
//
//
//
//// MARK: - Keyboard.
//extension MessagingViewController: UITextFieldDelegate {
//    @objc func keyboardWillShow(_ notification: NSNotification) {
//        if let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
//            leadingOfTextFieldCS.constant = 8
//            keyboardHeight = keyboardRect.height
//            self.bottomAlignCollectionViewCS.constant = keyboardHeight
//            self.view.layoutIfNeeded()
//            scrollToBottom(of: chatView)
//        }
//    }
//    @objc func keyboardWillHide(notification: NSNotification) {
//        if let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
//            leadingOfTextFieldCS.constant = 120
//            keyboardHeight = keyboardRect.height
//            self.bottomAlignCollectionViewCS.constant = 0
//            self.view.layoutIfNeeded()
//            scrollToBottom(of: chatView)
//        }
//    }
//}
