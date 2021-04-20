//
//  GroupController.swift
//  InteractivePodcast
//
//  Created by XUCH on 2021/3/3.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class HomeController: BaseViewContoller, DialogDelegate {

    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var avatarView: RoundImageView!
    @IBOutlet weak var listView: UICollectionView! {
        didSet {
            let layout = WaterfallLayout()
            layout.delegate = self
            layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            layout.minimumLineSpacing = 10.0
            layout.minimumInteritemSpacing = 10.0
            
            listView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 70, right: 0)
            listView.collectionViewLayout = layout
            listView.register(HomeCardView.self, forCellWithReuseIdentifier: NSStringFromClass(HomeCardView.self))
            listView.dataSource = self
        }
    }
    @IBOutlet var handsupTap: UITapGestureRecognizer!
    @IBOutlet weak var createRoomButton: UIButton!
    @IBOutlet var meTap: UITapGestureRecognizer!
    @IBOutlet weak var reloadButton: UIButton!
    
    private var createRoomDialog: CreateRoomDialog? = nil
    private let refreshControl: UIRefreshControl = {
        let view = UIRefreshControl()
        view.tintColor = UIColor(hex: Colors.White)
        return view
    }()
    private var viewModel: HomeViewModel!
    private var miniRoomView: MiniRoomView? = nil
    
    private func subcribeUIEvent() {
        meTap.rx.event
            .throttle(RxTimeInterval.seconds(2), scheduler: MainScheduler.instance)
            .filter { [unowned self] _ in
                self.viewModel.account() != nil
            }
            .subscribe(onNext: { [unowned self] _ in
                self.navigationController?.pushViewController(
                    MeController.instance(),
                    animated: true
                )
            })
            .disposed(by: disposeBag)
        
        createRoomButton.rx.tap
            .throttle(RxTimeInterval.seconds(2), scheduler: MainScheduler.instance)
            .filter { [unowned self] _ in
                self.viewModel.account() != nil
            }
            .concatMap { [unowned self] _ -> Single<Bool> in
                self.createRoomDialog = UIView.loadFromNib(name: "CreateRoomDialog")
                self.createRoomDialog?.createRoomDelegate = self
                return self.createRoomDialog!.show()
            }
            .subscribe()
            .disposed(by: disposeBag)
        
        viewModel
            .showMiniRoom
            .startWith(false)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] showMiniRoom in
                self.showCreatRoomView(!showMiniRoom)
                self.showMiniRoom(showMiniRoom)
            })
            .disposed(by: disposeBag)
        
        refreshControl
            .rx.controlEvent(.valueChanged)
            .concatMap { [unowned self] _ in
                return self.viewModel.dataSource()
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] result in
                if (result.success) {
                    self.emptyView.isHidden = self.viewModel.roomList.count != 0
                    self.listView.reloadData()
                } else {
                    self.show(message: result.message ?? "unknown error".localized, type: .error)
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.isloading
            .startWith(false)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] loading in
                if (loading) {
                    self.refreshControl.beginRefreshing()
                } else {
                    self.refreshControl.endRefreshing()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func initAppData() {
        viewModel.setup()
            .do(onSubscribe: {
                self.show(processing: true)
            }, onDispose: {
                self.show(processing: false)
            })
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] result in
                if let user = self.viewModel.account() {
                    self.avatarView.image = UIImage(named: user.getLocalAvatar())
                }
                if (result.success) {
                    //self.refreshControl.sendActions(for: .valueChanged)
                    // UIRefreshControl bug?
                    self.refreshControl.tintColor = UIColor(hex: Colors.White)
                    self.refreshControl.refreshManually()
                } else {
                    self.show(message: result.message ?? "unknown error".localized, type: .error)
                }
            })
            .disposed(by: disposeBag)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        listView.refreshControl = refreshControl
        viewModel = HomeViewModel()
        
        if (Utils.checkNetworkPermission()) {
            initAppData()
        } else {
            reloadButton.isHidden = false
            reloadButton.rx.tap
                .subscribe(onNext: {
                    if (Utils.checkNetworkPermission()) {
                        self.reloadButton.isHidden = true
                        self.initAppData()
                    } else {
                        self.show(message: "Needs Network permission".localized, type: .error)
                    }
                })
                .disposed(by: disposeBag)
        }
        
        subcribeUIEvent()
    }
    
    private func showCreatRoomView(_ show: Bool) {
        if (show) {
            createRoomButton.alpha = 0
            UIView.animate(withDuration: TimeInterval(0.3), delay: TimeInterval(0.3), options: .curveEaseInOut, animations: {
                self.createRoomButton.alpha = 1
            })
        } else {
            createRoomButton.alpha = 1
            UIView.animate(withDuration: TimeInterval(0.3), delay: 0, options: .curveEaseInOut, animations: {
                self.createRoomButton.alpha = 0
            })
        }
    }
        
    private func showMiniRoom(_ show: Bool) {
        Logger.log(message: "showMiniRoom \(show)", level: .info)
        if (show) {
            if (miniRoomView == nil) {
                miniRoomView = MiniRoomView()
                miniRoomView!.leaveAction = self.onLeaveRoomController
                miniRoomView!.show(with: self)
            }
        } else {
            miniRoomView?.disconnect()
            miniRoomView?.dismiss(controller: self)
            miniRoomView = nil
        }
    }
    
    private func refresh() {
        refreshControl.sendActions(for: .valueChanged)
    }
    
    func onLeaveRoomController(action: LeaveRoomAction, room: Room?) {
        //self.refresh()
        switch action {
        case .closeRoom:
            show(message: "Room closed".localized, type: .error)
            viewModel.showMiniRoom.accept(false)
            refresh()
        case .leave:
            if (room != nil) {
                show(message: "Room closed".localized, type: .error)
                refresh()
            }
            viewModel.showMiniRoom.accept(false)
        case .mini:
            viewModel.showMiniRoom.accept(true)
        }
    }
}

