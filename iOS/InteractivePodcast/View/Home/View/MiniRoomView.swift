//
//  MiniRoomView.swift
//  InteractivePodcast
//
//  Created by XC on 2021/3/14.
//

import Foundation
import UIKit
import RxSwift

class MiniRoomView: Dialog {
    weak var delegate: HomeController!
    var leaveAction: ((LeaveRoomAction, Room?) -> Void)? = nil
    static var ICON_WIDTH: CGFloat = 36
    var viewModel: RoomViewModel = RoomViewModel()
    
    private var avatar0: UIImageView = {
        let view = RoundImageView()
        view.width(constant: ICON_WIDTH)
            .height(constant: ICON_WIDTH)
            .active()
        return view
    }()
    
    private var avatar1: UIImageView = {
        let view = RoundImageView()
        view.width(constant: ICON_WIDTH)
            .height(constant: ICON_WIDTH)
            .active()
        return view
    }()
    
    private var avatar2: UIImageView = {
        let view = RoundImageView()
        view.width(constant: ICON_WIDTH)
            .height(constant: ICON_WIDTH)
            .active()
        return view
    }()
    
    private var label: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 13)
        view.numberOfLines = 1
        view.textColor = UIColor(hex: Colors.White)
        view.text = "0 / 0"
        return view
    }()
    
    private var icon: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "blueBroadcaster")
        view.width(constant: 16)
            .height(constant: 16)
            .active()
        return view
    }()
    
    private var stackView: UIView = {
        let view = UIView()
        return view
    }()
    
    private var managerToolbar: ManagerMiniToolbar? = nil
    private var speakerMiniToolbar: SpeakerMiniToolbar? = nil
    private var listenerMiniToolbar: ListenerMiniToolbar? = nil
    
    private var dataSourceDisposable: Disposable? = nil
    private var actionDisposable: Disposable? = nil
    
    private func renderAvatars(speakers: Int) -> UIView? {
        let count = min(3, speakers)
        let avatars = [avatar0, avatar1, avatar2]
        avatars.forEach { avatar in
            avatar.removeFromSuperview()
        }
        if (count < 1) {
            return nil
        }
        let users = viewModel.coverCharacters
        var view: UIView? = nil
        for index in 1...count {
            let _index = count - index
            let avatar = avatars[_index]
            addSubview(avatars[_index])
            if (_index < users.count) {
                avatar.image = UIImage(named: users[_index].getLocalAvatar())
            } else {
                avatar.image = nil
            }
            avatar.marginLeading(anchor: leadingAnchor, constant: MiniRoomView.ICON_WIDTH * CGFloat(_index) * 0.8 + 10)
                .centerY(anchor: centerYAnchor)
                .active()
            if (index == 1) {
                view = avatar
            }
        }
        return view
    }
    
    override func setup() {
        viewModel = RoomViewModel()
        let tap = UITapGestureRecognizer()
        addGestureRecognizer(tap)
        tap.rx.event
            .throttle(RxTimeInterval.seconds(2), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] _ in
                self.delegate.onTapCard(with: self.viewModel.room)
            })
            .disposed(by: disposeBag)
        
        dataSourceDisposable?.dispose()
        dataSourceDisposable = viewModel.roomMembersDataSource()
            .flatMap { [unowned self] result -> Observable<Result<Bool>> in
                let roomClosed = result.data
                if (roomClosed == true) {
                    return self.viewModel.leaveRoom(action: .leave).map { _ in return result }
                } else {
                    return Observable.just(result)
                }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] result in
                let roomClosed = result.data
                if (!result.success) {
                    self.delegate.show(message: result.message ?? "出错了！", type: .error)
                } else if (roomClosed == true) {
                    self.dismiss(controller: self.delegate)
                } else {
                    self.label.text = "\(self.viewModel.count) / \(self.viewModel.speakersCount)"
                    self.renderToolbar()
                }
            })
        
        actionDisposable = viewModel.actionsSource()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] result in
                switch self.viewModel.role {
                case .manager:
                    managerToolbar?.onReceivedAction(result)
                case .speaker:
                    speakerMiniToolbar?.onReceivedAction(result)
                case .listener:
                    listenerMiniToolbar?.onReceivedAction(result)
                }
            })
    }
    
    func disconnect() {
        dataSourceDisposable?.dispose()
        dataSourceDisposable = nil
        actionDisposable?.dispose()
        actionDisposable = nil
    }
    
    private func renderToolbar() {
        Logger.log(message: "renderToolbar role:\(viewModel.role)", level: .info)
        switch viewModel.role {
        case .manager:
            if (managerToolbar == nil) {
                managerToolbar = ManagerMiniToolbar()
                stackView.addSubview(managerToolbar!)
                managerToolbar!.fill(view: stackView).active()
                managerToolbar!.delegate = self
                
                if (speakerMiniToolbar != nil || listenerMiniToolbar != nil) {
                    speakerMiniToolbar?.removeFromSuperview()
                    speakerMiniToolbar = nil
                    listenerMiniToolbar?.removeFromSuperview()
                    listenerMiniToolbar = nil
                }
                
                managerToolbar!.subcribeUIEvent()
                managerToolbar!.subcribeRoomEvent()
            }
        case .speaker:
            if (speakerMiniToolbar == nil) {
                speakerMiniToolbar = SpeakerMiniToolbar()
                stackView.addSubview(speakerMiniToolbar!)
                speakerMiniToolbar!.fill(view: stackView).active()
                speakerMiniToolbar!.delegate = self
                
                if (managerToolbar != nil || listenerMiniToolbar != nil) {
                    managerToolbar?.removeFromSuperview()
                    managerToolbar = nil
                    listenerMiniToolbar?.removeFromSuperview()
                    listenerMiniToolbar = nil
                }
                
                speakerMiniToolbar!.subcribeUIEvent()
                speakerMiniToolbar!.subcribeRoomEvent()
            }
        case .listener:
            if (listenerMiniToolbar == nil) {
                listenerMiniToolbar = ListenerMiniToolbar()
                stackView.addSubview(listenerMiniToolbar!)
                listenerMiniToolbar!.fill(view: stackView).active()
                listenerMiniToolbar!.delegate = self
                
                if (managerToolbar != nil || speakerMiniToolbar != nil) {
                    managerToolbar?.removeFromSuperview()
                    managerToolbar = nil
                    speakerMiniToolbar?.removeFromSuperview()
                    speakerMiniToolbar = nil
                }
                
                listenerMiniToolbar!.subcribeUIEvent()
                listenerMiniToolbar!.subcribeRoomEvent()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(hex: "#4E586A")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func render() {
        rounded()
        shadow()
        let avatar = renderAvatars(speakers: max(self.viewModel.speakersCount, 1))
        addSubview(label)
        if let avatar = avatar {
            label.removeAllConstraints()
            label.marginLeading(anchor: avatar.trailingAnchor, constant: 16)
                .centerY(anchor: centerYAnchor)
                .active()
        } else {
            label.removeAllConstraints()
            label.marginLeading(anchor: leadingAnchor, constant: 10)
                .centerY(anchor: centerYAnchor)
                .active()
        }

        addSubview(icon)
        icon.marginLeading(anchor: label.trailingAnchor)
            .centerY(anchor: centerYAnchor)
            .active()
        
        addSubview(stackView)
        stackView.height(constant: MiniRoomView.ICON_WIDTH)
            .marginTrailing(anchor: trailingAnchor, constant: 10)
            .marginLeading(anchor: icon.trailingAnchor, constant: 10, relation: .greaterOrEqual)
            .centerY(anchor: centerYAnchor)
            .active()
        
        height(constant: 36 + 10 + 10)
            .active()
    }
    
    func show(with delegate: HomeController, onDismiss: (() -> Void)? = nil) {
        self.delegate = delegate
        self.show(controller: delegate, style: .bottomNoMask, padding: 16, onDismiss: onDismiss)
    }
    
    func showAlert(title: String, message: String) -> Observable<Bool> {
        self.delegate.showAlert(title: title, message: message)
    }
    
    func show(message: String, type: Notification, duration: CGFloat = 1.5) {
        self.delegate.show(message: message, type: type, duration: duration)
    }
    
    func dismiss() {
        self.dismiss(controller: delegate)
    }
    
    func onChange(room: Room) -> Observable<Bool> {
        if (viewModel.isManager && viewModel.room.id != room.id) {
            return showAlert(title: "离开房间", message: "离开房间后，所有成员将被移出房间\n房间将关闭")
                .filter { close in close }
        } else {
            return Observable.just(true)
        }
    }
    
    deinit {
        dataSourceDisposable?.dispose()
        actionDisposable?.dispose()
    }
}

extension MiniRoomView: RoomDelegate {
    
    func show(dialog: UIView, style: DialogStyle, padding: CGFloat, onDismiss: (() -> Void)?) -> Single<Bool> {
        return delegate.show(dialog: dialog, style: style, padding: padding, onDismiss: onDismiss)
    }
    
    func dismiss(dialog: UIView) -> Single<Bool> {
        return delegate.dismiss(dialog: dialog)
    }
}
