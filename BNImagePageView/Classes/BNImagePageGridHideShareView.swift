//
//  FinFinViewController.swift
//  BNImagePageView_Example
//
//  Created by Banchai on 8/11/2562 BE.
//  Copyright © 2562 CocoaPods. All rights reserved.
//

import UIKit

class BNImagePageGridHideShareView: BNImagePageGridView {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mButtonClose.setImage(BNSetting.closeImage, for: .normal)
        self.mButtonClose.tintColor = .white
        self.mButtonClose.contentEdgeInsets = UIEdgeInsets(top: 5,left: 5,bottom: 5,right: 5)
        self.mButtonClose.backgroundColor = .clear//UIColor.black.withAlphaComponent(0.6)
        
//        self.mButtonShare.setImage(UIImage(named:"icon-home")?.withRenderingMode(.alwaysTemplate), for: .normal)
//        self.mButtonShare.tintColor = .white
//        self.mButtonShare.clipsToBounds = true
        self.mButtonShare.backgroundColor = .clear
//        self.setPageTitle()
//        self.mPageTitle.setTitle("1000", for: .normal)
    }
    
    override func handleOneTapScrollView(recognizer: UITapGestureRecognizer) {
        self.toggleBuutonCloseAndShareFinFIn()
    }

}



// Helper function inserted by Swift 4.2 migrator.
//fileprivate func convertFromUIPageViewControllerOptionsKey(_ input: UIPageViewController.OptionsKey) -> String {
//    return input.rawValue
//}
