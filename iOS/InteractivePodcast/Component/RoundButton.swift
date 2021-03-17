//
//  RoundButton.swift
//  InteractivePodcast
//
//  Created by XC on 2021/3/12.
//

import Foundation
import UIKit

class RoundButton: UIButton {
    
    var borderColor: String?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        rounded(color: borderColor, borderWidth: 1)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.alpha = 0.65
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.alpha = 1
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        self.alpha = 1
    }
}
