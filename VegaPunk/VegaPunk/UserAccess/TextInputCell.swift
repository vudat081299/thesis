//
//  SignupInputCell.swift
//  Social Messaging
//
//  Created by Vũ Quý Đạt  on 19/05/2021.
//

import UIKit

class TextInputCell: UITableViewCell {
    static let reuseIdentifier = "TextInputCell"
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var inputTextField: UITextField!
    var indexPath: IndexPath?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
