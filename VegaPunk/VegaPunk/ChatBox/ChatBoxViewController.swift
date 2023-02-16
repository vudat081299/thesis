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


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    // MARK: - Tasks
    @objc func websocketReceivedChatBoxPackage(_ notification: Notification) {
        if navigationController?.topViewController == self {
            fetchChatBox()
            i = 0
        }
    }
    @objc func websocketReceivedMessagePackage(_ notification: Notification) {
        if navigationController?.topViewController == self {
            fetchMessage()
        }
    }
    func fetchMessage() {
        guard let authenticatedUser = AuthenticatedUser.retrieve(),
              let mappingId = authenticatedUser.data?.mappingId
        else { return }
        setUp(with: mappingId)
    }
    var i = 0
    func setUp(with mappingId: UUID) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.i += 1
            print(self.i)
            self.chatBoxViewModel.retrieve(with: mappingId)
            self.chatBoxViewModel.forEach {
                print($0.lastestMessage?.content)
            }
            self.tableView.reloadData()
        }
        
        let queue = DispatchQueue(label: "com.vudat081299.Vegapunk")
        queue.async {
            let listChatBoxId1 = self.chatBoxViewModel.map { $0.chatBox.id }
            let chatBoxes = ChatBoxes.retrieve().chatBoxes
            let listChatBoxId2 = chatBoxes.map { $0.id }
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
                self.i += 1
                print(self.i)
                self.chatBoxViewModel.retrieve(with: mappingId)
                self.chatBoxViewModel.forEach {
                    print($0.lastestMessage?.content)
                }
                self.tableView.reloadData()
            }
        }
    }
    func fetchChatBox() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            guard let authenticatedUser = AuthenticatedUser.retrieve(),
                  let mappingId = authenticatedUser.data?.mappingId
            else { return }
            self.user = authenticatedUser
            self.friends = Friend.retrieve().friends
            
            // Fetch from local
            self.setUp(with: mappingId)
            
            // Fetch from server
            DataInteraction.newChatBoxFetch() {
                self.setUp(with: mappingId)
            }
            
        }
    }
    func prepareView() {
        view.backgroundColor = .systemBackground
    }
    
    
    // MARK: - Mini tasks
    func getMembersInChatBox(with mappingIds: [UUID]) -> [User] {
        return friends.filter { mappingIds.contains($0.mappingId!) }
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
}
