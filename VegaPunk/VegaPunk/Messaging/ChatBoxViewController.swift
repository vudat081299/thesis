//
//  MessagingViewControllerTableView.swift
//  VegaPunk
//
//  Created by Dat vu on 13/05/2021.
//

import UIKit

class ChatBoxViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    var chatBoxExtractedDataList = [ChatBoxExtractedData]()
    var friends = [User]()
    var authenticatedUser: AuthenticatedUser!
    
    
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
        configureHierarchy()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Prepare data
        prepareData()

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
    func prepareData() {
        resetData()
        
        // ChatBox Friend pivot
        guard let authenticatedUser = AuthenticatedUser.retrieve(),
              let mappingId = authenticatedUser.data?.mappingId else { return }
        self.authenticatedUser = authenticatedUser
        var chatBoxes = ChatBoxes.retrieve().chatBoxes
        let pivots = MappingChatBoxPivots.retrieve().pivots
        let userChatBoxIds = pivots[mappingId]
        chatBoxes = chatBoxes.filter { userChatBoxIds.contains($0.id) }
        chatBoxes.forEach {
            let members = pivots[mappingId, $0.id]
            chatBoxExtractedDataList.append(ChatBoxExtractedData(chatBox: $0, members: members))
        }
        friends = Friend.retrieve().friends
        
        tableView.reloadData()
    }
    func resetData() {
        chatBoxExtractedDataList = []
        friends = []
        authenticatedUser = nil
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
        return chatBoxExtractedDataList.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatBoxTableViewCell.reuseIdentifier, for: indexPath) as! ChatBoxTableViewCell
        let data = chatBoxExtractedDataList[indexPath.row]
        cell.prepare(with: data)
        return cell
    }
    
}
