//
//  ChatBoxAvatarView.swift
//  VegaPunk
//
//  Created by Dat Vu on 07/02/2023.
//

import UIKit

/**
 - Note: Very `confuse` that it's work even when set File's Owner class in .xib is `ReusableUIView`instead of `ChatBoxAvatarView`
 */
class ChatBoxAvatarView: ReusableUIView {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    let defaultEmoji = "😄"
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func prepare(with text: String) {
        if text.count > 1 {
            
        } else {
            label.text = text.first?.description
        }
    }
}
