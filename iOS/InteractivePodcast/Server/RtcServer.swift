//
//  RtcServer.swift
//  InteractivePodcast
//
//  Created by XUCH on 2021/3/7.
//

import Foundation
import AgoraRtcKit
import RxSwift
import RxRelay

enum RtcServerStateType {
    case join
    case error
    case members
}

class RtcServer: NSObject {
    
    var rtcEngine: AgoraRtcEngineKit?
    private let statePublisher: PublishRelay<Result<RtcServerStateType>> = PublishRelay()

    var uid: UInt = 0
    var isManager: Bool = false
    var channel: String? = nil
    var members: [UInt] = []
    var speakers = [UInt: Bool]()
    var role: AgoraClientRole = .audience
    var muted: Bool = false
    
    var isJoinChannel: Bool {
        get {
            return channel != nil && channel?.isEmpty == false
        }
    }
    
    override init() {
        super.init()
        let config = AgoraRtcEngineConfig()
        config.appId = BuildConfig.AppId
        rtcEngine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        rtcEngine?.setChannelProfile(.liveBroadcasting)
        rtcEngine?.setAudioProfile(.musicHighQualityStereo, scenario: .chatRoomEntertainment)
        rtcEngine?.enableAudioVolumeIndication(500, smooth: 3, report_vad: false)
    }
    
    func setClientRole(_ role: AgoraClientRole) {
        Logger.log(message: "rtc setClientRole \(role.rawValue)", level: .info)
        if (self.role == role) {
            return
        }
        self.role = role
        guard let rtc = self.rtcEngine else {
            return
        }
        rtc.setClientRole(role)
    }
    
    func joinChannel(member: Member, channel: String) -> Observable<Result<Void>> {
        guard let rtc = self.rtcEngine else {
            return Observable.just(Result(success: false, message: "rtcEngine is nil!"))
        }
        self.members.removeAll()
        self.isManager = member.isManager
        if (member.isSpeaker) {
            setClientRole(.broadcaster)
        } else {
            setClientRole(.audience)
        }
        muteLocalMicrophone(mute: member.isSelfMuted)
        let code = rtc.joinChannel(byToken: BuildConfig.Token, channelId: channel, info: nil, uid: 0, options: AgoraRtcChannelMediaOptions())
        if (code != 0) {
            return Observable.just(Result(success: false, message: RtcServer.toErrorString(type: .join, code: code)))
        } else {
            return statePublisher.filter { (state) -> Bool in
                return state.data == RtcServerStateType.join || state.data == RtcServerStateType.error
            }.take(1).map { (state) -> Result<Void> in
                return Result(success: state.success, message: state.message)
            }
        }
    }
    
    func leaveChannel() -> Observable<Result<Void>> {
        return Single.create { [unowned self] single in
            if (isJoinChannel) {
                if let rtc = self.rtcEngine {
                    self.channel = nil
                    self.uid = 0
                    self.members.removeAll()
                    self.statePublisher.accept(Result(success: true, data: RtcServerStateType.members))
                    Logger.log(message: "rtc leaveChannel", level: .info)
                    let code = rtc.leaveChannel { state in
                        single(.success(Result(success: true)))
                    }
                    if (code != 0) {
                        single(.success(Result(success: false, message: "rtcEngine is nil!")))
                    }
                } else {
                    single(.success(Result(success: false, message: "rtcEngine is nil!")))
                }
            } else {
                single(.success(Result(success: true)))
            }
            
            return Disposables.create()
        }.asObservable()
    }
    
    func onSpeakersChanged() -> Observable<[UInt: Bool]> {
        return statePublisher
            .filter { (state) -> Bool in
                return state.data == RtcServerStateType.members
            }
            .startWith(Result(success: true, data: RtcServerStateType.members))
            .map { [unowned self] _ in
                var speakers = [UInt: Bool]()
                self.members.forEach { member in
                    speakers[member] = self.speakers[member] ?? true
                }
                return speakers
            }
    }
    
    func muteLocalMicrophone(mute: Bool) {
        Logger.log(message: "rtc muteLocalMicrophone: \(mute)", level: .info)
        self.muted = mute
        self.rtcEngine?.muteLocalAudioStream(mute)
    }
}

extension RtcServer: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        Logger.log(message: "didOccurError \(AgoraRtcEngineKit.getErrorDescription(errorCode.rawValue) ?? "\(errorCode)")", level: .info)
        self.statePublisher.accept(Result(success: false, data: RtcServerStateType.error, message: AgoraRtcEngineKit.getErrorDescription(errorCode.rawValue)))
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        Logger.log(message: "didJoinChannel:\(channel) uid:\(uid)", level: .info)
        self.uid = uid
        self.channel = channel
        self.members.append(uid)
        self.speakers[uid] = self.role == .audience
        self.statePublisher.accept(Result(success: true, data: RtcServerStateType.join))
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
        Logger.log(message: "didLeaveChannelWith:\(stats)", level: .info)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        Logger.log(message: "didJoinedOfUid uid:\(uid)", level: .info)
        self.members.append(uid)
        self.speakers[uid] = true
        self.statePublisher.accept(Result(success: true, data: RtcServerStateType.members))
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didAudioMuted muted: Bool, byUid uid: UInt) {
        Logger.log(message: "didAudioMuted uid:\(uid) muted:\(muted)", level: .info)
        self.speakers[uid] = muted
        self.statePublisher.accept(Result(success: true, data: RtcServerStateType.members))
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        Logger.log(message: "didOfflineOfUid uid:\(uid)", level: .info)
        if let index = self.members.firstIndex(of: uid) {
            self.members.remove(at: index)
        }
        self.speakers[uid] = false
        self.statePublisher.accept(Result(success: true, data: RtcServerStateType.members))
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, reportAudioVolumeIndicationOfSpeakers speakers: [AgoraRtcAudioVolumeInfo], totalVolume: Int) {
        speakers.forEach { speaker in
            if (speaker.volume > 0) {
                //Logger.log(message: "reportAudioVolumeIndicationOfSpeakers \(speaker.uid)", level: .info)
            }
        }
    }
}

enum RtcServerError: Int {
    case join = 0
    case register = 1
    case leave = 2
}

extension RtcServer: ErrorDescription {
    static func toErrorString(type: RtcServerError, code: Int32) -> String {
        switch type {
        case RtcServerError.join:
            switch code {
            case -2:
                return "参数无效"
            case -3:
                return "SDK 初始化失败"
            case -5:
                return "调用被拒绝"
            case -7:
                return "SDK 尚未初始化"
            default:
                return "未知错误"
            }
        case RtcServerError.register:
            return "未知错误"
        case RtcServerError.leave:
            switch code {
            case -2:
                return "参数无效"
            case -7:
                return "SDK 尚未初始化"
            default:
                return "未知错误"
            }
        }
    }
}
