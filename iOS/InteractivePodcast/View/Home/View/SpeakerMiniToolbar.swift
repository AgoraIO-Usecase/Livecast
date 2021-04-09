//
//  SpeakerMiniToolbar.swift
//  InteractivePodcast
//
//  Created by XC on 2021/3/14.
//

import Foundation
import RxSwift
import UIKit
import RxCocoa

class SpeakerMiniToolbar: UIStackView {
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
            .subscribe(onNext: { [unowned self] result in
                self.delegate.dismiss()
                self.delegate.leaveAction?(.leave, nil)
            })
            .disposed(by: disposeBag)
        
        onMicView.rx.tap
            .throttle(RxTimeInterval.seconds(2), scheduler: MainScheduler.instance)
            .filter {
                return !self.delegate.viewModel.member.isMuted
            }
            .flatMap { [unowned self] _ in
                return self.delegate.viewModel.selfMute(mute: !self.delegate.viewModel.muted())
            }
            .subscribe(onNext: { [unowned self] result in
                if (!result.success) {
                    self.delegate.show(message: result.message ?? "unknown error".localized, type: .error)
                }
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
    
    func onReceivedAction(_ result: Result<Action>) {}
    func subcribeRoomEvent() {}
}
