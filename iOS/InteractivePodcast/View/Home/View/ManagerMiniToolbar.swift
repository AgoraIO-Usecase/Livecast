//
//  ManagerMiniToolbar.swift
//  InteractivePodcast
//
//  Created by XC on 2021/3/14.
//

import Foundation
import RxSwift
import UIKit
import RxCocoa

class ManagerMiniToolbar: UIStackView {
    weak var delegate: MiniRoomView!
    let disposeBag = DisposeBag()
    
    var isMuted: Bool = false {
        didSet {
            onMicView.icon = isMuted ? "redMic" : "iconMicOn"
        }
    }
    
    var onMicView: IconButton = {
        let view = IconButton()
        view.icon = "iconMicOn"
        view.style = .fill
        view.color = "#364151"
        view.width(constant: MiniRoomView.ICON_WIDTH)
            .height(constant: MiniRoomView.ICON_WIDTH)
            .active()
        return view
    }()
    
    var handsupNoticeView: IconButton = {
        let view = IconButton()
        view.icon = "iconUpNotice"
        view.style = .fill
        view.color = "#364151"
        view.width(constant: MiniRoomView.ICON_WIDTH)
            .height(constant: MiniRoomView.ICON_WIDTH)
            .active()
        return view
    }()
    
    var exitView: IconButton = {
        let view = IconButton()
        view.icon = "iconExit"
        view.style = .fill
        view.color = "#364151"
        view.width(constant: MiniRoomView.ICON_WIDTH)
            .height(constant: MiniRoomView.ICON_WIDTH)
            .active()
        return view
    }()
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        spacing = 16
        addArrangedSubview(exitView)
        addArrangedSubview(handsupNoticeView)
        addArrangedSubview(onMicView)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func subcribeUIEvent() {
        exitView.rx.tap
            .throttle(RxTimeInterval.seconds(2), scheduler: MainScheduler.instance)
            .concatMap { [unowned self] _ in
                return self.delegate.showAlert(title: "离开房间", message: "离开房间后，所有成员将被移出房间\n房间将关闭")
            }
            .filter { close in
                return close
            }
            .flatMap { [unowned self] _ in
                return self.delegate.viewModel.leaveRoom(action: .leave)
            }
            .filter { [unowned self] result in
                if (!result.success) {
                    self.delegate.show(message: result.message ?? "出错了！", type: .error)
                }
                return result.success
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] _ in
                self.delegate.dismiss()
                self.delegate.leaveAction?(.leave, self.delegate.viewModel.room)
            })
            .disposed(by: disposeBag)
        
        onMicView.rx.tap
            .throttle(RxTimeInterval.seconds(2), scheduler: MainScheduler.instance)
            .flatMap { [unowned self] _ in
                return self.delegate.viewModel.selfMute(mute: !self.delegate.viewModel.muted())
            }
            .subscribe(onNext: { [unowned self] result in
                if (!result.success) {
                    self.delegate.show(message: result.message ?? "出错了！", type: .error)
                }
            })
            .disposed(by: disposeBag)
        
        handsupNoticeView.rx.tap
            .throttle(RxTimeInterval.seconds(2), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] _ in
                HandsupListDialog().show(delegate: self.delegate)
            })
            .disposed(by: disposeBag)
        
        self.delegate.viewModel.isMuted
            .startWith(self.delegate.viewModel.muted())
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] muted in
                self.isMuted = muted
            })
            .disposed(by: disposeBag)
        
        self.delegate.viewModel.syncLocalUIStatus()
    }
    
    func onReceivedAction(_ result: Result<Action>) {
        if (!result.success) {
            Logger.log(message: result.message ?? "出错了！", level: .error)
        } else {
            if let action = result.data {
                switch action.action {
                case .invite:
                    if (action.status == .refuse) {
                        self.delegate.show(message: "\(action.member.user.name) 拒绝了你的上台邀请", type: .error)
                    }
                default:
                    Logger.log(message: "\(action.member.user.name)", level: .info)
                }
            }
        }
    }
    
    func subcribeRoomEvent() {
//        actionDisposable = self.delegate.viewModel.actionsSource()
//            .observe(on: MainScheduler.instance)
//            .subscribe(onNext: { [unowned self] result in
//                if (!result.success) {
//                    Logger.log(message: result.message ?? "出错了！", level: .error)
//                } else {
//                    if let action = result.data {
//                        switch action.action {
//                        case .invite:
//                            if (action.status == .refuse) {
//                                self.delegate.show(message: "\(action.member.user.name) 拒绝了你的上台邀请", type: .error)
//                            }
//                        default:
//                            Logger.log(message: "\(action.member.user.name)", level: .info)
//                        }
//                    }
//                }
//            })
        
        self.delegate.viewModel.onHandsupListChange
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] list in
                self.handsupNoticeView.count = list.count
            })
            .disposed(by: disposeBag)
    }
}
