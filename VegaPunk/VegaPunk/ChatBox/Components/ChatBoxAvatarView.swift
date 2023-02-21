//
//  ChatBoxAvatarView.swift
//  VegaPunk
//
//  Created by Dat Vu on 07/02/2023.
//

import UIKit
import Nuke

enum TypeAvatar {
    case single, multiple
}

/**
 - Note: Very `confuse` that it's work even when set File's Owner class in .xib is `ReusableUIView`instead of `ChatBoxAvatarView`
 */
class ChatBoxAvatarView: ReusableUIView {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    let defaultEmoji = "😄"
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    func configure() {
        label.isHidden = true
        avatar.contentMode = .scaleAspectFill
        containerView.backgroundColor = .white
    }
    
    func prepare(with avatarFileId: String? = nil, type: TypeAvatar) {
        let placeholderImage = UIImage(systemName: "person.circle")
        let options = ImageLoadingOptions(
            placeholder: placeholderImage?.withTintColor(.systemGray2),
            transition: .fadeIn(duration: 0.5)
        )
        let urlString = (QueryBuilder.queryInfomation(.downloadFile)?.genUrl())! + (avatarFileId ?? "")
        let url = URL(string: urlString)!
        Nuke.loadImage(with: url, options: options, into: avatar)
        
//        containerView.roundedBorder()
//        image.roundedBorder()
        switch type {
        case .single:
            containerView.border(20)
            avatar.border(18)
            break
        case .multiple:
            containerView.border(16)
            avatar.border(14)
            break
        }
    }
}
