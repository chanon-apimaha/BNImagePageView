//
//  aaa.swift
//  BNImagePageView
//
//  Created by Banchai Nangpang on 19/2/2562 BE.
//

import UIKit

public class ImgaePageData {
     var atIndex: IndexPath = []
     var sImageUrl: String = ""
     var fWidth: CGFloat = 0.0
     var fHeight: CGFloat = 0.0
    
    init(atIndex: IndexPath, sImageUrl: String, fWidth: CGFloat, fHeight: CGFloat) {
        self.atIndex = atIndex
        self.sImageUrl = sImageUrl
        self.fWidth = fWidth
        self.fHeight = fHeight
    }
}
