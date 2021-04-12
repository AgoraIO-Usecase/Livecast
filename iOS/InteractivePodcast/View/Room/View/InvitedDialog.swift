//
//  InvitedDialog.swift
//  InteractivePodcast
//
//  Created by XC on 2021/3/13.
//

import Foundation
import UIKit
import RxSwift

class InvitedDialog: Dialog {
    weak var delegate: RoomDelegate!
    var action: Action! {
        didSet {
            message.text = "\(self.delegate.viewModel.roomManager?.user.name ?? "") \("invite you to speak".localized)"
        }
    }
    
    var message: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 15)
        view.numberOfLines = 0
        view.textColor = UIColor(hex: Colors.White)
        return view
    }()
    
    var rejectButton: UIButton = {
        let view = RoundButton()
        view.borderColor = Colors.White
        view.setTitle("Decline".localized, for: .normal)
        view.setTitleColor(UIColor(hex: Colors.White), for: .normal)
        view.backgroundColor = .clear
        view.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        return view
    }()
    
    var agreeButton: UIButton = {
        let view = RoundButton()
        view.setTitle("Agree".localized, for: .normal)
        view.borderColor = Colors.Yellow
        view.setTitleColor(UIColor(hex: Colors.Black), for: .normal)
        view.backgroundColor = UIColor(hex: Colors.Yellow)
        view.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        return view
    }()
    
    override func setup() {
        addSubview(message)
        addSubview(rejectButton)
        addSubview(agreeButton)
        
        message.marginTop(anchor: topAnchor, constant: 16)
            .marginLeading(anchor: leadingAnchor, constant: 16)
            .centerX(anchor: centerXAnchor)
            .active()
        
        agreeButton.width(constant: 90)
            .height(constant: 36)
            .marginTrailing(anchor: trailingAnchor, constant: 16)
            .marginTop(anchor: message.bottomAnchor, constant: 16)
            .marginBottom(anchor: bottomAnchor, constant: 16)
            .active()
        
        rejectButton.width(constant: 90)
            .height(constant: 36)
            .marginTrailing(anchor: agreeButton.leadingAnchor, constant: 16)
            .marginTop(anchor: message.bottomAnchor, constant: 16)
            .marginBottom(anchor: bottomAnchor, constant: 16)
            .active()
        
        backgroundColor = UIColor(hex: "#4F576C")
        
        rejectButton.rx.tap
            .throttle(RxTimeInterval.seconds(2), scheduler: MainScheduler.instance)
            .flatMap { [unowned self] _ in
                return self.delegate.viewModel.process(action: self.action, agree: false)
            }
            .flatMap { [unowned self] result -> Observable<Result<Bool>> in
                return result.onSuccess {
                    return self.delegate.dismiss(dialog: self).asObservable().map { _ in Result(success: true) }
                }
            }
            .subscribe(onNext: { [unowned self] result in
                if (!result.success) {
                    self.delegate.show(message: result.message ?? "unknown error".localized, type: .error, duration: 1.5)
                }
            })
            .disposed(by: disposeBag)
        
        agreeButton.rx.tap
            .throttle(RxTimeInterval.seconds(2), scheduler: MainScheduler.instance)
            .flatMap { [unowned self] _ in
                return self.delegate.viewModel.process(action: self.action, agree: true)
            }
            .flatMap { [unowned self] result -> Observable<Result<Bool>> in
                return result.onSuccess {
                    return self.delegate.dismiss(dialog: self).asObservable().map { _ in Result(success: true) }
                }
            }
            .subscribe(onNext: { [unowned self] result in
                if (!result.success) {
                    self.delegate.show(message: result.message ?? "unknown error".localized, type: .error, duration: 1.5)
                }
            })
            .disposed(by: disposeBag)
    }
    
    override func render() {
        rounded(radius: 10)
        shadow()
    }
    
    func show(with action: Action, delegate: RoomDelegate) {
        self.delegate = delegate
        self.action = action
        self.show(controller: delegate, style: .top, padding: 16)
    }
}
