//
//  ViewController.swift
//  VegaPunk
//
//  Created by Dat Vu on 08/01/2023.
//

import UIKit

class ViewController: UIViewController {
    
    // MARK: -
    static let headerElementKind = "header-element-kind"
    static let footerElementKind = "footer-element-kind"
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    //
    let notificationCenter = NotificationCenter.default
    
    //
    var dataSource: UICollectionViewDiffableDataSource<Int, UserExtractedData>! = nil
    var userExtractedDataList = [UserExtractedData]()
    
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        prepareNavigationViewController()
        configureHierarchy()
        configureDataSource()
        setUpNavigationBar()
        fetch()
        
        notificationCenter.addObserver(self, selector: #selector(websocketReceivedUserPackage(_:)), name: .WebsocketReceivedUserPackage, object: nil)
    }
    

    func prepareNavigationViewController() {
        title = "Explore"
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.navigationBar.sizeToFit()
        self.navigationController?.navigationItem.largeTitleDisplayMode = .always
        
    }
    // MARK: - Set up methods.
    func setUpNavigationBar() {
        // BarButtonItem.
        let leftBarButtonItem: UIBarButtonItem = {
            let bt = UIBarButtonItem(title: "Log out", style: .plain, target: self, action: #selector(signOut))
            bt.tintColor = .systemRed
            return bt
        }()
        navigationItem.leftBarButtonItem = leftBarButtonItem
    }
    
    
    // MARK: - Tasks
    func fetch() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            // Fetch from local
            var storeData = [UserExtractedData]()
            let mappings = Mappings.retrieve()
            let friends = Friend.retrieve().friends
            friends.forEach {
                if let friendId = $0.id,
                   let friendMappingId = mappings.mappingId(friendId) {
                    storeData.append(UserExtractedData(mappingId: friendMappingId, user: $0))
                }
            }
            self.userExtractedDataList = storeData
            self.applySnapshot()
            
            // Fetch from server
            var fetchData = [UserExtractedData]()
            DataInteraction.fetchData { [self] in
                let mappings = Mappings.retrieve()
                let friends = Friend.retrieve().friends
                friends.forEach {
                    if let friendId = $0.id,
                       let friendMappingId = mappings.mappingId(friendId) {
                        fetchData.append(UserExtractedData(mappingId: friendMappingId, user: $0))
                    }
                }
                self.userExtractedDataList = fetchData
                self.applySnapshot()
                if let mappingId = AuthenticatedUser.retrieve()?.data?.mappingId {
                    MappingChatBoxPivots.retrieve().pivots[mappingId].forEach {
                        RequestEngine.getMessagesOfChatBox($0) { messages in
                            Messages(messages).store()
                        }
                    }
                }
            }
        }
    }
    @objc func signOut() {
        resetApplicationMetadata()
        let vc = UIStoryboard(name: "UserAccess", bundle: nil).instantiateInitialViewController()!
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated:true, completion:nil)
        configureApplication()
    }
    @objc func websocketReceivedUserPackage(_ notification: Notification) {
        fetch()
    }
    func resetApplicationMetadata() {
        AuthenticatedUser.remove()
        ChatBoxes.remove()
        Mappings.remove()
        Messages.remove()
        Friend.remove()
    }
    
    /// Configure default specification for application.
    /// - ex: domain, ip, port,..
    func configureApplication() {
        AuthenticatedUser.store(networkConfig: NetworkConfig(domain: "http://192.168.1.24:8080/", ip: "192.168.1.24", port: "8080"))
    }
    
}



