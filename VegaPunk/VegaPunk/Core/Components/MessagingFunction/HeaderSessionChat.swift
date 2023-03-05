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
    
    @IBOutlet weak var avatarLayer: UIView!
    @IBOutlet weak var avatarContainer: UIView!
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var constraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        avatar.tintColor = .systemGray3
        avatarContainer.border()
//        avatarContainer.dropShadow()
        avatarLayer.border()
        avatarLayer.dropShadow()
        self.clipsToBounds = false
        
        avatar.contentMode = .scaleAspectFill
        let contentModes = ImageLoadingOptions.ContentModes(
          success: .scaleAspectFill,
          failure: .scaleAspectFill,
          placeholder: .scaleAspectFill)
        
        let placeholderImage = UIImage(systemName: "person.circle")
        ImageLoadingOptions.shared.contentModes = contentModes
        ImageLoadingOptions.shared.placeholder = placeholderImage?.withTintColor(.systemGray2)
        ImageLoadingOptions.shared.transition = .fadeIn(duration: 0.5)
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
        var pixelSize: CGFloat { return 160 }
        var resizedImageProcessors: [ImageProcessing] {
            let imageSize = CGSize(width: pixelSize, height: pixelSize)
            return [ImageProcessors.Resize(size: imageSize, contentMode: .aspectFill)]
        }
        let urlString = (QueryBuilder.queryInfomation(.downloadFile)?.genUrl())! + (avatarFileId ?? "")
        let imageUrl = URL(string: urlString)!
        let request = ImageRequest(url: imageUrl, processors: resizedImageProcessors)
        Nuke.loadImage(with: request, into: avatar)
    }
}

