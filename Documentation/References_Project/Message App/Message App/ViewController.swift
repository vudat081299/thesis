//
//  ViewController.swift
//  Message App
//
//  Created by Dat Vu on 04/12/2022.
//

import UIKit

class ViewController: UIViewController {
    
    var friends: [User] = [] {
        didSet {
            prepareDataSource()
        }
    }
    
    private lazy var sectionItems: [SectionItem] = {
        let cells: [Cell] = {
            var list: [Cell] = []
            for i in 0...100 {
                let customCell = Cell(data: ("\(i)", "\(i + 1)"), select: triggerCellAction)
                list.append(customCell)
            }
            return list
        }()
        return [SectionItem(cells: cells, sectionType: .collection, behavior: .noneType)]
    }()

    func triggerCellAction() {
        print("Trigger cell action!")
    }
    
    
    
    // MARK: - Variables.
    
    
    
    
    // MARK: - IBOutlet and UI constant.
//    var collectionView: UICollectionView! = nil
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    
    // MARK: - Navigation Bar set up and create component.
    let searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = "New Search"
        searchController.searchBar.searchBarStyle = .minimal
//        searchController.dimsBackgroundDuringPresentation = false // was deprecated in iOS 12.0
        searchController.definesPresentationContext = true
       return searchController
    }()
    
    @objc func leftBarItemAction() {
        print("Left bar button was pressed!")
        
//        let updateUser = User(id: UUID(uuidString: "A83D1C56-E773-48A3-9E1B-716CE73C61C7")!, name: "dat1", username: "dat1", email: "vudat081299@gmail.com", join: nil, phone: "076223870", birth: nil, siwaIdentifier: "test", avatar: "test", password: nil, country: "VN", gender: .female)
//        RequestService.updateUser(updateUser)
        
        AuthenticationService.getMyMapping()
        RequestService.readAllUsers()
        friends = DataService.friends
    }
    
    @objc func rightBarItemAction() {
        print("Right bar button was pressed!")
    }
    
    func prepareNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.sizeToFit()
        
        navigationItem.largeTitleDisplayMode = .always
//        navigationItem.searchController = searchController
//        navigationItem.hidesSearchBarWhenScrolling = false
        
//        self.searchController.hidesNavigationBarDuringPresentation = true
//        self.searchController.searchBar.searchBarStyle = .prominent
//        // Include the search bar within the navigation bar.
//        self.navigationItem.titleView = self.searchController.searchBar
        
        let leftBarItem: UIBarButtonItem = {
            let bt = UIBarButtonItem(title: "Action", style: .done, target: self, action: #selector(leftBarItemAction))
            return bt
        }()
        let rightBarItem: UIBarButtonItem = {
            let bt = UIBarButtonItem(image: UIImage(systemName: "bookmark.circle"), style: .plain, target: self, action: #selector(rightBarItemAction))
            return bt
        }()
        navigationItem.leftBarButtonItem = leftBarItem
        navigationItem.rightBarButtonItem = rightBarItem
    }
    

    
    // MARK: - Life cycle.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Default configurations.
        definesPresentationContext = true
        
        // Do any additional setups after loading the view.
        prepareNavigationBar()
        
        // Setting up collection view.
        prepareCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
}

// MARK: - Collection view layout.
extension ViewController {
    func createLayout() -> UICollectionViewLayout {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 20
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { [self] (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(150)))
//            item.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
            let containerGroup = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(150)), subitems: [item])
            let section = NSCollectionLayoutSection(group: containerGroup)
            section.orthogonalScrollingBehavior = .none
            return section
            
        }, configuration: config)
        return layout
    }
}



// MARK: - Collection view dataSource.
extension ViewController {
    func prepareCollectionView() {
//        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.frame = view.bounds
        collectionView.collectionViewLayout = createLayout()
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.delegate = self
        view.addSubview(collectionView)
        
        collectionView.register(UINib(nibName: CustomCollectionViewListCell.reuseIdentifier, bundle: nil), forCellWithReuseIdentifier: CustomCollectionViewListCell.reuseIdentifier)
        collectionView.register(UINib(nibName: CustomSupplementaryView.reuseIdentifier, bundle: nil), forSupplementaryViewOfKind: ViewController.headerElementKind, withReuseIdentifier: CustomSupplementaryView.reuseIdentifier)
        collectionView.register(UINib(nibName: UserCollectionViewCell.reuseIdentifier, bundle: nil), forCellWithReuseIdentifier: UserCollectionViewCell.reuseIdentifier)
    }
    
    func prepareDataSource() {
        // UICollectionViewDiffableDataSource work similar like [cellForItem]
        let dataSource = UICollectionViewDiffableDataSource<Int, Int>(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, identifier: Int) -> UICollectionViewCell? in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserCollectionViewCell.reuseIdentifier, for: indexPath) as? UserCollectionViewCell else { fatalError("Cannot create new cell") }
            let user = self.friends[indexPath.row]
            cell.userProfileData = user
            cell.name.text = user.name
            cell.username.text = "@\(user.username)"
            cell.bio.text = "reuseIdentifier, for: indexPath) as? UserView else { fatalError( vudat8129 vudat dat Cannot"
            cell.messToUserActionClosure = {}
            return cell
        }

        // NSDiffableDataSourceSnapshot work similar like [numberOfSection] and [numberOfCell]
        if self.friends.count > 0 {
            var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
            snapshot.appendSections([0])
            snapshot.appendItems(Array(0...(self.friends.count - 1)))
            dataSource.apply(snapshot, animatingDifferences: false)
        }
    }
}



// MARK: - Collection view delegate.
extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let cellItem = sectionItems[indexPath.section].cells[indexPath.row]
        if let action = cellItem.select { action() }
        if let viewController = cellItem.viewControllerType {
            navigationController?.pushViewController(viewController.init(), animated: true)
        }
    }
}
