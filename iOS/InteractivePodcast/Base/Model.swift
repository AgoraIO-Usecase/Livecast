//
//  Model.swift
//  InteractivePodcast
//
//  Created by XUCH on 2021/3/7.
//

import Foundation
import RxSwift

struct Result<T> {
    var success: Bool
    var data: T?
    var message: String?
    
    func onSuccess<U>(next: () -> Observable<Result<U>>) -> Observable<Result<U>> {
        if (success) {
            return next()
        } else {
            return Observable.just(Result<U>(success: false, message: message))
        }
    }
    
    func transform<U>() -> Result<U> {
        if (success) {
            return Result<U>(success: success)
        } else {
            return Result<U>(success: false, message: message)
        }
    }
}

class User {
    var id: String
    var name: String
    var avatar: String?
    
    init(id: String, name: String, avatar: String?) {
        self.id = id
        self.name = name
        self.avatar = avatar
    }
}

class Room: Equatable {
    
    static func == (lhs: Room, rhs: Room) -> Bool {
        return lhs.id == rhs.id
    }
    
    var id: String
    let channelName: String
    var anchor: User
    var total: Int = 0
    var speakersTotal: Int = 0
    var coverCharacters: [User] = []
    
    init(id: String, channelName: String, anchor: User) {
        self.id = id
        self.channelName = channelName
        self.anchor = anchor
    }
}

class Member {
    var id: String
    var isMuted: Bool
    var isSelfMuted: Bool
    var isSpeaker: Bool = false
    var room: Room
    var streamId: UInt
    var user: User
    
    var isManager: Bool = false
    
    init(id: String, isMuted: Bool, isSelfMuted: Bool, isSpeaker: Bool, room: Room, streamId: UInt, user: User) {
        self.id = id
        self.isMuted = isMuted
        self.isSelfMuted = isSelfMuted
        self.isSpeaker = isSpeaker
        self.room = room
        self.streamId = streamId
        self.user = user
        self.isManager = room.anchor.id == id
    }
}

enum ActionType: Int {
    case handsUp = 1
    case invite = 2
    case error
    
    static func from(value: Int) -> ActionType {
        switch value {
        case 1:
            return .handsUp
        case 2:
            return .invite
        default:
            return .error
        }
    }
}

enum ActionStatus: Int {
    case ing = 1
    case agree = 2
    case refuse = 3
    case error
    
    static func from(value: Int) -> ActionStatus {
        switch value {
        case 1:
            return .ing
        case 2:
            return .agree
        case 3:
            return .refuse
        default:
            return .error
        }
    }
}

class Action {
    var id: String
    var action: ActionType
    var status: ActionStatus
    
    var member: Member
    var room: Room
    
    init(id: String, action: ActionType, status: ActionStatus, member: Member, room: Room) {
        self.id = id
        self.action = action
        self.status = status
        self.member = member
        self.room = room
    }
}

class LocalSetting {
    var audienceLatency: Bool
    
    init(audienceLatency: Bool = false) {
        self.audienceLatency = audienceLatency
    }
}
