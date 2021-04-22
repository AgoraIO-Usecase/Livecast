//
//  BaseViewContoller.swift
//  InteractivePodcast
//
//  Created by XUCH on 2021/3/5.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

enum DialogStyle: Int {
    case center = 233
    case bottom
    case top
    case topNoMask
    case bottomNoMask
    
    static func valueOf(style: Int) -> DialogStyle {
        if (style == DialogStyle.bottom.rawValue) {
            return .bottom
        } else if (style == DialogStyle.top.rawValue) {
            return .top
        }else if (style == DialogStyle.bottomNoMask.rawValue) {
            return .bottomNoMask
        } else if (style == DialogStyle.topNoMask.rawValue) {
            return .topNoMask
        } else {
            return .center
        }
    }
}

class BaseViewContoller: UIViewController {
    
    let disposeBag = DisposeBag()
    private var dialogBackgroundMaskView: UIView?
    private var onDismiss: (() -> Void)? = nil
    var enableSwipeGesture: Bool = true
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if (enableSwipeGesture) {
            self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        }
    }

    private func _showMaskView(dialog: UIView, alpha: CGFloat = 0.3) {
        if (self.dialogBackgroundMaskView == nil) {
            self.self.dialogBackgroundMaskView = UIView(frame: self.view.frame)
            self.dialogBackgroundMaskView!.backgroundColor = UIColor.black
            self.dialogBackgroundMaskView!.center = self.view.center
            self.dialogBackgroundMaskView!.alpha = 0
            
            let root = addViewTop(self.dialogBackgroundMaskView!)
            self.dialogBackgroundMaskView!.fill(view: root).active()
        }
        if let mask = dialogBackgroundMaskView {
            let tapGesture = UITapGestureRecognizer()
            mask.addGestureRecognizer(tapGesture)
            tapGesture.rx.event.flatMap { [unowned self] _ in
                return self.dismiss(dialog: dialog)
            }
            .subscribe()
            .disposed(by: disposeBag)
        }
        if let maskView: UIView = self.dialogBackgroundMaskView {
            maskView.alpha = 0
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                maskView.alpha = alpha
            })
        }
    }
    
    private func _hiddenMaskView() {
        if let maskView = self.dialogBackgroundMaskView {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                maskView.alpha = 0
            }, completion: { _ in
                maskView.removeFromSuperview()
                self.dialogBackgroundMaskView = nil
            })
        }
    }

    func show(dialog: UIView, style: DialogStyle = .center, padding: CGFloat = 0, onDismiss: (() -> Void)? = nil) -> Single<Bool> {
        return Single.create { [unowned self] single in
            self.onDismiss = onDismiss
            dialog.tag = style.rawValue
            
            switch style {
            case .bottom:
                _showMaskView(dialog: dialog)
                let root = addViewTop(dialog)
                //self.view.addSubview(dialog)
                dialog.marginLeading(anchor: root.leadingAnchor, constant: padding)
                    .centerX(anchor: root.centerXAnchor)
                    .marginBottom(anchor: root.bottomAnchor)
                    .active()
                
                dialog.alpha = 0
                let translationY = view.frame.height
                dialog.transform = CGAffineTransform(translationX: 0, y: translationY)
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                    dialog.alpha = 1
                    dialog.transform = CGAffineTransform(translationX: 0, y: 0)
                }, completion: { finish in
                    single(.success(finish))
                })
            case .center:
                _showMaskView(dialog: dialog, alpha: 0.65)
                let root = addViewTop(dialog)
                //self.view.addSubview(dialog)
                dialog.marginLeading(anchor: root.leadingAnchor, constant: padding, relation: .greaterOrEqual)
                    .centerX(anchor: root.centerXAnchor)
                    .centerY(anchor: root.centerYAnchor, constant: -50)
                    .active()

                dialog.alpha = 0
                dialog.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                    dialog.alpha = 1
                    dialog.transform = CGAffineTransform(scaleX: 1, y: 1)
                }, completion: { finish in
                    single(.success(finish))
                })
            case .top:
                _showMaskView(dialog: dialog)
                let root = addViewTop(dialog)
                //self.view.addSubview(dialog)
                dialog.marginLeading(anchor: root.leadingAnchor, constant: padding)
                    .centerX(anchor: root.centerXAnchor)
                    .marginTop(anchor: root.safeAreaLayoutGuide.topAnchor, constant: padding)
                    .active()
                
                dialog.alpha = 0
                let translationY = view.frame.height
                dialog.transform = CGAffineTransform(translationX: 0, y: -translationY)
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                    dialog.alpha = 1
                    dialog.transform = CGAffineTransform(translationX: 0, y: 0)
                }, completion: { finish in
                    single(.success(finish))
                })
            case .topNoMask:
                let root = addViewTop(dialog)
                //self.view.addSubview(dialog)
                dialog.marginLeading(anchor: root.leadingAnchor, constant: padding)
                    .centerX(anchor: root.centerXAnchor)
                    .marginTop(anchor: root.safeAreaLayoutGuide.topAnchor, constant: padding)
                    .active()
                
                dialog.alpha = 0
                let translationY = view.frame.height
                dialog.transform = CGAffineTransform(translationX: 0, y: -translationY)
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                    dialog.alpha = 1
                    dialog.transform = CGAffineTransform(translationX: 0, y: 0)
                }, completion: { finish in
                    single(.success(finish))
                })
            case .bottomNoMask:
                let root = addViewTop(dialog)
                //self.view.addSubview(dialog)
                if (padding > 0) {
                    dialog.marginLeading(anchor: root.leadingAnchor, constant: padding)
                        .centerX(anchor: root.centerXAnchor)
                        .marginBottom(anchor: root.safeAreaLayoutGuide.bottomAnchor, constant: padding)
                        .active()
                } else {
                    dialog.marginLeading(anchor: root.leadingAnchor)
                        .centerX(anchor: root.centerXAnchor)
                        .marginBottom(anchor: root.bottomAnchor)
                        .active()
                }
                
                dialog.alpha = 0
                let translationY = view.bounds.height
                dialog.transform = CGAffineTransform(translationX: 0, y: translationY)
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                    dialog.alpha = 1
                    dialog.transform = CGAffineTransform(translationX: 0, y: 0)
                }, completion: { finish in
                    single(.success(finish))
                })
            }
            
            return Disposables.create()
        }
        .subscribe(on: MainScheduler.instance)
    }
    
    func dismiss(dialog: UIView) -> Single<Bool> {
        return Single.create { [unowned self] single in
            _hiddenMaskView()
            let style = DialogStyle.valueOf(style: dialog.tag)
            switch style {
            case .bottom:
                //dialog.transform = CGAffineTransform(translationX: 0, y: 0)
                //dialog.alpha = 1
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                    let translationY = dialog.bounds.height
                    dialog.transform = CGAffineTransform(translationX: 0, y: translationY)
                    dialog.alpha = 0
                }, completion: { finish in
                    dialog.removeFromSuperview()
                    if let onDismiss = self.onDismiss {
                        onDismiss()
                    }
                    self.onDismiss = nil
                    single(.success(finish))
                })
            case .center:
                //dialog.transform = CGAffineTransform(scaleX: 1, y: 1)
                //dialog.alpha = 1
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                    dialog.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                    dialog.alpha = 0
                }, completion: { finish in
                    dialog.removeFromSuperview()
                    if let onDismiss = self.onDismiss {
                        onDismiss()
                    }
                    self.onDismiss = nil
                    single(.success(finish))
                })
            case .top:
                //dialog.transform = CGAffineTransform(translationX: 0, y: 0)
                //dialog.alpha = 1
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                    let translationY = dialog.bounds.height
                    dialog.transform = CGAffineTransform(translationX: 0, y: -translationY)
                    dialog.alpha = 0
                }, completion: { finish in
                    dialog.removeFromSuperview()
                    if let onDismiss = self.onDismiss {
                        onDismiss()
                    }
                    self.onDismiss = nil
                    single(.success(finish))
                })
            case .bottomNoMask:
                //dialog.transform = CGAffineTransform(translationX: 0, y: 0)
                //dialog.alpha = 1
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                    let translationY = dialog.bounds.height
                    dialog.transform = CGAffineTransform(translationX: 0, y: translationY)
                    dialog.alpha = 0
                }, completion: { finish in
                    dialog.removeFromSuperview()
                    if let onDismiss = self.onDismiss {
                        onDismiss()
                    }
                    self.onDismiss = nil
                    single(.success(finish))
                })
            case .topNoMask:
                //dialog.transform = CGAffineTransform(translationX: 0, y: 0)
                //dialog.alpha = 1
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                    let translationY = dialog.bounds.height
                    dialog.transform = CGAffineTransform(translationX: 0, y: -translationY)
                    dialog.alpha = 0
                }, completion: { finish in
                    dialog.removeFromSuperview()
                    if let onDismiss = self.onDismiss {
                        onDismiss()
                    }
                    self.onDismiss = nil
                    single(.success(finish))
                })
            }
            
            return Disposables.create()
        }
        .subscribe(on: MainScheduler.instance)
    }
    
    func dismiss() -> Single<Bool> {
        return Single.create { [unowned self] single in
            if let navigationController = self.navigationController {
                navigationController.popViewController(animated: true)
                single(.success(true))
            } else {
                self.dismiss(animated: true, completion: {
                    single(.success(true))
                })
            }
            return Disposables.create()
        }
    }
    
    func showAlert(title: String, message: String) -> Observable<Bool> {
        return Single.create { single in
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Cancel".localized, style: .cancel) { _ in
                single(.success(false))
            }
            alertController.addAction(cancel)
            let ok = UIAlertAction(title: "Ok".localized, style: .default) { _ in
                single(.success(true))
            }
            alertController.addAction(ok)
            self.present(alertController, animated: true, completion: nil)
            
            return Disposables.create()
        }
        .subscribe(on: MainScheduler.instance)
        .asObservable()
    }
    
    func pop() -> Single<Bool> {
        return Single.create { [unowned self] single in
            if let navigationController = self.navigationController {
                Logger.log(message: "pop with navigationController", level: .info)
                UIView.transition(with: self.navigationController!.view!, duration: 0.3, options: .curveEaseOut) {
                    let transition = CATransition()
                    transition.duration = 0
                    transition.type = CATransitionType.push
                    transition.subtype = CATransitionSubtype.fromBottom
                    transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    self.navigationController?.view.layer.add(transition, forKey: kCATransition)
                } completion: { _ in
                    Logger.log(message: "pop with navigationController finish", level: .info)
                    navigationController.popViewController(animated: false)
                    single(.success(true))
                }
            } else {
                Logger.log(message: "pop with dismiss", level: .info)
                self.dismiss(animated: true, completion: {
                    single(.success(true))
                })
            }
            return Disposables.create()
        }
    }
    
    func push(controller: UIViewController) {
        UIView.transition(with: self.navigationController!.view!, duration: 0.3, options: .curveEaseOut) {
            let transition = CATransition()
            transition.duration = 0
            transition.type = CATransitionType.push
            transition.subtype = CATransitionSubtype.fromTop
            transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            self.navigationController?.view.layer.add(transition, forKey: kCATransition)
            self.navigationController?.pushViewController(controller, animated: false)
        }
    }
}
