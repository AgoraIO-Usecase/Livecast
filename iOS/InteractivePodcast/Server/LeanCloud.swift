//
//  Database.swift
//  InteractivePodcast
//
//  Created by XUCH on 2021/3/7.
//
#if LEANCLOUD
import Foundation
import LeanCloud
import RxSwift

class Database {
    
    static let completionQueue = DispatchQueue(label: "Database")
    
    static func save(
        transform: @escaping () throws -> LCObject
    ) -> Observable<Result<String>> {
        return Single.create { single in
            do {
                let object = try transform()
                let acl = LCACL()
                // deafult allow all user can read write
                acl.setAccess([.read, .write], allowed: true)
                object.ACL = acl
                
                object.save(completionQueue: Database.completionQueue, completion: { result in
                    switch result {
                    case .success:
                        single(.success(Result(success:true, data: object.objectId?.value)))
                    case .failure(error: let error):
                        single(.success(Result(success:false, message: error.description)))
                    }
                })
            } catch {
                single(.success(Result(success: false, message: error.localizedDescription)))
            }
            return Disposables.create()
        }.asObservable()
    }
    
    static func query<T>(
        className: String,
        objectId: String,
        queryWhere: ((LCQuery) throws -> Void)?,
        transform: @escaping (LCObject) throws -> T
    ) -> Observable<Result<T>> {
        return Single.create { single in
            let _query = LCQuery(className: className)
            do {
                if let _where = queryWhere {
                    try _where(_query)
                }
                _query.get(objectId, completionQueue: Database.completionQueue, completion: { result in
                    do {
                        switch result {
                        case .success(object: let data):
                            single(.success(Result(success:true, data: try transform(data))))
                        case .failure(error: let error):
                            single(.success(Result(success:false, message: error.description)))
                        }
                    } catch {
                        single(.success(Result(success:false, message: error.localizedDescription)))
                    }
                })
            } catch {
                single(.success(Result(success:false, message: error.localizedDescription)))
            }
            return Disposables.create()
        }.asObservable()
    }
    
    static func query<T>(
        className: String,
        queryWhere: ((LCQuery) throws -> Void)?,
        transform: @escaping ([LCObject]) throws -> T
    ) -> Observable<Result<T>> {
        return Single.create { single in
            let _query = LCQuery(className: className)
            do {
                if let _where = queryWhere {
                    try _where(_query)
                }
                _query.find (completionQueue: Database.completionQueue, completion: { result in
                    do {
                        switch result {
                        case .success(objects: let list):
                            single(.success(Result(success:true, data: try transform(list))))
                        case .failure(error: let error):
                            single(.success(Result(success:false, message: error.description)))
                        }
                    } catch {
                        Logger.log(message: "query0 \(className) error:\(error)", level: .error)
                        single(.success(Result(success:false, message: "unknown error".localized)))
                    }
                })
            } catch {
                Logger.log(message: "query1 \(className) error:\(error)", level: .error)
                single(.success(Result(success:false, message: "unknown error".localized)))
            }
            return Disposables.create()
        }.asObservable()
    }
    
    static func delete(
        className: String,
        objectId: String
    ) -> Observable<Result<Void>> {
        return Single.create { single in
            let object = LCObject(className: className, objectId: objectId)
            object.delete { _result in
                switch _result {
                case .success:
                    single(.success(Result(success:true)))
                case .failure(error: let error):
                    single(.success(Result(success:false, message: error.description)))
                }
            }
            return Disposables.create()
        }.asObservable()
    }
    
    static func delete(
        className: String,
        queryWhere: ((LCQuery) throws -> Void)?
    ) -> Observable<Result<Void>> {
        return Single.create { single in
            let _query = LCQuery(className: className)
            do {
                if let _where = queryWhere {
                    try _where(_query)
                }
                _query.find (completionQueue: Database.completionQueue, completion: { result in
                    switch result {
                    case .success(objects: let list):
                        LCObject.delete(list) { _result in
                            switch _result {
                            case .success:
                                single(.success(Result(success:true)))
                            case .failure(error: let error):
                                single(.success(Result(success:false, message: error.description)))
                            }
                        }
                    case .failure(error: let error):
                        if (error.code == 101) {
                            single(.success(Result(success:true)))
                        } else {
                            single(.success(Result(success:false, message: error.description)))
                        }
                    }
                })
            } catch {
                Logger.log(message: "delete \(className) error:\(error)", level: .error)
                single(.success(Result(success:false, message: "unknown error".localized)))
            }
            return Disposables.create()
        }.asObservable()
    }
    
