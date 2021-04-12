//
//  DisclaimerController.swift
//  InteractivePodcast
//
//  Created by XC on 2021/4/8.
//

import Foundation
import UIKit
import RxCocoa
import RxSwift

class DisclaimerController: BaseViewContoller {
    @IBOutlet weak var backButton: UIView!
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.alwaysBounceVertical = true
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 5
        let attributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
            NSAttributedString.Key.paragraphStyle: style,
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]
        
        if let filepath = Bundle.main.path(forResource: "disclaimer", ofType: nil) {
            do {
                let contents = try String(contentsOfFile: filepath)
                textView.attributedText = NSAttributedString(string: contents, attributes: attributes)
            } catch {
                Logger.log(message: error.localizedDescription, level: .error)
            }
        }
        
        let tapBack = UITapGestureRecognizer()
        backButton.addGestureRecognizer(tapBack)
        tapBack.rx.event
            .subscribe(onNext: { _ in
                self.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    static func instance() -> DisclaimerController {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyBoard.instantiateViewController(withIdentifier: "DisclaimerController") as! DisclaimerController
        return controller
    }
}
