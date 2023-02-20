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
        avatarContainer.roundedBorder()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func prepare(_ imageUrl: String?) {
        let options = ImageLoadingOptions(
          placeholder: UIImage(systemName: "person"),
          transition: .fadeIn(duration: 0.5)
        )
        let query = QueryBuilder.queryInfomation(.downloadFile)
        guard let imageUrl = imageUrl else { return }
        let urlString = (query?.genUrl())! + imageUrl
        let url = URL(string: urlString)!
        Nuke.loadImage(with: url, options: options, into: avatarImage)
    }
}