    static func subscribe<T>(
        className: String,
        queryWhere: ((LCQuery) throws -> Void)?,
        onEvent: @escaping ((LiveQuery.Event) throws -> T?)
    ) -> Observable<Result<T>> {
        return Observable.create { observer -> Disposable in
            let query = LCQuery(className: className)
            var liveQuery: LiveQuery?
            do {
                if let _where = queryWhere {
                    try _where(query)
                }
                liveQuery = try LiveQuery(query: query, eventHandler: { (liveQuery, event) in
                    Logger.log(message: "liveQueryEvent event:\(event)", level: .info)
                    do {
                        let result = try onEvent(event)
                        observer.onNext(Result<T>(success: result != nil, data: result))
                    } catch {
                        observer.onNext(Result<T>(success: false, message: "unknown error".localized))
                    }
                    
                })
                liveQuery!.subscribe { result in
                    switch result {
                    case .success:
                        observer.onNext(Result(success: true))
                        Logger.log(message: "----- subscribe \(className) success -----", level: .info)
                        return
                    case .failure(error: let error):
                        Logger.log(message: "subscribe1 \(className) error:\(error)", level: .error)
                        observer.onNext(Result(success: false, message: error.reason))
                        observer.onCompleted()
                        return
                    }
                }
            } catch {
                Logger.log(message: "subscribe0 \(className) error:\(error)", level: .error)
                observer.onNext(Result(success: false, message: "unknown error".localized))
                observer.onCompleted()
            }
            return Disposables.create {
                liveQuery?.unsubscribe { (result) in
                    switch result {
                    case .success:
                        Logger.log(message: "----- unsubscribe \(className) success -----", level: .info)
                        break
                    case .failure(error: let error):
                        Logger.log(message: "----- unsubscribe \(className) error:\(error) -----", level: .error)
                    }
                }
            }
        }
    }
}

extension User {
    static func from(object: LCObject) throws -> User {
        let name: String = object.get(NAME)!.stringValue!
        let avatar: String = object.get(AVATAR)!.stringValue!
        return User(id: object.objectId!.stringValue!, name: name, avatar: avatar)
    }
    
    static func create(user: User) -> Observable<Result<String>> {
        return Database.save {
            let object = LCObject(className: TABLE)
            try object.set(NAME, value: user.name)
            try object.set(AVATAR, value: user.avatar)
            return object
        }
    }
    
    static func getUser(by objectId: String) -> Observable<Result<User>> {
        return Database.query(
            className: TABLE,
            objectId: objectId,
            queryWhere: nil,
            transform: { (data: LCObject) -> User in
                return try User.from(object: data)
            }
        )
    }
    
    static func randomUser() -> Observable<Result<User>>  {
        let user = User(id: "", name: Utils.randomString(length: 8), avatar: Utils.randomAvatar())
        return create(user: user).map { result in
            if (result.success) {
                user.id = result.data!
                return Result(success: true, data: user)
            } else {
                return Result(success: false, message: result.message)
            }
        }
    }
    
    func update(name: String) -> Observable<Result<Void>> {
        return Database.save {
            let object = LCObject(className: User.TABLE, objectId: self.id)
            try object.set(User.NAME, value: name)
            return object
        }
        .map { result in
            if (result.success) {
                self.name = name
            }
            return Result(success: result.success, message: result.message)
        }
    }
}

extension Room {
    static func queryMemberCount(room: LCObject) throws -> Int {
        let query = LCQuery(className: Member.TABLE)
        try query.where(Member.ROOM, .equalTo(room))
        return query.count().intValue
    }
    
