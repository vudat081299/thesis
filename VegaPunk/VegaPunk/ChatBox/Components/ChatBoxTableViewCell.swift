//
//  ChatBoxTableViewCell.swift
//  Social Messaging
//
//  Created by Dat vu on 13/05/2021.
//

import UIKit


// MARK: - Definition
struct ChatBoxExtractedData: Hashable {
    let chatBox: ChatBox
    let members: [UUID]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(chatBox.id)
    }
    
    static func == (lhs: ChatBoxExtractedData, rhs: ChatBoxExtractedData) -> Bool {
        return lhs.chatBox.id == rhs.chatBox.id
    }
}

class ChatBoxTableViewCell: UITableViewCell {
    static let reuseIdentifier = "ChatBoxTableViewCell"
    // ChatBox() - members
    @IBOutlet weak var singleChatBoxAvatarContainer: UIView!
    @IBOutlet weak var firstAvatar: ChatBoxAvatarView!
    
    @IBOutlet weak var multipleChatBoxAvatarContainer: UIView!
    @IBOutlet weak var secondAvatar: ChatBoxAvatarView!
    @IBOutlet weak var thirdAvatar: ChatBoxAvatarView!
    
    @IBOutlet weak var name: UILabel! //
    @IBOutlet weak var id: UILabel! //
    @IBOutlet weak var lastestMesssage: UILabel!
    @IBOutlet weak var timeStampButton: UIButton!
    
    var data: ChatBoxExtractedData!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
    }
    
    
    // MARK: - Prepare
    func prepare(with chatBoxExtractedData: ChatBoxExtractedData? = nil) {
        data = chatBoxExtractedData
        let isSingleChatBox = data.members.count < 2
        let shouldHideSingleChatBox = !isSingleChatBox
        singleChatBoxAvatarContainer.isHidden = shouldHideSingleChatBox
        multipleChatBoxAvatarContainer.isHidden = !shouldHideSingleChatBox
        
        if isSingleChatBox {
            firstAvatar.prepare(with: <#T##ChatBoxAvatarView.AvatarType#>)
        } else {
            
        }
    }
}

