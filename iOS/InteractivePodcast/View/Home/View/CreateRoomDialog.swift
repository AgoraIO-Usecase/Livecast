//
//  CreateRoomDialog.swift
//  InteractivePodcast
//
//  Created by XUCH on 2021/3/5.
//

import Foundation
import UIKit
import RxSwift

protocol CreateRoomDelegate: BaseViewContoller {
    func createRoom(with: String?) -> Observable<Result<Room>>
    func onCreateSuccess(with: Room)
}

class CreateRoomDialog: UIView {
    
    private let disposeBag = DisposeBag()
    @IBOutlet weak var inputRoomView: UITextField!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    @IBOutlet weak var refreshButton: UIButton!
    weak var createRoomDelegate: CreateRoomDelegate!
    
    private var showing = false
    private var processing = false {
        didSet {
            DispatchQueue.main.async { [unowned self] in
                self.indicatorView.isHidden = !processing
                self.createButton.isEnabled = !processing
                self.inputRoomView.isEnabled = !processing
            }
        }
    }
    
    private func onCreateRoom() -> Observable<Result<Room>> {
        return createButton.rx.tap
            .throttle(RxTimeInterval.seconds(2), scheduler: MainScheduler.instance)
            .filter { [unowned self] in
                return !self.processing
            }
            .map { [unowned self] in
                self.processing = true
                return self.inputRoomView.text
            }
            .flatMap { [unowned self] name in
                return self.createRoomDelegate.createRoom(with: name)
            }
            .map { [unowned self] result in
                self.processing = false
                return result
            }
    }
    
    func show() -> Single<Bool> {
        if (showing) {
            return Single.just(true)
        } else {
            showing = true
            processing = false
            createButton.setTitle("", for: .disabled)
            
            inputRoomView.attributedPlaceholder = NSAttributedString(
                string: "请输入房间名",
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray]
            )
            inputRoomView.superview!.rounded(color: "#373337", borderWidth: 1, radius: 5)
            refreshButton.rx.tap
                .subscribe(onNext: { _ in
                    Logger.log(message: "randomRoomName", level: .info)
                    self.inputRoomView.text = Utils.randomRoomName()
                })
                .disposed(by: disposeBag)
            
            cancelButton.rx.tap
                .throttle(RxTimeInterval.seconds(2), scheduler: MainScheduler.instance)
                .flatMap { [unowned self] in
                    return self.dismiss()
                }
                .subscribe()
                .disposed(by: disposeBag)
            
            onCreateRoom()
                .subscribe(onNext: { [unowned self] result in
                    guard let room = result.data else {
                        self.createRoomDelegate.showToast(message: result.message, type: .error)
                        return
                    }
                    self.createRoomDelegate.onCreateSuccess(with: room)
                })
                .disposed(by: disposeBag)
            
            return self.createRoomDelegate.show(dialog: self, padding: 16).map { finished in
                self.inputRoomView.becomeFirstResponder()
                return finished
            }
        }
    }
    
    func dismiss() -> Single<Bool> {
        return createRoomDelegate.dismiss(dialog: self)
            .map { [unowned self] finished in
                self.showing = false
                return finished
            }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        inputRoomView.endEditing(true)
    }
}
