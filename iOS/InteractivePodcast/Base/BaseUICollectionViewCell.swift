//
//  BaseUICollectionViewCell.swift
//  InteractivePodcast
//
//  Created by XUCH on 2021/3/11.
//

import Foundation
import UIKit

class BaseUICollectionViewCell<T>: UICollectionViewCell {
    
    var model: T!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        render()
    }
    
    func render() {}
}
