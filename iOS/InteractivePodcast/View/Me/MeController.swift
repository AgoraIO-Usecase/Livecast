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
    @IBOutlet weak var nickNameView: UILabel!
    @IBOutlet weak var backButton: UIView!
    @IBOutlet weak var setNameView: UIView!
    @IBOutlet weak var aboutView: UIView!
    @IBOutlet weak var audienceLatencyLevelView: UISwitch!
    
    private var account: User = Server.shared().account!
    private var setting: LocalSetting = Server.shared().setting
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameView.text = account.name
        nickNameView.text = account.name
        avatarView.image = UIImage(named: account.getLocalAvatar())
        audienceLatencyLevelView.setOn(setting.audienceLatency, animated: false)
        
        let tapBack = UITapGestureRecognizer()
        backButton.addGestureRecognizer(tapBack)
        tapBack.rx.event
            .subscribe(onNext: { _ in
                self.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
        
        let tapSetName = UITapGestureRecognizer()
        setNameView.addGestureRecognizer(tapSetName)
        tapSetName.rx.event
            .subscribe(onNext: { _ in
                self.navigationController?.pushViewController(ChangeNameController.instance(), animated: true)
            })
            .disposed(by: disposeBag)
        
        let tapAbout = UITapGestureRecognizer()
        aboutView.addGestureRecognizer(tapAbout)
        tapAbout.rx.event
            .subscribe(onNext: { _ in
                self.navigationController?.pushViewController(AboutController.instance(), animated: true)
            })
            .disposed(by: disposeBag)
        
        audienceLatencyLevelView.rx.isOn
            .asObservable()
            .filter { isOn -> Bool in
                return isOn != self.setting.audienceLatency
            }
            .flatMap { isOn -> Observable<Result<LocalSetting>> in
                self.setting.audienceLatency = isOn
                return CoreData.saveSetting(setting: self.setting)
            }
            .subscribe(onNext: { result in
                if (!result.success) {
                    self.show(message: result.message ?? "unknown error".localized, type: .error)
                } else {
                    Server.shared().updateSetting()
                }
            })
            .disposed(by: disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        nameView.text = account.name
        nickNameView.text = account.name
    }
    
    static func instance() -> MeController {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyBoard.instantiateViewController(withIdentifier: "MeController") as! MeController
        return controller
    }
}
