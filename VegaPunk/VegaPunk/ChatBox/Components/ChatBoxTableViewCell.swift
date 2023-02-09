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
    var lastestMessage: Message?
    let members: [UUID]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(chatBox.id)
    }
    
    static func == (lhs: ChatBoxExtractedData, rhs: ChatBoxExtractedData) -> Bool {
        return lhs.chatBox.id == rhs.chatBox.id
    }
    
    static func > (lhs: ChatBoxExtractedData, rhs: ChatBoxExtractedData) -> Bool {
        if let lhsLastestMessage = lhs.lastestMessage,
           let rhsLastestMessage = rhs.lastestMessage {
            return lhsLastestMessage > rhsLastestMessage
        }
        return false
    }
}

class ChatBoxTableViewCell: UITableViewCell {
    static let reuseIdentifier = "ChatBoxTableViewCell"
    
    @IBOutlet weak var singleChatBoxAvatarContainer: UIView!
    @IBOutlet weak var firstAvatar: ChatBoxAvatarView!
    
    @IBOutlet weak var multipleChatBoxAvatarContainer: UIView!
    @IBOutlet weak var secondAvatar: ChatBoxAvatarView!
    @IBOutlet weak var thirdAvatar: ChatBoxAvatarView!
    
    @IBOutlet weak var name: UILabel! //
    @IBOutlet weak var username: UILabel! //
    @IBOutlet weak var lastestMesssage: UILabel!
    @IBOutlet weak var dayTime: UILabel!
    
    var data: ChatBoxExtractedData!
    var delegate: ChatBoxViewController?
    
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
        guard let validateData = chatBoxExtractedData else { return }
        data = validateData
        
        prepareAvatar()
        prepareTextIBOutlets()
        prepareLastestMessage()
    }
    
    func prepareAvatar() {
        let isSingleChatBox = data.members.count < 2
        let shouldHideSingleChatBox = !isSingleChatBox
        singleChatBoxAvatarContainer.isHidden = shouldHideSingleChatBox
        multipleChatBoxAvatarContainer.isHidden = !shouldHideSingleChatBox
    }
    
    func prepareTextIBOutlets() {
        guard let delegate = delegate else { return }
        let members = delegate.getMembersInChatBox(with: data.members)
        if members.count == 0 {
            let user = AuthenticatedUser.retrieve()?.data
            name.text = data.chatBox.name
            username.text = "@" + (user?.username ?? "")
            firstAvatar.prepare(with: user?.avatar, type: .single)
        } else if members.count == 1 {
            name.text = members[0].name
            username.text = "@" + (members[0].username ?? "")
            firstAvatar.prepare(with: members[0].avatar, type: .single)
        } else if members.count > 1 {
            name.text = data.chatBox.name
            username.text = ""
            secondAvatar.prepare(with: members[0].avatar, type: .multiple)
            thirdAvatar.prepare(with: members[1].avatar, type: .multiple)
        }
    }
    
    func prepareLastestMessage() {
        guard let lastestMessage = data.lastestMessage else { return }
        switch lastestMessage.mediaType {
        case .text:
            lastestMesssage.text = lastestMessage.content
        case .notify:
            lastestMesssage.text = lastestMessage.content
        default:
            break
        }
        let date = lastestMessage.createdAt.toDate()
        dayTime.text = date.weekDay + "\n" + date.dayTime
    }
}

