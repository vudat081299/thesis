//
//  ProfileAvatarTableViewCell.swift
//  VegaPunk
//
//  Created by Dat Vu on 20/02/2023.
//

import UIKit
import Nuke

class ProfileAvatarTableViewCell: UITableViewCell {
    static let reuseIdentifier = "ProfileAvatarTableViewCell"

    @IBOutlet weak var avatarContainer: UIView!
    @IBOutlet weak var avatarImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        avatarImage.contentMode = .scaleAspectFill
        avatarImage.tintColor = .systemGray3
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func prepare(_ imageUrl: String?) {
        let placeholderImage = UIImage(systemName: "person.circle")
        let options = ImageLoadingOptions(
            placeholder: placeholderImage?.withTintColor(.systemGray2),
            transition: .fadeIn(duration: 0.5)
        )
        let urlString = QueryBuilder.queryInfomation(.downloadFile)!.genUrl() + (imageUrl ?? "")
        let url = URL(string: urlString)
        Nuke.loadImage(with: url!, options: options, into: avatarImage)
        avatarContainer.roundedBorder()
    }
}
