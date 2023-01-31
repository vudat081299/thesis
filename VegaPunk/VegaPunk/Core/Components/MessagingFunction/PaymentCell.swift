//
//  PaymentCell.swift
//  Spending
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

struct UserCellData: Hashable {
    var chatBox: ChatBox?
    var friendInformation: User
    var friendMappingId: UUID
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(friendMappingId)
    }
    
    static func == (lhs: UserCellData, rhs: UserCellData) -> Bool {
        return lhs.friendMappingId == rhs.friendMappingId
    }
}

class PaymentCell: UICollectionViewCell {
    static let reuseIdentifier = "PaymentCell"
    
    @IBOutlet weak var iconBackGround: UIImageView!
    @IBOutlet weak var icon: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var type: UILabel!
    @IBOutlet weak var note: UILabel!
    @IBOutlet weak var bio: UILabel!
    
    var data: UserCellData!
    
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
        if let userInfor = data.friendInformation.avatar, let avatar = Int(userInfor) {
            icon.text = avatarLabels[avatar]
        }
        if let name = data.friendInformation.name {
            type.text = name
        }
        if let username = data.friendInformation.username {
            note.text = username
        }
        if let bio = data.friendInformation.bio {
            self.bio.text = bio
        }
    }
}
