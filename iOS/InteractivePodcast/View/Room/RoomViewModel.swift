//
//  RoomViewModel.swift
//  InteractivePodcast
//
//  Created by XUCH on 2021/3/6.
//

import Foundation
import RxSwift
import IGListKit
import RxRelay
import RxCocoa

enum LeaveRoomAction {
    case closeRoom
    case leave
    case mini
}

enum RoomRole {
    case manager
    case speaker
    case listener
}

class SpeakerGroup: NSObject, ListDiffable {
    let list: Array<Member>
    
    init(list: Array<Member>) {
        var managers = list.filter { member in
            return member.isManager
        }
        let others = list.filter { member in
            return !member.isManager
        }
        managers.append(contentsOf: others)
        self.list = managers
    }
    
    func diffIdentifier() -> NSObjectProtocol {
        return self
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        return self === object ? true : self.isEqual(object)
    }
}

class MemberGroup: NSObject, ListDiffable {
    var list: Array<Member>
    
    init(list: Array<Member>) {
        self.list = list
    }
    
    func diffIdentifier() -> NSObjectProtocol {
        return self
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        return self === object ? true : self.isEqual(object)
    }
}

class RoomViewModel {
    
    var room: Room {
        return member.room
    }
    
    var isSpeaker: Bool {
        return member.isSpeaker
    }
    
    var isManager: Bool {
        return member.isManager
    }
    
    var role: RoomRole {
        return isManager ? .manager : isSpeaker ? .speaker : .listener
    }
    
    var account: User {
        return Server.shared().account!
    }
    
    var member: Member {
        return Server.shared().member!
    }
    
    var roomManager: Member? = nil
    
    var count: Int = 0
    var speakersCount: Int = 0
    
    var coverCharacters: [User] = []
    var memberList: [Any] = []
    var handsupList: [Action] = []
    var onHandsupListChange: BehaviorRelay<[Action]> = BehaviorRelay(value: [])
    
    func actionsSource() -> Observable<Result<Action>> {
        return Server.shared().subscribeActions()
            .map { [unowned self] result in
                if let action = result.data {
                    if (action.action == .handsUp && self.handsupList.first { item in
                        return item.member.id == action.member.id
                    } == nil) {
                        handsupList.append(action)
                        onHandsupListChange.accept(handsupList)
                    }
                }
                return result
            }
    }
    
    func roomMembersDataSource() -> Observable<Result<Bool>> {
        return Server.shared().subscribeMembers()
            .map { [unowned self] result in
                Logger.log(message: "member isMuted:\(member.isMuted) member:\(member.isSelfMuted)", level: .info)
                var roomClosed = false
                if (result.success) {
                    syncLocalUIStatus()
                    self.memberList.removeAll()
                    self.count = 0
                    self.speakersCount = 0
                    if let list = result.data {
                        if (list.count == 0) {
                            roomClosed = true
                            self.roomManager = nil
                        } else {
                            roomManager = list.first { member in
                                return member.isManager
                            }
                            self.count = list.count
                        }
                        let speakerGroup = SpeakerGroup(
                            list: list.filter { user in
                                return user.isSpeaker
                            }
                        )
                        self.speakersCount = speakerGroup.list.count
                        self.coverCharacters.removeAll()
                        
                        let max = min(self.speakersCount, 3)
                        if (max > 0) {
                            for index in 0...(max - 1) {
                                self.coverCharacters.append(speakerGroup.list[index].user)
                            }
                        } else {
                            self.coverCharacters.append(room.anchor)
                        }
                        let listenerGroup = MemberGroup(
                            list: list.filter { user in
                                return !user.isSpeaker
                            }
                        )
                        self.memberList.append(
                            contentsOf: [
                                speakerGroup,
                                "Audience".localized,
                                listenerGroup
                            ]
                        )
                    } else {
                        self.roomManager = nil
                        self.memberList.append(
                            contentsOf: [
                                SpeakerGroup(list: []),
                                "Audience".localized,
                                MemberGroup(list: [])
                            ]
                        )
                    }
                }
                return Result(success: result.success, data: roomClosed, message: result.message)
            }
    }
    
    func leaveRoom(action: LeaveRoomAction) -> Observable<Result<Void>> {
        Logger.log(message: "RoomViewModel leaveRoom action:\(action)", level: .info)
        switch action {
        case .mini:
            return Observable.just(Result(success: true))
        case .leave:
            return Server.shared().leave()
        case .closeRoom:
            return Server.shared().leave()
        }
    }
    
    let isMuted: PublishRelay<Bool> = PublishRelay<Bool>()
    
    func muted() -> Bool {
        return Server.shared().isMicrophoneClose()
    }
    
    func selfMute(mute: Bool) -> Observable<Result<Void>>{
        isMuted.accept(mute)
        return Server.shared().closeMicrophone(close: mute)
    }
    
    func handsup() -> Observable<Result<Void>>{
        return Server.shared().handsUp()
    }
    
    func inviteSpeaker(member: Member) -> Observable<Result<Void>> {
        return Server.shared().inviteSpeaker(member: member)
    }
    
    func muteSpeaker(member: Member) -> Observable<Result<Void>> {
        return Server.shared().muteSpeaker(member: member)
    }
    
    func unMuteSpeaker(member: Member) -> Observable<Result<Void>> {
        return Server.shared().unMuteSpeaker(member: member)
    }
    
    func kickSpeaker(member: Member) -> Observable<Result<Void>> {
        return Server.shared().kickSpeaker(member: member)
    }
    
    func process(action: Action, agree: Bool) -> Observable<Result<Void>> {
        switch action.action {
        case .handsUp:
            if (isManager) {
                let find = handsupList.firstIndex { item in
                    return item.id == action.id
                }
                if let find = find {
                    handsupList.remove(at: find)
                }
                onHandsupListChange.accept(handsupList)
                return Server.shared().process(handsup: action, agree: agree)
            } else {
                return Observable.just(Result(success: true))
            }
        case .invite:
            if (!isManager && !isSpeaker) {
                return Server.shared().process(invition: action, agree: agree)
            } else {
                return Observable.just(Result(success: true))
            }
        default:
            return Observable.just(Result(success: true))
        }
    }
    
    func syncLocalUIStatus() {
        isMuted.accept(muted())
    }
}
