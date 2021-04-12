//
//  AboutController.swift
//  InteractivePodcast
//
//  Created by XC on 2021/4/8.
//

import Foundation
import UIKit
import RxCocoa
import RxSwift

class AboutController: BaseViewContoller {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var itemView0: UIView!
    @IBOutlet weak var itemView1: UIView!
    @IBOutlet weak var itemView2: UIView!
    
    @IBOutlet weak var publishTimeView: UILabel!
    @IBOutlet weak var sdkVersionView: UILabel!
    @IBOutlet weak var appVersionView: UILabel!
    
    @IBOutlet weak var backButton: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.alwaysBounceVertical = true
        let tapItem0 = UITapGestureRecognizer()
        itemView0.addGestureRecognizer(tapItem0)
        tapItem0.rx.event
            .subscribe(onNext: { _ in
                if let url = URL(string: BuildConfig.PrivacyPolicy) {
                    UIApplication.shared.open(url)
                }
            })
            .disposed(by: disposeBag)
        
        let tapItem1 = UITapGestureRecognizer()
        itemView1.addGestureRecognizer(tapItem1)
        tapItem1.rx.event
            .subscribe(onNext: { _ in
                self.navigationController?.pushViewController(DisclaimerController.instance(), animated: true)
            })
            .disposed(by: disposeBag)
        
        let tapItem2 = UITapGestureRecognizer()
        itemView2.addGestureRecognizer(tapItem2)
        tapItem2.rx.event
            .subscribe(onNext: { _ in
                if let url = URL(string: BuildConfig.SignupUrl) {
                    UIApplication.shared.open(url)
                }
            })
            .disposed(by: disposeBag)
        
        publishTimeView.text = BuildConfig.PublishTime
        sdkVersionView.text = BuildConfig.SdkVersion
        appVersionView.text = BuildConfig.AppVersion
        
        let tapBack = UITapGestureRecognizer()
        backButton.addGestureRecognizer(tapBack)
        tapBack.rx.event
            .subscribe(onNext: { _ in
                self.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    static func instance() -> AboutController {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyBoard.instantiateViewController(withIdentifier: "AboutController") as! AboutController
        return controller
    }
}
