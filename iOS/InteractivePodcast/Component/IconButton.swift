//
//  IconButton.swift
//  InteractivePodcast
//
//  Created by XUCH on 2021/3/11.
//

import Foundation
import UIKit

class IconButton: UIButton {
    
    enum Style {
        case fill
        case stroke
    }
    
    var style: Style = .stroke
    var color: String = "#23FFFFFF"
    
    var icon: String! {
        didSet {
            _icon.image = UIImage(named: icon)
        }
    }
    
    var label: String? {
        didSet {
            _label.text = label
        }
    }
    
    var count: Int? {
        didSet {
            if (count != nil && count! > 0) {
                _count.text = String(count!)
                _count.isHidden = false
            } else {
                _count.text = nil
                _count.isHidden = true
            }
        }
    }
    
    private var _icon: UIImageView = {
       let view = UIImageView()
        
        return view
    }()
    
    private lazy var _label: UILabel = {
       let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 15)
        view.numberOfLines = 1
        view.textColor = UIColor(hex: Colors.White)
        return view
    }()
    
    private lazy var _count: UILabel = {
        let view = RoundLabelView()
        view.font = UIFont.systemFont(ofSize: 9)
        view.numberOfLines = 1
        view.textColor = UIColor(hex: Colors.White)
        view.backgroundColor = UIColor(hex: Colors.Red)
        view.textAlignment = .center
        return view
     }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        switch style {
        case .fill:
            backgroundColor = UIColor(hex: color)
            rounded(color: color)
        default:
            backgroundColor = .clear
            rounded(color: color, borderWidth: 1)
        }
        addSubview(_icon)
        if (label?.isEmpty == false) {
            addSubview(_label)
            _icon.removeAllConstraints()
            _icon.width(constant: bounds.height)
                .height(constant: bounds.height)
                .marginLeading(anchor: leadingAnchor, constant: 10)
                .centerY(anchor: centerYAnchor)
                .active()
            _label.marginLeading(anchor: _icon.trailingAnchor, constant: 0)
                .centerY(anchor: centerYAnchor)
                .marginTrailing(anchor: trailingAnchor, constant: 15)
                .active()
        } else {
            _icon.removeAllConstraints()
            width(constant: bounds.height)
                .height(constant: bounds.height)
                .active()
            
            _icon.width(constant: bounds.height)
                .height(constant: bounds.height)
                .centerX(anchor: centerXAnchor)
                .centerY(anchor: centerYAnchor)
                .active()
        }
        
        addSubview(_count)
        _count.height(constant: _count.font.lineHeight + 2)
            .centerX(anchor: trailingAnchor, constant: -3)
            .centerY(anchor: topAnchor, constant: 3)
            .active()
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
