//
//  ChatBoxMemberTableViewCell.swift
//  VegaPunk
//
//  Created by Dat Vu on 05/03/2023.
//

import UIKit

class ChatBoxMemberTableViewCell: UITableViewCell {
    static let reuseIdentifier = "ChatBoxMemberTableViewCell"

    @IBOutlet weak var avatarView: ChatBoxAvatarView!
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        avatarView.avatar.image = nil
        nameLabel.text = nil
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func prepare(with user: User? = nil) {
        guard let user = user else { return }
        avatarView.prepare(with: user.avatar, type: .single)
        nameLabel.text = user.name
    }
}
