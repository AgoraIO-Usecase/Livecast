//
//  ListenerMiniToolbar.swift
//  InteractivePodcast
//
//  Created by XC on 2021/3/14.
//

import Foundation
import RxSwift
import UIKit
import RxCocoa

class ListenerMiniToolbar: UIStackView {
    weak var delegate: MiniRoomView!
    let disposeBag = DisposeBag()
    
    var handsupView: IconButton = {
        let view = IconButton()
        view.icon = "iconBlueHandsUp"
        view.style = .fill
        view.color = Colors.Yellow
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
        addArrangedSubview(handsupView)
    }
    
    required init(coder: NSCoder) {
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
                    self.delegate.show(message: result.message ?? "出错了！", type: .error)
                } else {
                    self.delegate.show(message: "你已举手，请等待房主回应", type: .info)
                }
            })
            .disposed(by: disposeBag)
        
        exitView.rx.tap
            .throttle(RxTimeInterval.seconds(2), scheduler: MainScheduler.instance)
            .flatMap { [unowned self] _ in
                self.delegate.viewModel.leaveRoom(action: .leave)
            }
            .filter { [unowned self] result in
                if (!result.success) {
                    self.delegate.show(message: result.message ?? "出错了！", type: .error)
                }
                return result.success
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] result in
                self.delegate.dismiss()
                self.delegate.leaveAction?(.leave, nil)
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
                    if (action.status == .ing) {
                        InvitedDialog().show(with: action, delegate: self.delegate)
                    }
                default:
                    Logger.log(message: "received action \(action.action)", level: .info)
                }
            }
        }
    }
    
    func subcribeRoomEvent() {
//        self.delegate.viewModel.actionsSource()
//            .observe(on: MainScheduler.instance)
//            .subscribe(onNext: { [unowned self] result in
//                
//            })
//            .disposed(by: disposeBag)
    }
}
