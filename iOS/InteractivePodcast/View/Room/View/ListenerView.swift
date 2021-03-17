//
//  MemberView.swift
//  InteractivePodcast
//
//  Created by XUCH on 2021/3/9.
//

import Foundation
import UIKit

class ListenerView: BaseUICollectionViewCell<Member> {
    fileprivate static let padding: CGFloat = 10
    fileprivate static let avatarWidth: CGFloat = 50
    
    weak var delegate: RoomControlDelegate?
    
    override var model: Member! {
        didSet {
            name.text = model.user.name
            avatar.image = UIImage(named: model.user.getLocalAvatar())
        }
    }
    
    var avatar: UIImageView = {
        let view = RoundImageView()
        return view
    }()
    
    var name: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 15)
        view.numberOfLines = 1
        view.textColor = UIColor(hex: Colors.White)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))))
        backgroundColor = .clear
        addSubview(avatar)
        addSubview(name)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func render() {
        avatar
            .width(constant: ListenerView.avatarWidth)
            .height(constant: ListenerView.avatarWidth)
            .marginLeading(anchor: leadingAnchor, constant: 30)
            .centerY(anchor: centerYAnchor)
            .active()
        name.marginLeading(anchor: avatar.trailingAnchor, constant: 10)
            .marginTrailing(anchor: trailingAnchor, constant: 30)
            .centerY(anchor: centerYAnchor)
            .active()
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        delegate?.onTap(member: model)
    }
    
    static func sizeForItem(width: CGFloat) -> CGSize {
        return CGSize(width: width, height: padding + avatarWidth + padding)
    }
}
