//
//  RoundImageView.swift
//  InteractivePodcast
//
//  Created by XUCH on 2021/3/10.
//

import Foundation
import UIKit

class RoundImageView: UIImageView {
    var color: String? = "#AA4E5E76"
    var borderWidth: CGFloat = 1
    
    override func layoutSubviews() {
        super.layoutSubviews()
        clipsToBounds = true
        rounded(color: color, borderWidth: borderWidth)
    }
}
