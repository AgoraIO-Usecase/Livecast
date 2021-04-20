//
//  GroupViewModel.swift
//  InteractivePodcast
//
//  Created by XUCH on 2021/3/3.
//

import Foundation
import RxSwift
import RxRelay
import IGListKit

class HomeViewModel {
    let isloading: PublishRelay<Bool>
    let showMiniRoom: PublishRelay<Bool>
    var roomList: [Room] = []
    
    private var _loading: Bool = false
    private let lock = NSRecursiveLock()
    private var scheduler = SerialDispatchQueueScheduler(internalSerialQueueName: "io")

    init() {
        showMiniRoom = PublishRelay<Bool>()
        isloading = PublishRelay<Bool>()
    }
    
    func setup() -> Observable<Result<Void>> {
        return Server.shared().getAccount().map { $0.transform() }
            // UIRefreshControl bug?
            .delay(DispatchTimeInterval.microseconds(200), scheduler: scheduler)
    }
    
    func account() -> User? {
        return Server.shared().account
    }

    func dataSource() -> Observable<Result<Array<Room>>> {
        self._loading = true
        self.isloading.accept(true)
        return Server.shared().getRooms()
            //_dataSource()
            .map { [unowned self] data in
                self._loading = false
                self.lock.lock()
                self.isloading.accept(false)
                self.lock.unlock()
                if (data.success) {
                    self.roomList.removeAll()
                    self.roomList.append(contentsOf: data.data ?? [])
                }
                return data
            }.subscribe(on: scheduler)
    }
    
//    func _dataSource() -> Observable<Result<Array<Room>>> {
//        return Observable.just(Result(success: true, data: [
//            Room(id: "u01", channelName: "Post vday 互相表白大会", anchor: account()!),
//            Room(id: "u02", channelName: "Inez Garcia", anchor: account()!),
//            Room(id: "u03", channelName: "Top 3 Greatet Rappers of All Time", anchor: account()!)
//        ])).delay(DispatchTimeInterval.seconds(3), scheduler: scheduler)
//    }
    
    func createRoom(with name: String) -> Observable<Result<Room>> {
        let account = self.account()
        if let anchor = account {
            return Server.shared().create(room: Room(id: "", channelName: name, anchor: anchor))
        } else {
            return Observable.just(Result(success: false, message: "account is nil!"))
        }
    }
    
    func join(room: Room) -> Observable<Result<Room>> {
        return Server.shared().join(room: room)
    }
}

extension Room: ListDiffable {
    func diffIdentifier() -> NSObjectProtocol {
        return id as NSObjectProtocol
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard self !== object else { return true }
        guard let object = object as? Room else { return false }
        return id == object.id &&
            channelName == object.channelName &&
            total == object.total &&
            speakersTotal == object.speakersTotal
    }
}
