//
//  InviteSpeakerDialog.swift
//  InteractivePodcast
//
//  Created by XC on 2021/3/13.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class InviteSpeakerDialog: Dialog {
    weak var delegate: RoomController!
    var model: Member! {
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
    
    var button: UIButton = {
        let view = RoundButton()
        view.borderColor = Colors.Yellow
        view.setTitle("Invite to speak".localized, for: .normal)
        view.setTitleColor(UIColor(hex: Colors.Black), for: .normal)
        view.backgroundColor = UIColor(hex: Colors.Yellow)
        view.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        return view
    }()
    
    override func setup() {
        backgroundColor = UIColor(hex: Colors.Black)
        addSubview(avatar)
        addSubview(name)
        addSubview(button)
        
        button.rx.tap
            .throttle(RxTimeInterval.seconds(2), scheduler: MainScheduler.instance)
            .flatMap { [unowned self] _ in
                return self.delegate.viewModel.inviteSpeaker(member: self.model)
            }
            .flatMap { [unowned self] result -> Observable<Result<Void>> in
                return result.onSuccess {
                    return self.delegate.dismiss(dialog: self).asObservable().map { _ in result }
                }
            }
            .subscribe(onNext: { [unowned self] result in
                if (!result.success) {
                    self.delegate.show(message: result.message ?? "unknown error".localized, type: .error)
                }
            })
            .disposed(by: disposeBag)
    }
    
    override func render() {
        roundCorners([.topLeft, .topRight], radius: 30)
        shadow()
        avatar.width(constant: 80)
            .height(constant: 80)
            .marginTop(anchor: topAnchor, constant: 30)
            .centerX(anchor: centerXAnchor)
            .active()
        
        name.marginTop(anchor: avatar.bottomAnchor, constant: 10)
            .marginLeading(anchor: leadingAnchor, constant: 20, relation: .greaterOrEqual)
            .centerX(anchor: centerXAnchor)
            .active()
        
        button.width(constant: 200)
            .height(constant: 36)
            .marginTop(anchor: name.bottomAnchor, constant: 15)
            .centerX(anchor: centerXAnchor)
            .marginBottom(anchor: bottomAnchor, constant: safeAreaInsets.bottom + 20)
            .active()
    }
    
    func show(with member: Member, delegate: RoomController) {
        self.delegate = delegate
        self.model = member
        self.show(controller: delegate)
    }
}
