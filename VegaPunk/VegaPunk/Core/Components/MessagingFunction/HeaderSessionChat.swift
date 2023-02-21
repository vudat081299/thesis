//
//  HeaderSessionChat.swift
//  Social Messaging
//
//  Created by Vũ Quý Đạt  on 21/04/2021.
//

import UIKit
import Nuke

class HeaderSessionChat: UICollectionReusableView {
    static let reuseIdentifier = "HeaderSessionChat"
    
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var constraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = 8
        self.clipsToBounds = false
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        constraint.constant = 0
        avatar.image = nil
    }
}

extension HeaderSessionChat {
    func prepare(_ avatarFileId: String?) {
        let placeholderImage = UIImage(systemName: "person.circle")
        let options = ImageLoadingOptions(
            placeholder: placeholderImage?.withTintColor(.systemGray2),
            transition: .fadeIn(duration: 0.5)
        )
        let urlString = (QueryBuilder.queryInfomation(.downloadFile)?.genUrl())! + (avatarFileId ?? "")
        let url = URL(string: urlString)!
        Nuke.loadImage(with: url, options: options, into: avatar)
    }
}

