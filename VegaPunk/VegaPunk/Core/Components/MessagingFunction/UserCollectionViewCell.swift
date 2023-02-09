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

struct UserExtractedData: Hashable {
    var mappingId: UUID
    var user: User
    var chatBox: ChatBox?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(mappingId)
    }
    
    static func == (lhs: UserExtractedData, rhs: UserExtractedData) -> Bool {
        return lhs.mappingId == rhs.mappingId
    }
}

class UserCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "UserCollectionViewCell"
    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var emoji: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var type: UILabel!
    @IBOutlet weak var note: UILabel!
    @IBOutlet weak var bio: UILabel!
    
    var data: UserExtractedData!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.contentView.backgroundColor = .systemBackground
        image.roundedBorder()
        image.image = nil
        emoji.text = ""
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        image.image = nil
        emoji.text = ""
    }
    
    func prepare(with userExtractedData: UserExtractedData? = nil) {
        guard let validatedData = userExtractedData else { return }
        data = validatedData
        
        prepareAvatar()
        fillTextIBOutlets()
    }
    
    func prepareAvatar() {
        image.isHidden = data.user.avatar?.count == 1
        emoji.isHidden = !image.isHidden
        if (data.user.avatar?.count == 1) {
            emoji.text = data.user.avatar
        } else {
            Nuke.loadImage(with: URL(string: imageUrl)!, into: image)
        }
        
//        let avatarLabels = ["🐝", "😝", "🍌", "☔️", "😊", "☕️"]
//        if let userInfor = data.user.avatar, let avatar = Int(userInfor) {
//            emoji.text = avatarLabels[avatar]
//        }
    }
    
    func fillTextIBOutlets() {
        if let name = data.user.name {
            type.text = name
        }
        if let username = data.user.username {
            note.text = "@" + username
        }
        if let bio = data.user.bio {
            self.bio.text = bio
        }
    }
}