    static func querySpeakerCount(room: LCObject) throws -> Int {
        let query = LCQuery(className: Member.TABLE)
        try query.where(Member.ROOM, .equalTo(room))
        try query.where(Member.IS_SPEAKER, .equalTo(1))
        return query.count().intValue
    }
    
    static func from(object: LCObject) throws -> Room {
        let objectId: String = object.objectId!.stringValue!
        let channelName: String = object.get(CHANNEL_NAME)!.stringValue!
        let anchor: User = try User.from(object: object.get(ANCHOR_ID) as! LCObject)
        let room = Room(id: objectId, channelName: channelName, anchor: anchor)
        room.total = try queryMemberCount(room: object)
        room.speakersTotal = try querySpeakerCount(room: object)
        if (room.coverCharacters.count == 0) {
            room.coverCharacters.append(room.anchor)
        }
        return room
    }
    
    static func create(room: Room) -> Observable<Result<String>> {
        return Database.save {
            let object = LCObject(className: TABLE)
            let anchor = LCObject(className: User.TABLE, objectId: room.anchor.id)
            try object.set(CHANNEL_NAME, value: room.channelName)
            try object.set(ANCHOR_ID, value: anchor)
            return object
        }
    }
    
    func delete() -> Observable<Result<Void>> {
        return Database.delete(className: Room.TABLE, objectId: id)
    }
    
    static func getRooms() -> Observable<Result<Array<Room>>> {
        return Database.query(className: TABLE) { (query) in
            try query.where(CHANNEL_NAME, .selected)
            try query.where(ANCHOR_ID, .selected)
            try query.where(ANCHOR_ID, .included)
            try query.where("createdAt", .descending)
        } transform: { (list) -> Array<Room> in
            let rooms: Array<Room> = try list.map { room in
                return try from(object: room)
            }
            return rooms
        }
    }
    
    static func getRoom(by objectId: String) -> Observable<Result<Room>> {
        return Database.query(className: TABLE, objectId: objectId) { query in
            try query.where(ANCHOR_ID, .included)
        } transform: { (data: LCObject) -> Room in
            let channelName: String = data.get(CHANNEL_NAME)!.stringValue!
            let anchor = try User.from(object: data.get(ANCHOR_ID) as! LCObject)
            return Room(id: objectId, channelName: channelName, anchor: anchor)
        }
    }
    
    static func update(room: Room) -> Observable<Result<String>> {
        return Database.save {
            let object = LCObject(className: TABLE, objectId: room.id)
            try object.set(CHANNEL_NAME, value: room.channelName)
            try object.set(ANCHOR_ID, value: LCObject(className: User.TABLE, objectId: room.anchor.id))
            return object
        }
    }
    
    func getMembers() -> Observable<Result<Array<Member>>> {
        return Database.query(className: Member.TABLE) { (query) in
            let room = LCObject(className: Room.TABLE, objectId: self.id)
            try query.where(Member.ROOM, .equalTo(room))
            try query.where(Member.USER, .included)
            try query.where("createdAt", .ascending)
        } transform: { (list) -> Array<Member> in
            let members: Array<Member> = try list.map { data in
                let member = try Member.from(object: data, room: self)
                member.isManager = member.user.id == self.anchor.id
                return member
            }
            return members
        }
    }
    
    func getCoverSpeakers() -> Observable<Result<Array<Member>>> {
        return Database.query(className: Member.TABLE) { (query) in
            let room = LCObject(className: Room.TABLE, objectId: self.id)
            try query.where(Member.ROOM, .equalTo(room))
            try query.where(Member.IS_SPEAKER, .equalTo(1))
            query.limit = 3
            try query.where(Member.USER, .included)
        } transform: { (list) -> Array<Member> in
            let members: Array<Member> = try list.map { data in
                let member = try Member.from(object: data, room: self)
                member.isManager = member.user.id == self.anchor.id
                return member
            }
            return members
        }
    }
    
