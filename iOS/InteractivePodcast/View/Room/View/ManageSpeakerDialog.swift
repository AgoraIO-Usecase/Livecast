//
//  ManageSpeakerDialog.swift
//  InteractivePodcast
//
//  Created by XC on 2021/3/13.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class ManageSpeakerDialog: Dialog {
    weak var delegate: RoomController!
    var model: Member! {
        didSet {
            name.text = model.user.name
            avatar.image = UIImage(named: model.user.getLocalAvatar())
            if (model.isMuted) {
                closeMicButton.setTitle(model.isMuted ? "打开麦克风" : "关闭麦克风", for: .normal)
            }
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
    
    var kickButton: UIButton = {
        let view = RoundButton()
        view.borderColor = "#AA4E5E76"
        view.setTitle("下台", for: .normal)
        view.setTitleColor(UIColor(hex: Colors.White), for: .normal)
        view.backgroundColor = .clear
        view.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        return view
    }()
    
    var closeMicButton: UIButton = {
        let view = RoundButton()
        view.borderColor = "#AA4E5E76"
        view.setTitle("关闭麦克风", for: .normal)
        view.setTitleColor(UIColor(hex: Colors.White), for: .normal)
        view.backgroundColor = .clear
        view.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        return view
    }()
    
    override func setup() {
        backgroundColor = UIColor(hex: Colors.Black)
        
        addSubview(avatar)
        addSubview(name)
        addSubview(kickButton)
        addSubview(closeMicButton)
        
        kickButton.rx.tap
            .throttle(RxTimeInterval.seconds(2), scheduler: MainScheduler.instance)
            .flatMap { [unowned self] _ in
                return self.delegate.viewModel.kickSpeaker(member: self.model)
            }
            .flatMap { [unowned self] result -> Observable<Result<Bool>> in
                return result.onSuccess {
                    return self.delegate.dismiss(dialog: self).asObservable().map { _ in Result(success: true) }
                }
            }
            .subscribe(onNext: { [unowned self] result in
                if (!result.success) {
                    self.delegate.show(message: result.message ?? "出错了！", type: .error)
                }
            })
            .disposed(by: disposeBag)
        
        closeMicButton.rx.tap
            .throttle(RxTimeInterval.seconds(2), scheduler: MainScheduler.instance)
            .flatMap { [unowned self] _ -> Observable<Result<Void>> in
                if (self.model.isMuted) {
                    return self.delegate.viewModel.unMuteSpeaker(member: self.model)
                } else {
                    return self.delegate.viewModel.muteSpeaker(member: self.model)
                }
            }
            .flatMap { [unowned self] result -> Observable<Result<Void>> in
                return result.onSuccess {
                    return self.delegate.dismiss(dialog: self).asObservable().map { _ in result }
                }
            }
            .subscribe(onNext: { [unowned self] result in
                if (!result.success) {
                    self.delegate.show(message: result.message ?? "出错了！", type: .error)
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
        
        kickButton.width(constant: 200)
            .height(constant: 36)
            .marginTop(anchor: name.bottomAnchor, constant: 15)
            .centerX(anchor: centerXAnchor)
            .active()
        
        closeMicButton.width(constant: 200)
            .height(constant: 36)
            .marginTop(anchor: kickButton.bottomAnchor, constant: 15)
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