// MARK: - Tasks
extension ViewController {
    
    
    // MARK: - Prepare
    func prepareCompositionalLayout(for scrollingBehavior: UICollectionLayoutSectionOrthogonalScrollingBehavior = UICollectionLayoutSectionOrthogonalScrollingBehavior.none, at section: Int, in environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        switch scrollingBehavior {
        case .none:
            let layoutSection: NSCollectionLayoutSection
            var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
            configuration.showsSeparators = false
            configuration.trailingSwipeActionsConfigurationProvider = { [weak self] (indexPath) in
                guard let self = self else { return nil }
                return self.trailingSwipeActionConfigurationForListCellItem(indexPath)
            }
            layoutSection = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
            layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10)
            return layoutSection
        default:
            do {
                let leadingItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.7), heightDimension: .fractionalHeight(1.0)))
                leadingItem.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                
                let trailingItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(0.3)))
                trailingItem.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                let trailingGroup = NSCollectionLayoutGroup.vertical(layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.3), heightDimension: .fractionalHeight(1.0)), subitems: [trailingItem])
                
                let orthogonallyScrolls = scrollingBehavior != .none
                let containerGroupFractionalWidth = orthogonallyScrolls ? CGFloat(0.85) : CGFloat(1.0)
                let containerGroup = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(containerGroupFractionalWidth),
                                                       heightDimension: .fractionalHeight(0.4)),
                    subitems: [leadingItem, trailingGroup])
                let section = NSCollectionLayoutSection(group: containerGroup)
                section.orthogonalScrollingBehavior = scrollingBehavior
                
                let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .estimated(44)),
                    elementKind: ViewController.headerElementKind,
                    alignment: .top)
                section.boundarySupplementaryItems = [sectionHeader]
                return section
            }
        }
    }
    
    
    func trailingSwipeActionConfigurationForListCellItem(_ indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let cellData = userExtractedDataList[indexPath.section]
        let action = UIContextualAction(style: .destructive, title: nil) { [weak self] (_, _, completion) in
            guard let self = self else {
                completion(false)
                return
            }
            RequestEngine.createChatBox(cellData.mappingId) {
                self.fetch()
                SoundFeedBack.success()
                self.navigationItem.rightBarButtonItem?.tintColor = .systemGreen
                self.navigationItem.rightBarButtonItem?.image = UIImage(systemName: "checkmark.circle.fill")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.navigationItem.rightBarButtonItem?.image = nil
                }
            }
            completion(true)
        }
        action.image = UIImage(systemName: "message")
        action.backgroundColor = .systemGray2
        return UISwipeActionsConfiguration(actions: [action])
    }
}



// MARK: - Prepare collection view
extension ViewController {
    func configureHierarchy() {
        // configure collection view
        collectionView.collectionViewLayout = createLayout()
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemGroupedBackground
        
        // collection view delegation
        collectionView.delegate = self
        
        // collection view hierarchy
        view.addSubview(collectionView)
        collectionView.register(UINib(nibName: UserCollectionViewCell.reuseIdentifier, bundle: nil), forCellWithReuseIdentifier: UserCollectionViewCell.reuseIdentifier)
    }
    func createLayout() -> UICollectionViewLayout {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 0
        let layout = UICollectionViewCompositionalLayout(
            sectionProvider: {(
                sectionIndex: Int,
                layoutEnvironment: NSCollectionLayoutEnvironment
            ) -> NSCollectionLayoutSection? in
                return self.prepareCompositionalLayout(at: sectionIndex, in: layoutEnvironment)
            },
            configuration: config
        )
        return layout
    }
    func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, UserExtractedData>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, data: UserExtractedData) -> UICollectionViewCell? in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: UserCollectionViewCell.reuseIdentifier,
                for: indexPath) as? UserCollectionViewCell else { fatalError("Cannot create new cell!") }
            cell.prepare(with: data)
            return cell
        }
    }
    
    func applySnapshot() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            var snapshot = NSDiffableDataSourceSnapshot<Int, UserExtractedData>()
            let sections = Array(0..<self.userExtractedDataList.count)
            for section in sections {
                snapshot.appendSections([section])
                snapshot.appendItems([self.userExtractedDataList[section]])
            }
            self.dataSource.apply(snapshot, animatingDifferences: true)
        }
    }
}



// MARK: - UICollectionViewDelegate
extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
//        let chatBoxViewController = ChatBoxViewController()
//        navigationController?.pushViewController(chatBoxViewController, animated: true)
    }
}




