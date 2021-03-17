//
//  HomeCardView.swift
//  InteractivePodcast
//
//  Created by XUCH on 2021/3/4.
//

import UIKit
import RxSwift
import RxCocoa

protocol HomeCardDelegate: class {
    func onTapCard(with room: Room)
}

final class HomeCardView: UICollectionViewCell {
    fileprivate static let padding: CGFloat = 16
    fileprivate static let lineSpacing: CGFloat = 5
    fileprivate static let font = UIFont.systemFont(ofSize: 16)
    fileprivate static let lineHeight: CGFloat = 26.5
    
    fileprivate let onRoomChanged: PublishRelay<Room> = PublishRelay()
    weak var delegate: HomeCardDelegate?
    let disposeBag = DisposeBag()
    
    var room: Room! {
        didSet {
            //title.text = room.channelName
            let style = NSMutableParagraphStyle()
            style.lineSpacing = HomeCardView.lineSpacing
            let attributes = [
                NSAttributedString.Key.font: HomeCardView.font,
                NSAttributedString.Key.paragraphStyle: style
            ]
            title.attributedText = NSAttributedString(string: room.channelName, attributes: attributes)
            
            label.text = "   \(room.total) / \(room.speakersTotal)"
            onRoomChanged.accept(room)
        }
    }
    
    var avatar0: AvatarView = {
        let view = AvatarView()
        return view
    }()
    
    var avatar1: AvatarView = {
        let view = AvatarView()
        return view
    }()
    
    var avatar2: AvatarView = {
        let view = AvatarView()
        return view
    }()
    
    private func renderAvatars(speakers: Int, anchor: NSLayoutYAxisAnchor) {
        let count = min(3, speakers)
        let avatars = [avatar0, avatar1, avatar2]
        avatars.forEach { avatar in
            avatar.removeFromSuperview()
        }
        if (count < 1) {
            return
        }
        let users = room.coverCharacters
        for index in 1...count {
            let _index = count - index
            let avatar = avatars[_index]
            addSubview(avatars[_index])
            if (_index < users.count) {
                avatar.name.text = users[_index].name
                avatar.avatar.image = UIImage(named: users[_index].getLocalAvatar())
            } else {
                avatar.name.text = ""
                avatar.avatar.image = UIImage(named: "default")
            }
            
            avatar.height(constant: MiniRoomView.ICON_WIDTH)
                .marginTop(anchor: anchor, constant: MiniRoomView.ICON_WIDTH * CGFloat(_index) * 0.8 + 10)
                .marginLeading(anchor: leadingAnchor, constant: HomeCardView.padding)
                .marginTrailing(anchor: trailingAnchor, constant: HomeCardView.padding)
                .active()
//            if (index == 1) {
//                avatar.marginBottom(anchor: bottomAnchor, constant: 16, relation: .greaterOrEqual)
//                    .active()
//            }
        }
    }
    
    var title: UILabel = {
        let view = UILabel()
        view.textColor = UIColor(hex: Colors.White)
        view.numberOfLines = 2
        return view
    }()
    
    private var label: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 13)
        view.numberOfLines = 1
        view.textColor = UIColor(hex: Colors.White)
        view.text = " 0 / 0"
        view.backgroundColor = UIColor(hex: Colors.Blue)
        return view
    }()
    
    private var icon: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "blueBroadcaster")
        view.backgroundColor = UIColor(hex: Colors.Blue)
        view.width(constant: 16)
            .height(constant: 16)
            .active()
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(hex: Colors.Blue)
        addSubview(title)
        addSubview(icon)
        addSubview(label)

        title.marginTop(anchor: topAnchor, constant: HomeCardView.padding)
            .marginLeading(anchor: leadingAnchor, constant: HomeCardView.padding)
            .centerX(anchor: centerXAnchor)
            .active()
        
        icon.marginTrailing(anchor: trailingAnchor, constant: HomeCardView.padding)
            .marginTop(anchor: topAnchor, constant: HomeCardView.padding + HomeCardView.lineHeight)
            .active()
        
        label.marginTrailing(anchor: icon.leadingAnchor, constant: 5)
            .height(constant: 16)
            .centerY(anchor: icon.centerYAnchor)
            .active()
        
        let tap = UITapGestureRecognizer()
        addGestureRecognizer(tap)
        tap.rx.event
            .throttle(RxTimeInterval.seconds(2), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] _ in
                self.delegate?.onTapCard(with: room)
            })
            .disposed(by: disposeBag)
        
        onRoomChanged
            .distinctUntilChanged()
            .flatMap { room in
                return room.getCoverSpeakers()
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] result in
                if (result.success) {
                    if let list = result.data {
                        list.forEach { member in
                            Logger.log(message: member.user.name, level: .info)
                        }
                        if (list.count != 0) {
                            self.room.coverCharacters.removeAll()
                            self.room.coverCharacters.append(contentsOf: list.map { $0.user })
                            self.layoutIfNeeded()
                            self.setNeedsLayout()
                        }
                    }
                }
            })
            .disposed(by: disposeBag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        rounded(radius: 10)
        renderAvatars(speakers: room.coverCharacters.count, anchor: label.bottomAnchor)
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
    
    class AvatarView: UIView {
        var avatar: UIImageView = {
            let view = RoundImageView()
            view.color = nil
            view.borderWidth = 0
            view.image = UIImage(named: "default")
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
            backgroundColor = .clear
            addSubview(avatar)
            addSubview(name)
            
            avatar
                .width(constant: MiniRoomView.ICON_WIDTH)
                .height(constant: MiniRoomView.ICON_WIDTH)
                .marginLeading(anchor: leadingAnchor)
                .centerY(anchor: centerYAnchor)
                .active()
            name.marginLeading(anchor: avatar.trailingAnchor, constant: 10)
                .marginTrailing(anchor: trailingAnchor)
                .centerY(anchor: centerYAnchor)
                .active()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    static func sizeForItem(room: Room, width: CGFloat) -> CGSize {
        let count: CGFloat = CGFloat(room.speakersTotal <= 0 ? 1 : room.speakersTotal)
        let height = padding + font.lineHeight + lineSpacing + lineHeight + 10 + MiniRoomView.ICON_WIDTH * count * 0.8 + padding
        return CGSize(width: width, height: height)
    }
}
