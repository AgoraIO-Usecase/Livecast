//
//  Service.swift
//  InteractivePodcast
//
//  Created by XUCH on 2021/3/3.
//

import Foundation
import RxSwift

protocol Service {
    var account: User? { get set }
    var member: Member? { get set }
    
    func getAccount() -> Observable<Result<User>>
    func getRooms() -> Observable<Result<Array<Room>>>
    func create(room: Room) -> Observable<Result<Room>>
    func join(room: Room) -> Observable<Result<Room>>
    func leave() -> Observable<Result<Void>>
    func closeMicrophone(close: Bool) -> Observable<Result<Void>>
    func isMicrophoneClose() -> Bool
    
    func subscribeMembers() -> Observable<Result<Array<Member>>>
    func subscribeActions() -> Observable<Result<Action>>
    
    func inviteSpeaker(member: Member) -> Observable<Result<Void>>
    func muteSpeaker(member: Member) -> Observable<Result<Void>>
    func unMuteSpeaker(member: Member) -> Observable<Result<Void>>
    func kickSpeaker(member: Member) -> Observable<Result<Void>>
    func process(handsup: Action, agree: Bool) -> Observable<Result<Void>>
    
    func process(invition: Action, agree: Bool) -> Observable<Result<Void>>
    func handsUp() -> Observable<Result<Void>>
}

protocol ErrorDescription {
    associatedtype Item
    static func toErrorString(type: Item, code: Int32) -> String
}