    func subscribeMembers() -> Observable<Result<Array<Member>>> {
        return Database.subscribe(className: Member.TABLE) { [unowned self] query in
            let room = LCObject(className: Room.TABLE, objectId: self.id)
            try query.where(Member.ROOM, .equalTo(room))
        } onEvent: { (event) -> Bool in
            return true
        }
        //.startWith(Result(success: true))
        .flatMap { [unowned self] result -> Observable<Result<Array<Member>>> in
            return result.onSuccess { self.getMembers() }
        }
    }
}

extension Member {
    static func from(object: LCObject, room: Room) throws -> Member {
        let userObject = object.get(USER) as! LCObject
        let user = try User.from(object: userObject)
        let isMuted = (object.get(MUTED)?.intValue ?? 0) == 1
        let isSpeaker = (object.get(IS_SPEAKER)?.intValue ?? 0) == 1
        let isSelfMuted = (object.get(SELF_MUTED)?.intValue ?? 0) == 1
        let streamId = object.get(STREAM_ID)?.uintValue ?? 0
        let id = object.objectId!.stringValue!
        return Member(id: id, isMuted: isMuted, isSelfMuted: isSelfMuted, isSpeaker: isSpeaker, room: room, streamId: streamId, user: user)
    }
    
    func join(streamId: UInt) -> Observable<Result<Void>>{
        self.streamId = streamId
        return Database.delete(className: Member.TABLE) { query in
            let user = LCObject(className: User.TABLE, objectId: self.user.id)
            try query.where(Member.USER, .equalTo(user))
        }
        .concatMap { result -> Observable<Result<Void>> in
            if (result.success) {
                return Database.save {
                    return try self.toObject()
                }.map { result in
                    if (result.success) {
                        self.id = result.data!
                    }
                    return Result(success: result.success, message: result.message)
                }
            } else {
                return Observable.just(Result(success: false, message: result.message))
            }
        }
    }
    
    func toObject() throws -> LCObject {
        let object = LCObject(className: Member.TABLE)
        try object.set(Member.ROOM, value: LCObject(className: Room.TABLE, objectId: self.room.id))
        try object.set(Member.USER, value: LCObject(className: User.TABLE, objectId: self.user.id))
        try object.set(Member.STREAM_ID, value: self.streamId)
        try object.set(Member.IS_SPEAKER, value: self.isSpeaker ? 1 : 0)
        try object.set(Member.MUTED, value: self.isMuted ? 1 : 0)
        try object.set(Member.SELF_MUTED, value: self.isSelfMuted ? 1 : 0)
        return object
    }
    
    func mute(mute: Bool) -> Observable<Result<Void>> {
        return Database.save {
            Logger.log(message: "save mute \(mute)", level: .info)
            let object = LCObject(className: Member.TABLE, objectId: self.id)
            try object.set(Member.MUTED, value: mute ? 1 : 0)
            return object
        }
        .map { $0.transform() }
    }
    
    func selfMute(mute: Bool) -> Observable<Result<Void>> {
        return Database.save {
            Logger.log(message: "save selfMute \(mute)", level: .info)
            let object = LCObject(className: Member.TABLE, objectId: self.id)
            try object.set(Member.SELF_MUTED, value: mute ? 1 : 0)
            return object
        }
        .map { $0.transform() }
    }
    
    func asSpeaker(agree: Bool) -> Observable<Result<Void>> {
        return Database.save {
            Logger.log(message: "save asSpeaker \(agree)", level: .info)
            let object = LCObject(className: Member.TABLE, objectId: self.id)
            try object.set(Member.IS_SPEAKER, value: agree ? 1 : 0)
            if (agree) {
                try object.set(Member.MUTED, value: 0)
                try object.set(Member.SELF_MUTED, value: 0)
            }
            return object
        }
        .map { $0.transform() }
    }
    
