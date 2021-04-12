//
//  Database.swift
//  InteractivePodcast
//
//  Created by XC on 2021/4/6.
//

extension User {
    static let TABLE: String = "USER"
    static let NAME: String = "name"
    static let AVATAR: String = "avatar"
    
    func getLocalAvatar() -> String {
        switch avatar {
        case "1":
            return "default"
        case "2":
            return "portrait02"
        case "3":
            return "portrait03"
        case "4":
            return "portrait04"
        case "5":
            return "portrait05"
        case "6":
            return "portrait06"
        case "7":
            return "portrait07"
        case "8":
            return "portrait08"
        case "9":
            return "portrait09"
        case "10":
            return "portrait10"
        case "11":
            return "portrait11"
        case "12":
            return "portrait12"
        case "13":
            return "portrait13"
        case "14":
            return "portrait14"
        default:
            return "default"
        }
    }
}

extension Room {
    static let TABLE: String = "ROOM"
    static let ANCHOR_ID: String = "anchorId"
    static let CHANNEL_NAME: String = "channelName"
}

extension Member {
    static let TABLE: String = "MEMBER"
    static let MUTED: String = "isMuted"
    static let SELF_MUTED: String = "isSelfMuted"
    static let IS_SPEAKER: String = "isSpeaker"
    static let ROOM: String = "roomId"
    static let STREAM_ID = "streamId"
    static let USER = "userId"
}

extension Action {
    static let TABLE: String = "ACTION"
    static let ACTION: String = "action"
    static let MEMBER: String = "memberId"
    static let ROOM: String = "roomId"
    static let STATUS: String = "status"
}
