//
//  FirstMessContentCellForSection.swift
//  Social Messaging
//
//  Created by Dat vu on 22/04/2021.
//

import UIKit

class FirstMessContentCellForSection: UICollectionViewCell, UIScrollViewDelegate {
    static let reuseIdentifier = "FirstMessContentCellForSection"
    
    @IBOutlet weak var contentTextLabel: UILabel!
    @IBOutlet weak var contentImageContainerScrollView: UIScrollView!
    @IBOutlet weak var contentImageView: UIImageView!
    @IBOutlet weak var heightContentImageCS: NSLayoutConstraint!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var constraint: NSLayoutConstraint!
    @IBOutlet weak var backGroundView: UIView!
    
    @IBOutlet weak var senderName: UILabel!
    @IBOutlet weak var creationDate: UILabel!
    
    var delegate: MessagingViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        contentImageView.image = nil
        contentTextLabel.text = ""
        
        contentImageContainerScrollView.contentOffset = CGPoint(x: 100, y: 100)
        contentImageContainerScrollView.delegate = self
        contentImageContainerScrollView.minimumZoomScale = 1.0
        contentImageContainerScrollView.maximumZoomScale = 3.0
        contentImageContainerScrollView.zoomScale = 1.0
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        constraint.constant = 0
        contentImageContainerScrollView.zoomScale = 1.0
        contentImageView.image = nil
        heightContentImageCS.constant = 0
//        contentTextLabel.text = ""
        senderName.textColor = .systemOrange
    }
    
    override var isHighlighted: Bool {
        didSet {
            if self.isHighlighted {
                backgroundColor = .systemBackground
                // Your customized animation or add a overlay view
            } else {
                backgroundColor = .clear
                // Your customized animation or remove overlay view
            }
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentImageView
    }
    
    
    // MARK: - Tasks
    func prepare(_ message: Message) {
        creationDate.text = message.createdAt.toDate().iso8601StringShortDateTime
        timeLabel.text = message.createdAt.toDate().dayTime
        contentTextLabel.text = message.content
        guard let delegate = delegate else { return }
        if let user = delegate.user(message.sender!) {
            senderName.text = user.name
        }
        if delegate.checkIsSender(message.sender!) {
            senderName.textColor = .systemGreen
        }
    }
}