extension HomeController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let card: HomeCardView = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(HomeCardView.self), for: indexPath) as! HomeCardView
        card.delegate = self
        card.room = viewModel.roomList[indexPath.item]
        return card
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.roomList.count
    }
}

extension HomeController: WaterfallLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, layout: WaterfallLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (layout.collectionViewContentSize.width - 16 * 2 - 10) / 2
        return HomeCardView.sizeForItem(room: viewModel.roomList[indexPath.item], width: width)
    }
    
    func collectionViewLayout(for section: Int) -> WaterfallLayout.Layout {
        return .waterfall(column: 2, distributionMethod: .balanced)
    }
    
    func checkMiniRoom(with room: Room) -> Observable<Bool> {
        if let miniRoom = miniRoomView {
            return miniRoom.onChange(room: room).map { [unowned self] close in
                if (close) { self.viewModel.showMiniRoom.accept(false) }
                return close
            }
        }
        return Observable.just(true)
    }
}

extension HomeController: HomeCardDelegate {
    func onTapCard(with room: Room) {
        checkMiniRoom(with: room)
            .concatMap { [unowned self] _ -> Observable<Result<Room>> in
                self.show(processing: true)
                return self.viewModel.join(room: room)
            }
            .observe(on: MainScheduler.instance)
            .subscribe() { [unowned self] result in
                if (result.success) {
                    let roomController = RoomController.instance(leaveAction: self.onLeaveRoomController)
                    //roomController.navigationController = self.navigationController
                    self.push(controller: roomController)
                } else {
                    self.show(message: result.message ?? "unknown error".localized, type: .error)
                }
            } onDisposed: {
                self.show(processing: false)
            }
            .disposed(by: disposeBag)
    }
}

extension HomeController: CreateRoomDelegate {
    func onCreateSuccess(with room: Room) {
        if let dialog = createRoomDialog {
            dialog.dismiss()
                .subscribe(onSuccess: { [unowned self] _ in
                    self.refresh()
                    self.onTapCard(with: room)
                })
                .disposed(by: disposeBag)
        }
    }
    
    func createRoom(with name: String?) -> Observable<Result<Room>> {
        if (name?.isEmpty == false) {
            return viewModel.createRoom(with: name!)
        } else {
            return Observable.just(Result<Room>(success: false, message: "Enter a room name".localized))
        }
    }
}
