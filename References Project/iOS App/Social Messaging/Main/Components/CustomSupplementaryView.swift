//
//  CustomSupplementaryView.swift
//  Social Messaging
//
//  Created by Vũ Quý Đạt  on 14/04/2021.
//

import UIKit

class CustomSupplementaryView: UICollectionReusableView {
    static let reuseIdentifier = "CustomSupplementaryView"
    
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}
