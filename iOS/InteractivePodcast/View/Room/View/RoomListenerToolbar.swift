//
//  RoomMemberToolbar.swift
//  InteractivePodcast
//
//  Created by XUCH on 2021/3/11.
//

import Foundation
import UIKit
import RxSwift

class RoomListenerToolbar: UIView {
    weak var delegate: RoomController!
    let disposeBag = DisposeBag()
    
    var returnView: IconButton = {
       let view = IconButton()
        view.icon = "iconExit"
        view.label = "Leave quietly".localized
        return view
    }()
    
    var handsupView: IconButton = {
       let view = IconButton()
        view.icon = "iconHandsUp"
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(returnView)
        addSubview(handsupView)
        
        handsupView.height(constant: 36)
            .marginTrailing(anchor: trailingAnchor, constant: 16)
            .centerY(anchor: centerYAnchor)
            .active()
        
        returnView.height(constant: 36)
            .marginLeading(anchor: leadingAnchor, constant: 16)
            .centerY(anchor: centerYAnchor)
            .active()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func subcribeUIEvent() {
        handsupView.rx.tap
            .throttle(RxTimeInterval.seconds(2), scheduler: MainScheduler.instance)
            .flatMap { [unowned self] _ in
                self.delegate.viewModel.handsup()
            }
            .subscribe(onNext: { [unowned self] result in
                if (!result.success) {
                    self.delegate.show(message: result.message ?? "unknown error".localized, type: .error)
                } else {
                    self.delegate.show(message: "Request received. Please wait ...".localized, type: .info)
                }
            })
            .disposed(by: disposeBag)
        
        returnView.rx.tap
            .throttle(RxTimeInterval.seconds(2), scheduler: MainScheduler.instance)
            .flatMap { [unowned self] _ in
                self.delegate.viewModel.leaveRoom(action: .leave)
            }
            .filter { [unowned self] result in
                if (!result.success) {
                    self.delegate.show(message: result.message ?? "unknown error".localized, type: .error)
                }
                return result.success
            }
            .observe(on: MainScheduler.instance)
            .flatMap { [unowned self] _ in
                self.delegate.pop()
            }
            .subscribe(onNext: { [unowned self] result in
                self.delegate.leaveAction?(.leave, nil)
            })
            .disposed(by: disposeBag)
        
        self.delegate.viewModel.syncLocalUIStatus()
    }
    
    func onReceivedAction(_ result: Result<Action>) {
        if (!result.success) {
            Logger.log(message: result.message ?? "unknown error".localized, level: .error)
        } else {
            if let action = result.data {
                switch action.action {
                case .invite:
                    if (action.status == .ing) {
                        InvitedDialog().show(with: action, delegate: self.delegate)
                    }
                default:
                    Logger.log(message: "received action \(action.action)", level: .info)
                }
            }
        }
    }
    
    func subcribeRoomEvent() {}
}
