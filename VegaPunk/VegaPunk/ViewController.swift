//
//  ViewController.swift
//  VegaPunk
//
//  Created by Dat Vu on 08/01/2023.
//

import UIKit

var configureIp: String {
    UserDefaults.standard.string(forKey: "storage_ip") ?? "192.168.1.24"
}

class ViewController: UIViewController {
    
    // MARK: -
    static let headerElementKind = "header-element-kind"
    static let footerElementKind = "footer-element-kind"
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    //
    let notificationCenter = NotificationCenter.default
    
    //
    var dataSource: UICollectionViewDiffableDataSource<Int, UserViewModel>! = nil
    var userViewModel = [UserViewModel]()
    
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        prepareView()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetch()
    }
    deinit {
        notificationCenter.removeObserver(self, name: .WebsocketReceivedUserPackage, object: nil)
    }
    
    
    // MARK: - Prepare view
    func prepareView() {
        prepareNavigationViewController()
        configureHierarchy()
        configureDataSource()
        prepareObserver()
        
        func prepareObserver() {
            notificationCenter.addObserver(self, selector: #selector(websocketReceivedUserPackage(_:)), name: .WebsocketReceivedUserPackage, object: nil)
        }
        func prepareNavigationViewController() {
            title = "Khám phá"
            self.navigationController?.navigationBar.prefersLargeTitles = true
            self.navigationController?.navigationBar.sizeToFit()
            self.navigationController?.navigationItem.largeTitleDisplayMode = .always
            prepareNavigationBar()
        }
        func prepareNavigationBar() {
            // BarButtonItem
        }
    }
    
    
    // MARK: - Tasks
    /// Fetch data from local storage and then fetch data from server.
    /// - Note: This method reload collectionView snapshot in closure on sub thread so the collectionView must have been set up before call this method.
    func fetch() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            // Fetch from local
            self.userViewModel.retrieve()
            self.applySnapshot()
            
            // Fetch from server
            DataInteraction.newUserFetch() { [self] in
                self.userViewModel.retrieve()
                self.applySnapshot()
                Messages.fetch()
            }
        }
    }
    
    
    // MARK: Mini tasks
    @objc func websocketReceivedUserPackage(_ notification: Notification) {
        fetch()
    }
}


// MARK: - Prepare collection view
extension ViewController {
    
    
    // MARK: - Prepare composition layout
    func prepareCompositionalLayout(for scrollingBehavior: UICollectionLayoutSectionOrthogonalScrollingBehavior = UICollectionLayoutSectionOrthogonalScrollingBehavior.none, at section: Int, in environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        switch scrollingBehavior {
        case .none:
            let layoutSection: NSCollectionLayoutSection
            var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
            configuration.showsSeparators = false
            configuration.trailingSwipeActionsConfigurationProvider = { [weak self] (indexPath) in
                guard let self = self else { return nil }
                return self.trailingSwipeAction(indexPath)
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
    func trailingSwipeAction(_ indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let cellData = userViewModel[indexPath.section]
        let action = UIContextualAction(style: .destructive, title: nil) { [weak self] (_, _, completion) in
            guard let self = self else {
                completion(false)
                return
            }
            if let userId = AuthenticatedUser.retrieve()?.data?.id! {
                if ChatboxMembers.retrieve().chatboxMembers.hasChatbox(between: [userId, cellData.user.id!]) != nil {
                    completion(true)
                    return
                }
            }
            RequestEngine.createChatBox(cellData.user.id!) {
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
                section: Int,
                layoutEnvironment: NSCollectionLayoutEnvironment
            ) -> NSCollectionLayoutSection? in
                return self.prepareCompositionalLayout(at: section, in: layoutEnvironment)
            },
            configuration: config
        )
        return layout
    }
    func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, UserViewModel>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, data: UserViewModel) -> UICollectionViewCell? in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: UserCollectionViewCell.reuseIdentifier,
                for: indexPath) as? UserCollectionViewCell else { fatalError("Cannot create new cell!") }
            cell.prepare(with: data)
            return cell
        }
    }
    func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, UserViewModel>()
        let sections = Array(0..<self.userViewModel.count)
        for section in sections {
            snapshot.appendSections([section])
            snapshot.appendItems([self.userViewModel[section]])
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.dataSource.apply(snapshot, animatingDifferences: true)
            self.collectionView.reloadData()
            self.collectionView.layoutIfNeeded()
        }
    }
}


// MARK: - UICollectionViewDelegate
extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let userProfileViewController = UserProfileViewController()
        let user = userViewModel[indexPath.section].user
        userProfileViewController.user = user
        userProfileViewController.title = user.name
        navigationController?.pushViewController(userProfileViewController, animated: true)
    }
}




