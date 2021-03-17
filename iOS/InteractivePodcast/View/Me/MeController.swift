//
//  MeController.swift
//  InteractivePodcast
//
//  Created by XUCH on 2021/3/6.
//

import Foundation
import UIKit
import RxCocoa
import RxSwift

class MeController: BaseViewContoller {
    
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var nameView: UILabel!
    @IBOutlet weak var inputNameView: UITextField!
    @IBOutlet weak var backButton: UIButton!
    
    private var account: User!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameView.text = account.name
        avatarView.image = UIImage(named: account.getLocalAvatar())
        inputNameView.becomeFirstResponder()
        
        backButton.rx.tap
            .flatMap { _ -> Observable<Result<Void>> in
                if let name = self.inputNameView.text {
                    if (!name.isEmpty) {
                        return self.account.update(name: name.trimmingCharacters(in: [" "]))
                    }
                }
                return Observable.just(Result(success: true))
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { _ in
                self.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        inputNameView.endEditing(true)
    }
    
    static func instance(with account: User) -> MeController {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyBoard.instantiateViewController(withIdentifier: "MeController") as! MeController
        controller.account = account
        return controller
    }
}
