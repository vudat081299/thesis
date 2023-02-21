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
    var mappingId: UUID
    var user: User
    var chatBox: ChatBox?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(mappingId)
    }
    
    static func == (lhs: UserViewModel, rhs: UserViewModel) -> Bool {
        return lhs.mappingId == rhs.mappingId
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
        let placeholderImage = UIImage(systemName: "person.circle")
        let options = ImageLoadingOptions(
            placeholder: placeholderImage?.withTintColor(.systemGray2),
            transition: .fadeIn(duration: 0.5)
        )
        let urlString = (QueryBuilder.queryInfomation(.downloadFile)?.genUrl())! + (data.user.avatar ?? "")
        let url = URL(string: urlString)!
        Nuke.loadImage(with: url, options: options, into: avatar)
        
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