    func leave() -> Observable<Result<Void>> {
        Logger.log(message: "Member leave isManager:\(isManager)", level: .info)
        if (self.isManager) {
            return Observable.zip(
                room.delete(),
                Database.delete(className: Member.TABLE) { query in
                    let room = LCObject(className: Room.TABLE, objectId: self.room.id)
                    try query.where(Member.ROOM, .equalTo(room))
                },
                Database.delete(className: Action.TABLE) { query in
                    let room = LCObject(className: Room.TABLE, objectId: self.room.id)
                    try query.where(Action.ROOM, .equalTo(room))
                }
            ).map { (args) in
                let (result0, result1, result2) = args
                if (result0.success && result1.success && result2.success) {
                    return result0
                } else {
                    return result0.success ? result1.success ? result2 : result1 : result0
                }
            }
        } else {
            return Database.delete(className: Member.TABLE) { query in
                let user = LCObject(className: User.TABLE, objectId: self.user.id)
                try query.where(Member.USER, .equalTo(user))
            }
        }
    }
    
    func action(with action: ActionType) -> Action {
        return Action(id: "", action: action, status: .ing, member: self, room: self.room)
    }
    
    func subscribeActions() -> Observable<Result<Action>> {
        return Database.subscribe(className: Action.TABLE) { [unowned self] query in
            let room = LCObject(className: Room.TABLE, objectId: self.room.id)
            try query.where(Action.ROOM, .equalTo(room))
//            try query.where(Action.ROOM, .included)
//            try query.where(Action.MEMBER, .included)
            if (!isManager) {
                let member = LCObject(className: Member.TABLE, objectId: self.id)
                try query.where(Action.MEMBER, .equalTo(member))
            }
        } onEvent: { (event) -> String? in
            switch event {
            case .create(object: let object):
//                Logger.log(message: object.jsonString, level: .info)
                return object.objectId!.stringValue!
            default:
                return nil
            }
        }
        .filter { result in
            return result.data != nil
        }
        .concatMap { result in
            return Action.get(objectId: result.data!)
        }
    }
    
    func handsup() -> Observable<Result<Void>> {
        let action = self.action(with: .handsUp)
        return Database.save {
            return try action.toActionObject()
        }
        .map { $0.transform() }
    }
    
    func inviteSpeaker(member: Member) -> Observable<Result<Void>> {
        let action = self.action(with: .invite)
        action.member = member
        return Database.save {
            return try action.toActionObject()
        }
        .map { $0.transform() }
    }
    
    func rejectInvition() -> Observable<Result<Void>> {
        let action = self.action(with: .invite)
        action.status = .refuse
        return Database.save {
            return try action.toActionObject()
        }
        .map { $0.transform() }
    }
}

extension Action {
    func toActionObject() throws -> LCObject {
        let object = LCObject(className: Action.TABLE)
        try object.set(Action.ROOM, value: LCObject(className: Room.TABLE, objectId: room.id))
        try object.set(Action.MEMBER, value: LCObject(className: Member.TABLE, objectId: member.id))
        try object.set(Action.ACTION, value: action.rawValue)
        try object.set(Action.STATUS, value: status.rawValue)
        return object
    }
    
    static func from(object: LCObject) throws -> Action {
        let id = object.objectId!.stringValue!
        let room = try Room.from(object: object.get(ROOM) as! LCObject)
        let member = try Member.from(object: object.get(MEMBER) as! LCObject, room: room)
        let action: Int = object.get(ACTION)!.intValue!
        let status: Int = object.get(STATUS)!.intValue!
        
        return Action(id: id, action: ActionType.from(value: action), status: ActionStatus.from(value: status), member: member, room: room)
    }
    
    static func get(objectId: String) -> Observable<Result<Action>> {
        return Database.query(className: Action.TABLE, objectId: objectId) { (query) in
            try query.where(Action.ROOM, .included)
            try query.where("\(Action.ROOM).\(Room.ANCHOR_ID)", .included)
            try query.where(Action.MEMBER, .included)
            try query.where("\(Action.MEMBER).\(Member.USER)", .included)
        } transform: { (object: LCObject) -> Action in
            return try Action.from(object: object)
        }
    }
    
    func setSpeaker(agree: Bool) -> Observable<Result<Void>> {
        return member.asSpeaker(agree: agree)
    }
    
    func setInvition(agree: Bool) -> Observable<Result<Void>> {
        if (agree) {
            return member.asSpeaker(agree: agree)
        } else {
            return member.rejectInvition()
        }
    }
}
#endif
