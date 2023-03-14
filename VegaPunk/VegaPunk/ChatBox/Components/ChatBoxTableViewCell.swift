//
//  ChatBoxTableViewCell.swift
//  Social Messaging
//
//  Created by Dat vu on 13/05/2021.
//

import UIKit


// MARK: - Definition
struct ChatBoxViewModel: Hashable {
    let chatBox: Chatbox
    var lastestMessage: ChatboxMessage?
    let members: [UUID]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(chatBox.id)
    }
    
    static func == (lhs: ChatBoxViewModel, rhs: ChatBoxViewModel) -> Bool {
        return lhs.chatBox.id == rhs.chatBox.id
    }
    
    static func > (lhs: ChatBoxViewModel, rhs: ChatBoxViewModel) -> Bool {
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
    @IBOutlet weak var newMessageFlag: UIView!
    @IBOutlet weak var lastestMesssage: UILabel!
    @IBOutlet weak var dayTime: UILabel!
    
    var data: ChatBoxViewModel!
    var delegate: ChatBoxViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        newMessageFlag.roundedBorder()
        newMessageFlag.isHidden = true
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        username.textColor = .systemGray2
        username.font = UIFont.systemFont(ofSize: 10, weight: .regular)
        lastestMesssage.textColor = .secondaryLabel
        lastestMesssage.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        newMessageFlag.isHidden = true
        firstAvatar.avatar.image = nil
        secondAvatar.avatar.image = nil
        thirdAvatar.avatar.image = nil
    }
    
    
    // MARK: - Prepare
    func prepare(with chatBoxExtractedData: ChatBoxViewModel? = nil) {
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
        
//        if isSingleChatBox {
//            firstAvatar.prepare(with: delegate. type: <#T##TypeAvatar#>)
//        }
    }
    
    func prepareTextIBOutlets() {
        guard let delegate = delegate else { return }
        let members = delegate.getMembersInChatBox(with: data.members)
        
        if members.count == 0 {
            let user = AuthenticatedUser.retrieve()?.data
            name.text = "Me"
            username.text = "@" + (user?.username ?? "")
            username.font = UIFont.systemFont(ofSize: 10, weight: .medium)
            username.textColor = .systemGreen
            firstAvatar.prepare(with: user?.avatar, type: .single)
        } else if members.count == 1 {
            let friend = members[0]
            name.text = friend.name
            username.text = "@" + (friend.username ?? "")
            firstAvatar.prepare(with: friend.avatar, type: .single)
        } else if members.count > 1 {
            let chatBoxName = data.chatBox.name
            let listMemberName = [members[0].name!, members[1].name!].sorted(by: >)
            
            name.text = (chatBoxName != nil && chatBoxName?.count != 0) ? chatBoxName : "\(listMemberName[0]), \(listMemberName[1])"
            username.text = ""
            secondAvatar.prepare(with: members[0].avatar, type: .multiple)
            thirdAvatar.prepare(with: members[1].avatar, type: .multiple)
        }
    }
    
    func prepareLastestMessage() {
        guard let lastestMessage = data.lastestMessage else { return }
        let chatBoxId = data.chatBox.id
        switch lastestMessage.mediaType {
        case .file:
            lastestMesssage.text = "An image 🌃"
            break
        default:
            lastestMesssage.text = lastestMessage.content
            break
        }
        let lastestSeenMessage = ChatboxMessage.retrieve(.lastestSeenMessage, with: chatBoxId)
        if lastestSeenMessage == nil ||
            lastestMessage > lastestSeenMessage! {
            lastestMesssage.textColor = .black
            lastestMesssage.font = UIFont.systemFont(ofSize: 12, weight: .bold)
            newMessageFlag.isHidden = false
        }
        let date = lastestMessage.createdAt.toDate()
        dayTime.text = date.weekDay + "\n" + date.dayTime
    }
}

