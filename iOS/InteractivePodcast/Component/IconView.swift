//
//  IconView.swift
//  InteractivePodcast
//
//  Created by XUCH on 2021/3/10.
//

import Foundation
import UIKit

class IconView: UIView {
    fileprivate static let insets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)

    override func layoutSubviews() {
        super.layoutSubviews()
        rounded(color: "#23FFFFFF", borderWidth: 1)
    }
}
