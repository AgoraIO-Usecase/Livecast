//
//  HandsupList.swift
//  InteractivePodcast
//
//  Created by XC on 2021/3/12.
//

import Foundation
import UIKit
import RxSwift

protocol RoomDelegate: DialogDelegate {
    var viewModel: RoomViewModel { get set }
}

class HandsupListDialog: Dialog {
    weak var delegate: RoomDelegate!
    var title: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 18)
        view.textAlignment = .center
        view.textColor = UIColor(hex: Colors.White)
        view.text = "举手列表"
        return view
    }()
    
    var listView: UITableView = {
        let view = UITableView()
        view.backgroundColor = .clear
        return view
    }()
    
    override func setup() {
        backgroundColor = UIColor(hex: Colors.Black)
        addSubview(title)
        addSubview(listView)
    }
    
    override func render() {
        roundCorners([.topLeft, .topRight], radius: 30)
        shadow()
        title.marginLeading(anchor: leadingAnchor, constant: 20)
            .marginTrailing(anchor: trailingAnchor, constant: 20)
            .marginTop(anchor: topAnchor, constant: 20)
            .active()
        
        listView.marginTop(anchor: title.bottomAnchor, constant: 20)
            .marginLeading(anchor: leadingAnchor, constant: 20)
            .marginTrailing(anchor: trailingAnchor, constant: 20)
            .height(constant: 320, relation: .greaterOrEqual)
            .marginBottom(anchor: bottomAnchor)
            .active()
    }
    
    func show(delegate: RoomDelegate) {
        self.delegate = delegate
        let id = NSStringFromClass(Action.self)
        listView.register(HandsupCellView.self, forCellReuseIdentifier: id)
        listView.dataSource = self
        listView.rowHeight = 70
        listView.separatorStyle = .none
        
        self.delegate.viewModel.onHandsupListChange
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] list in
                self.listView.reloadData()
            })
            .disposed(by: disposeBag)
        self.show(controller: delegate)
    }
}

extension HandsupListDialog: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.delegate.viewModel.handsupList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = NSStringFromClass(Action.self)
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! HandsupCellView
        cell.item = self.delegate.viewModel.handsupList[indexPath.row]
        cell.delegate = self
        return cell
    }
}

extension HandsupListDialog: HandsupListDelegate {
    func reject(action: Action) -> Observable<Result<Void>> {
        return self.delegate.viewModel.process(action: action, agree: false)
    }
    
    func agree(action: Action) -> Observable<Result<Void>> {
        return self.delegate.viewModel.process(action: action, agree: true)
    }
}

protocol HandsupListDelegate: class {
    func reject(action: Action) -> Observable<Result<Void>>
    func agree(action: Action) -> Observable<Result<Void>>
}

class HandsupCellView: UITableViewCell {
    weak var delegate: HandsupListDelegate!
    private let disposeBag = DisposeBag()
    var item: Action! {
        didSet {
            name.text = item.member.user.name
            avatar.image = UIImage(named: item.member.user.getLocalAvatar())
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        render()
        agreeButton.rx.tap
            .flatMap { [unowned self] _ in
                return self.delegate.agree(action: self.item)
            }
            .subscribe()
            .disposed(by: disposeBag)
        
        rejectButton.rx.tap
            .flatMap { [unowned self] _ in
                return self.delegate.reject(action: self.item)
            }
            .subscribe()
            .disposed(by: disposeBag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var avatar: UIImageView = {
        let view = RoundImageView()
        //view.image = UIImage(named: "default")
        return view
    }()
    
    var name: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 15)
        view.numberOfLines = 1
        view.textColor = UIColor(hex: Colors.White)
        return view
    }()
    
    var rejectButton: UIButton = {
        let view = RoundButton()
        view.borderColor = "#AA4E5E76"
        view.setTitle("拒绝", for: .normal)
        view.setTitleColor(UIColor(hex: Colors.White), for: .normal)
        view.backgroundColor = .clear
        view.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        return view
    }()
    
    var agreeButton: UIButton = {
        let view = RoundButton()
        view.setTitle("同意", for: .normal)
        view.setTitleColor(UIColor(hex: Colors.Black), for: .normal)
        view.backgroundColor = UIColor(hex: Colors.Yellow)
        view.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        return view
    }()
    
    func render() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.addSubview(avatar)
        contentView.addSubview(name)
        contentView.addSubview(rejectButton)
        contentView.addSubview(agreeButton)
        
        agreeButton.width(constant: 80)
            .height(constant: 36)
            .marginTrailing(anchor: contentView.trailingAnchor)
            .centerY(anchor: contentView.centerYAnchor)
            .active()
        rejectButton.width(constant: 80)
            .height(constant: 36)
            .marginTrailing(anchor: agreeButton.leadingAnchor, constant: 10)
            .centerY(anchor: contentView.centerYAnchor)
            .active()
        avatar
            .width(constant: 45)
            .height(constant: 45)
            .marginLeading(anchor: contentView.leadingAnchor)
            .centerY(anchor: contentView.centerYAnchor)
            .active()
        name.marginLeading(anchor: avatar.trailingAnchor, constant: 10)
            .marginTrailing(anchor: contentView.trailingAnchor, constant: 10, relation: .equal)
            .centerY(anchor: contentView.centerYAnchor)
            .active()
    }
}
