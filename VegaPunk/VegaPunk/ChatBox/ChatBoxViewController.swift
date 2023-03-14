//
//  MessagingViewControllerTableView.swift
//  VegaPunk
//
//  Created by Dat vu on 13/05/2021.
//

import UIKit

class ChatBoxViewController: UIViewController {
    
    
    // MARK: - IBOutlet
    @IBOutlet weak var tableView: UITableView!
    
    //
    let notificationCenter = NotificationCenter.default
    
    //
    var chatBoxViewModel = [ChatBoxViewModel]()
    var friends = [User]()
    var user: AuthenticatedUser!
    let messagingViewController = MessagingViewController()
    
    
    // MARK: - Navbar components.
//    let searchController: UISearchController = {
//        let searchController = UISearchController(searchResultsController: nil)
//        searchController.searchBar.placeholder = "New Search"
//        searchController.searchBar.searchBarStyle = .minimal
////        searchController.dimsBackgroundDuringPresentation = false // was deprecated in iOS 12.0
//        searchController.definesPresentationContext = true
//       return searchController
//    }()

    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        prepareView()
        configureHierarchy()
        
        // Observer
        notificationCenter.addObserver(self, selector: #selector(websocketReceivedChatBoxPackage(_:)), name: .WebsocketReceivedChatBoxPackage, object: nil)
        notificationCenter.addObserver(self, selector: #selector(websocketReceivedMessagePackage(_:)), name: .WebsocketReceivedMessagePackage, object: nil)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.prefersLargeTitles = true
        fetchChatBox()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tabBarController?.tabBar.isHidden = false
    }
    deinit {
        notificationCenter.removeObserver(self, name: .WebsocketReceivedChatBoxPackage, object: nil)
        notificationCenter.removeObserver(self, name: .WebsocketReceivedMessagePackage, object: nil)
    }
    
    
    // MARK: - Tasks
    @objc func websocketReceivedChatBoxPackage(_ notification: Notification) {
        if navigationController?.topViewController == self {
            fetchChatBox()
        }
    }
    @objc func websocketReceivedMessagePackage(_ notification: Notification) {
        if navigationController?.topViewController == self {
            fetchMessage()
        }
    }
    func fetchChatBox() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            guard let authenticatedUser = AuthenticatedUser.retrieve(),
                  let userId = authenticatedUser.data?.id
            else { return }
            self.user = authenticatedUser
            self.friends = Friend.retrieve().friends
            
            // Fetch from local
            self.setUp(with: userId)
            
            // Fetch from server
            DataInteraction.newChatBoxFetch() {
                self.setUp(with: userId)
            }
            
        }
    }
    func fetchMessage() {
        guard let authenticatedUser = AuthenticatedUser.retrieve(),
              let userId = authenticatedUser.data?.id
        else { return }
        setUp(with: userId)
    }
    /// Confuse declaration
    func setUp(with mappingId: UUID) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.chatBoxViewModel.retrieve(with: mappingId)
            self.tableView.reloadData()
        }
        
        let queue = DispatchQueue(label: "com.vudat081299.Vegapunk")
        queue.async {
            let listChatBoxId1 = self.chatBoxViewModel.map { $0.chatBox.id }
            let chatboxes = Chatboxes.retrieve().chatboxes
            let listChatBoxId2 = chatboxes.map { $0.id }
            var newChatBoxId: UUID?
            for chatBoxId in listChatBoxId2 {
                if !listChatBoxId1.contains(chatBoxId) {
                    newChatBoxId = chatBoxId
                    break
                }
            }
            if let chatBoxId = newChatBoxId {
                Messages.fetch(chatBoxId)
            }
            Thread.sleep(until: Date().addingTimeInterval(1))
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.chatBoxViewModel.retrieve(with: mappingId)
                self.tableView.reloadData()
            }
        }
    }
    func prepareView() {
        view.backgroundColor = .systemBackground
    }
    
    
    // MARK: - Mini tasks
    func getMembersInChatBox(with userIds: [UUID]) -> [User] {
        return friends.filter { userIds.contains($0.id!) }
    }
    
    
    // MARK: - APIs
    func leave(from chatBoxId: UUID) {
        RequestEngine.delete(member: (user.data?.id)!, from: chatBoxId, completion: { [self] in
            DispatchQueue.main.async { [self] in
                chatBoxViewModel = chatBoxViewModel.filter { $0.chatBox.id != chatBoxId }
                tableView.reloadData()
            }
            update()
        })
    }
    
    func update() {
        RequestEngine.getAllMappingPivots()
    }
}


// MARK: - TableView
extension ChatBoxViewController: UITableViewDelegate, UITableViewDataSource {
    private func configureHierarchy() {
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: ChatBoxTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: ChatBoxTableViewCell.reuseIdentifier)
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatBoxViewModel.count;
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatBoxTableViewCell.reuseIdentifier, for: indexPath) as! ChatBoxTableViewCell
        cell.delegate = self
        let data = chatBoxViewModel[indexPath.row]
        cell.prepare(with: data)
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        messagingViewController.extractedChatBox = chatBoxViewModel[indexPath.row]
        messagingViewController.tabBarController?.tabBar.isHidden = true
        messagingViewController.navigationController?.modalPresentationStyle = .fullScreen
        navigationController?.pushViewController(messagingViewController, animated: true)
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive,
                                        title: "Rời nhóm") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            let alert = UIAlertController(title: "Rời khỏi nhóm chat", message: "Bạn có muốn rời khỏi nhóm chat?", preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Huỷ", style: .default, handler: nil)
            let leave = UIAlertAction(title: "Rời nhóm", style: .destructive) { _ in
                self.leave(from: self.chatBoxViewModel[indexPath.row].chatBox.id)
            }
            alert.addAction(cancel)
            alert.addAction(leave)
            alert.preferredAction = cancel
            self.present(alert, animated: true, completion: nil)
            completionHandler(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
}
