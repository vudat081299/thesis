//
//  ReusableUIView.swift
//  VegaPunk
//
//  Created by Dat Vu on 07/02/2023.
//

import UIKit

class ReusableUIView: UIView {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        
        // MARK: - Method 1 to reuse view.
//        if let nibsView = Bundle.main.loadNibNamed(String(describing: type(of: self)), owner: self, options: nil) as? [UIView] {
//            let rootNibView = nibsView[0]
//            self.addSubview(rootNibView)
//            rootNibView.frame = self.bounds
//        }
        
        // Method 2
        commonInit()
    }
    
    
    // MARK: - Method 2 to reuse view.
    func commonInit() {
        if let nibsView = Bundle.main.loadNibNamed(String(describing: type(of: self)), owner: self, options: nil)?[0] as? UIView {
            nibsView.fixInView(self)
        }
    }
}


// MARK: - Reusable custom UIView
extension UIView
{
    func fixInView(_ container: UIView!) -> Void{
        translatesAutoresizingMaskIntoConstraints = false
        frame = container.frame
        container.addSubview(self)
        NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: container, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: container, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
    }
}
