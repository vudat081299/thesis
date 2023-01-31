//
//  UserCollectionViewCell.swift
//  VegaPunk
//
//  Created by Dat Vu on 02/01/2023.
//

import UIKit

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
    
    @IBOutlet weak var iconBackGround: UIImageView!
    @IBOutlet weak var icon: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var type: UILabel!
    @IBOutlet weak var note: UILabel!
    @IBOutlet weak var bio: UILabel!
    
    var data: UserExtractedData!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
//        self.contentView.layer.cornerRadius = 16
//        self.contentView.clipsToBounds = true
        icon.text = ""
        self.contentView.backgroundColor = .systemBackground
        iconBackGround.layer.cornerRadius = iconBackGround.bounds.width / 2
        iconBackGround.clipsToBounds = true
        iconBackGround.borderOutline(2, color: .link)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        prepareCell()
    }
    
    func prepareCell() {
        let avatarLabels = ["🐝", "😝", "🍌", "☔️", "😊", "☕️"]
        if let userInfor = data.user.avatar, let avatar = Int(userInfor) {
            icon.text = avatarLabels[avatar]
        }
        if let name = data.user.name {
            type.text = name
        }
        if let username = data.user.username {
            note.text = username
        }
        if let bio = data.user.bio {
            self.bio.text = bio
        }
    }
}
