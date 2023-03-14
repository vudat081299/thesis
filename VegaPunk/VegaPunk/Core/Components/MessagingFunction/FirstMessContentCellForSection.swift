//
//  FirstMessContentCellForSection.swift
//  Social Messaging
//
//  Created by Dat vu on 22/04/2021.
//

import UIKit
import Nuke

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
        senderName.text = ""
        creationDate.text = ""
        timeLabel.text = ""
        
//        contentImageContainerScrollView.contentOffset = CGPoint(x: 100, y: 100)
//        contentImageContainerScrollView.delegate = self
//        contentImageContainerScrollView.minimumZoomScale = 1.0
//        contentImageContainerScrollView.maximumZoomScale = 3.0
//        contentImageContainerScrollView.zoomScale = 1.0
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        constraint.constant = 0
        heightContentImageCS.constant = 0
        contentImageContainerScrollView.zoomScale = 1.0
        senderName.textColor = .systemOrange
        resetCell()
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
    
    func resetCell() {
        contentImageView.image = nil
        contentTextLabel.text = ""
        senderName.text = ""
        creationDate.text = ""
        timeLabel.text = ""
    }
    
    
    // MARK: - Tasks
    func prepare(_ message: ChatboxMessage) {
        resetCell()
        timeLabel.text = message.createdAt.toDate().dayTime
        if message.mediaType == .file {
            let placeholderImage = UIImage()
            let options = ImageLoadingOptions(
                placeholder: placeholderImage.withTintColor(.systemGray2),
                transition: .fadeIn(duration: 0.5)
            )
            heightContentImageCS.constant = 240
            contentTextLabel.text = ""
            let query = QueryBuilder.queryInfomation(.downloadFile)
            let url = (query?.genUrl())! + message.content!
            guard let imageURL = URL(string: url) else { return }
            Nuke.loadImage(with: imageURL, options: options, into: contentImageView)
        } else {
            contentTextLabel.text = message.content
        }
    }
}
