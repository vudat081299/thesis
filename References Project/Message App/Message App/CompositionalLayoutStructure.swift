//
//  CompositionalLayoutStructure.swift
//  Message App
//
//  Created by Dat Vu on 04/12/2022.
//

import UIKit

enum SectionType: Int, CaseIterable {
    case list, collection
}

/// - Tag: OrthogonalBehavior
enum SectionKind: Int, CaseIterable {
    case continuous, continuousGroupLeadingBoundary, paging, groupPaging, groupPagingCentered, noneType
    func orthogonalScrollingBehavior() -> UICollectionLayoutSectionOrthogonalScrollingBehavior {
        switch self {
        case .noneType:
            return UICollectionLayoutSectionOrthogonalScrollingBehavior.none
        case .continuous:
            return UICollectionLayoutSectionOrthogonalScrollingBehavior.continuous
        case .continuousGroupLeadingBoundary:
            return UICollectionLayoutSectionOrthogonalScrollingBehavior.continuousGroupLeadingBoundary
        case .paging:
            return UICollectionLayoutSectionOrthogonalScrollingBehavior.paging
        case .groupPaging:
            return UICollectionLayoutSectionOrthogonalScrollingBehavior.groupPaging
        case .groupPagingCentered:
            return UICollectionLayoutSectionOrthogonalScrollingBehavior.groupPagingCentered
        }
    }
}

extension ViewController {
    static let headerElementKind = "header-element-kind"
}

/// Cell data structure.
class Cell: Hashable {
    let image: UIImage?
    let data: (String?, String?) // (label, detaiLabel)
    let select: (() -> Void)? // select cell
    let cellClass: UITableViewCell // class of cell
    let viewControllerType: UIViewController.Type? // view show when select cell
    
    init(image: UIImage? = nil,
         data: (String?, String?) = (nil, nil),
         select: (() -> ())? = nil,
         cellClass: UITableViewCell = UITableViewCell(),
         viewControllerType: UIViewController.Type? = nil
    ) {
        self.image = image
        self.data = data
        self.select = select
        self.cellClass = cellClass
        self.viewControllerType = viewControllerType
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    static func == (lhs: Cell, rhs: Cell) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    private let identifier = UUID()
}

/// Sectiion data structure.
class SectionItem {
    let cells: [Cell]
    let sectionType: SectionType?
    let behavior: SectionKind?
    let supplementaryData: (String?, String?)
    let header: UICollectionReusableView?
    let footer: UICollectionReusableView?
    
    init(cells: [Cell],
         sectionType: SectionType? = .list,
         behavior: SectionKind? = .continuous,
         supplementaryData: (String?, String?) = (nil, nil),
         header: UICollectionReusableView? = nil,
         footer: UICollectionReusableView? = nil
    ) {
        self.cells = cells
        self.sectionType = sectionType
        self.behavior = behavior
        self.supplementaryData = supplementaryData
        self.header = header
        self.footer = footer
    }
}
