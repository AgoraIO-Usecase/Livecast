//
//  Dialog.swift
//  InteractivePodcast
//
//  Created by XC on 2021/3/13.
//

import Foundation
import UIKit
import RxSwift

protocol DialogDelegate: class {
    func show(dialog: UIView, style: DialogStyle, padding: CGFloat, onDismiss: (() -> Void)?) -> Single<Bool>
    func dismiss(dialog: UIView) -> Single<Bool>
    func show(message: String, type: Notification, duration: CGFloat)
}

class Dialog: UIView {
    let disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        render()
    }
    
    open func setup() {}
    open func render() {}
    
    func show(
        controller: DialogDelegate,
        style: DialogStyle = .bottom,
        padding: CGFloat = 0,
        onDismiss: (() -> Void)? = nil
    ) {
        controller.show(dialog: self, style: style, padding: padding, onDismiss: onDismiss)
            .subscribe()
            .disposed(by: disposeBag)
    }
    
    func dismiss(controller: BaseViewContoller) {
        controller.dismiss(dialog: self)
            .subscribe()
            .disposed(by: disposeBag)
    }
}
