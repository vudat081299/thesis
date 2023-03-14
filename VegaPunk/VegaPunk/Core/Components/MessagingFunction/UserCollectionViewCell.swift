//
//  UserCollectionViewCell.swift
//  VegaPunk
//
//  Created by Dat Vu on 02/01/2023.
//

import UIKit
import Nuke


// MARK: - Definition
enum HighLightColor: Int {
    case red, blue, orange, green, purple, cyan, mint, gray
    func color() -> UIColor {
        switch self {
        case .red: return .systemRed
        case .blue: return .link
        case .orange: return .systemOrange
        case .green: return .systemGreen
        case .purple: return .systemPurple
        case .cyan: return .systemCyan
        case .mint: return .systemMint
        case .gray: return .systemGray
        }
    }
}

struct UserViewModel: Hashable {
    var user: User
    var chatBox: Chatbox?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(user.id)
    }
    
    static func == (lhs: UserViewModel, rhs: UserViewModel) -> Bool {
        return lhs.user.id == rhs.user.id
    }
}

class UserCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "UserCollectionViewCell"
    
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var emoji: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var bio: UILabel!
    
    var data: UserViewModel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.contentView.backgroundColor = .systemBackground
        avatar.roundedBorder()
        resetCell()
        
        avatar.tintColor = .systemGray3
        avatar.contentMode = .scaleAspectFill
        
        let contentModes = ImageLoadingOptions.ContentModes(
          success: .scaleAspectFill,
          failure: .scaleAspectFill,
          placeholder: .scaleAspectFill)
        
        let placeholderImage = UIImage(systemName: "person.circle")
        ImageLoadingOptions.shared.contentModes = contentModes
        ImageLoadingOptions.shared.placeholder = placeholderImage
        ImageLoadingOptions.shared.transition = .fadeIn(duration: 0.5)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        resetCell()
    }
    
    func prepare(with userExtractedData: UserViewModel? = nil) {
        guard let validatedData = userExtractedData else { return }
        data = validatedData
        
        prepareAvatar()
        prepareLabel()
    }
    
    func prepareAvatar() {
        var pixelSize: CGFloat { return 160 }
        var resizedImageProcessors: [ImageProcessing] {
            let imageSize = CGSize(width: pixelSize, height: pixelSize)
            return [ImageProcessors.Resize(size: imageSize, contentMode: .aspectFit)]
        }
        let urlString = (QueryBuilder.queryInfomation(.downloadFile)?.genUrl())! + (data.user.avatar ?? "")
        let imageUrl = URL(string: urlString)!
        let request = ImageRequest(url: imageUrl, processors: resizedImageProcessors)
        Nuke.loadImage(with: request, into: avatar)
        
//        let avatarLabels = ["🐝", "😝", "🍌", "☔️", "😊", "☕️"]
//        if let userInfor = data.user.avatar, let avatar = Int(userInfor) {
//            emoji.text = avatarLabels[avatar]
//        }
    }
    
    func prepareLabel() {
        name.text = data.user.name
        username.text = "@" + (data.user.username ?? "")
        bio.text = data.user.bio
    }
    
    func resetCell() {
        avatar.image = nil
        emoji.text = nil
        name.text = nil
        username.text = nil
        bio.text = nil
    }
}
