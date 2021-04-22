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
                return self.delegate.showAlert(title: "Leave room".localized, message: "Leaving the room ends the session and removes everyone".localized)
            }
            .filter { close in
                return close
            }
            .flatMap { [unowned self] _ in
                return self.delegate.viewModel.leaveRoom(action: .leave)
            }
            .filter { [unowned self] result in
                if (!result.success) {
                    self.delegate.show(message: result.message ?? "unknown error".localized, type: .error)
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
            .debounce(RxTimeInterval.microseconds(300), scheduler: MainScheduler.instance)
            .throttle(RxTimeInterval.seconds(1), scheduler: MainScheduler.instance)
            .flatMap { [unowned self] _ in
                return self.delegate.viewModel.selfMute(mute: !self.delegate.viewModel.muted())
            }
            .subscribe(onNext: { [unowned self] result in
                if (!result.success) {
                    self.delegate.show(message: result.message ?? "unknown error".localized, type: .error)
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
            Logger.log(message: result.message ?? "unknown error".localized, level: .error)
        } else {
            if let action = result.data {
                switch action.action {
                case .invite:
                    if (action.status == .refuse) {
                        self.delegate.show(message: "\(action.member.user.name) \("declines your request".localized)", type: .error)
                    }
                default:
                    Logger.log(message: "\(action.member.user.name)", level: .info)
                }
            }
        }
    }
    
    func subcribeRoomEvent() {
        self.delegate.viewModel.onHandsupListChange
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] list in
                self.handsupNoticeView.count = list.count
            })
            .disposed(by: disposeBag)
    }
}
