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
    @IBOutlet weak var image: UIImageView!
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
        image.contentMode = .scaleAspectFit
        containerView.backgroundColor = .white
    }
    
    func prepare(with text: String? = nil, type: TypeAvatar) {
        
        let placeholderImage = UIImage(systemName: "person")
        let options = ImageLoadingOptions(
            placeholder: placeholderImage?.withTintColor(.systemGray2),
            transition: .fadeIn(duration: 0.5)
        )
        
        let query = QueryBuilder.queryInfomation(.downloadFile)
        guard let imageUrl = text else { return }
        let urlString = (query?.genUrl())! + imageUrl
        let url = URL(string: urlString)!
        
        label.isHidden = imageUrl.count > 1
        image.isHidden = imageUrl.count < 1
        
        
        if imageUrl.count > 1 {
            Nuke.loadImage(with: url, options: options, into: image)
        } else {
            label.text = imageUrl.first?.description
        }
//        containerView.roundedBorder()
//        image.roundedBorder()
        switch type {
        case .single:
            containerView.border(20)
            image.border(18)
            break
        case .multiple:
            containerView.border(16)
            image.border(14)
            break
        }
    }
}
