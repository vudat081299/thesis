//
//  ReusableFooter.swift
//  ExampleReusableViews
//
//  Created by Pablo Blanco Peris on 06/09/2019.
//  Copyright © 2019 Pablo Blanco Peris. All rights reserved.
//

// MARK: - This implementation work well for some version .xib only by mistake

//import UIKit
//
//class ChatBoxAvatarView: UIView {
//    let nibName = "ChatBoxAvatarView"
//
//    @IBOutlet weak var image: UIImageView!
//    @IBOutlet weak var icon: UILabel!
//
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        commonInit()
//    }
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        commonInit()
//    }
//
//    func commonInit() {
//        guard let view = loadViewFromNib() else { return }
//        view.frame = bounds
//        addSubview(view)
//    }
//
//    func loadViewFromNib() -> UIView? {
//        let nib = UINib(nibName: nibName, bundle: nil)
//        return nib.instantiate(withOwner: self, options: nil).first as? UIView
//    }
//}
