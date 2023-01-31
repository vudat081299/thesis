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
    
    var dataSource: UICollectionViewDiffableDataSource<Int, UserExtractedData>! = nil
    var userExtractedDataList = [UserExtractedData]()
    
    
    // MARK: - App default configuration
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        prepareData()
        prepareNavigationViewController()
        configureHierarchy()
        configureDataSource()
        applySnapshot()
    }
    
    
    
    func prepareNavigationViewController() {
        title = "Explore"
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.navigationBar.sizeToFit()
        self.navigationController?.navigationItem.largeTitleDisplayMode = .always
        
    }
    
    
    // MARK: - Mini tasks
    func prepareData() {
//        Friend.retrieve().friends.forEach {
//            if let userMappingId = userDataGlobal?.mappingId, let friendId = $0.id, let friendMappingId = mappingsGlobal.mappingId(friendId), let chatBoxId = pivotGlobal.hasChatBox(between: [userMappingId, friendMappingId]) {
//                cellData.append(UserCellData(chatBox: ChatBoxes.retrieve()[chatBoxId], friendInformation: $0, friendMappingId: friendMappingId))
//            }
//        }
        Friend.retrieve().friends.forEach {
            if let friendId = $0.id, let friendMappingId = mappingsGlobal.mappingId(friendId) {
                userExtractedDataList.append(UserExtractedData(mappingId: friendMappingId, user: $0))
            }
        }
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
        let sec = indexPath.section
        let _ = indexPath.row
        let starAction = UIContextualAction(style: .destructive, title: nil) { [weak self] (_, _, completion) in
            guard let self = self else {
                completion(false)
                return
            }
            
            // call video here
            completion(true)
        }
        starAction.image = UIImage(systemName: "message")
        starAction.backgroundColor = .link
        return UISwipeActionsConfiguration(actions: [starAction])
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
            cell.data = data
            cell.prepareCell()
            return cell
        }
    }
    
    func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, UserExtractedData>()
        var numberOfSections = 0
        for data in userExtractedDataList {
            snapshot.appendSections([numberOfSections])
            numberOfSections += 1
            snapshot.appendItems([data])
        }
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}



// MARK: - UICollectionViewDelegate
extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let chattingViewController = ChattingViewController()
        let data = userExtractedDataList[indexPath.section]
        chattingViewController.data = data
        chattingViewController.title = data.user.name
        chattingViewController.navigationItem.largeTitleDisplayMode = .never
        chattingViewController.tabBarController?.tabBar.isHidden = true
        navigationController?.pushViewController(chattingViewController, animated: true)
        self.tabBarController?.tabBar.isHidden = true
    }
}




