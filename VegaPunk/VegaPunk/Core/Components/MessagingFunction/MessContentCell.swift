//
//  MessContentCell.swift
//  Social Messaging
//
//  Created by Vũ Quý Đạt  on 21/04/2021.
//

import UIKit
import Nuke

class MessContentCell: UICollectionViewCell, UIScrollViewDelegate {
    static let reuseIdentifier = "MessContentCell"
    
    @IBOutlet weak var contentTextLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var constraint: NSLayoutConstraint!
    @IBOutlet weak var heightImage: NSLayoutConstraint!
    @IBOutlet weak var contentImageView: UIImageView!
    @IBOutlet weak var contentImageContainerScrollView: UIScrollView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        contentImageView.image = nil
        contentImageView.contentMode = .scaleAspectFit
        contentImageView.tintColor = .systemGray3
        constraint.constant = 0
        heightImage.constant = 0
        contentTextLabel.text = ""
        timeLabel.text = ""
        
//        contentImageContainerScrollView.contentOffset = CGPoint(x: 100, y: 100)
//        contentImageContainerScrollView.delegate = self
//        contentImageContainerScrollView.minimumZoomScale = 1.0
//        contentImageContainerScrollView.maximumZoomScale = 3.0
//        contentImageContainerScrollView.zoomScale = 1.0
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        contentImageView.image = nil
        constraint.constant = 0
        heightImage.constant = 0
        contentTextLabel.text = ""
        timeLabel.text = ""
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
    
    
    // MARK: - Tasks
    func prepare(_ message: ChatboxMessage) {
        timeLabel.text = message.createdAt.toDate().dayTime
        if message.mediaType == .file {
            let placeholderImage = UIImage()
            let options = ImageLoadingOptions(
                placeholder: placeholderImage.withTintColor(.systemGray2),
                transition: .fadeIn(duration: 0.5)
            )
            heightImage.constant = 240
            contentTextLabel.text = ""
            let query = QueryBuilder.queryInfomation(.downloadFile)
            let url = (query?.genUrl())! + message.content!
            guard let imageURL = URL(string: url) else { return }
            Nuke.loadImage(with: imageURL, options: options, into: contentImageView)
        } else {
            contentTextLabel.text = message.content
        }
    }
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentImageView
    }
}
