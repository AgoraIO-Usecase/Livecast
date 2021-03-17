//
//  Utils.swift
//  InteractivePodcast
//
//  Created by XUCH on 2021/3/7.
//

import Foundation
import SystemConfiguration

class Utils {
    
    enum ReachabilityStatus {
        case notReachable
        case reachableViaWWAN
        case reachableViaWiFi
    }
    
    static let names = [
        "最长的电影",
        "Good voice",
        "Bad day",
        "好故事不容错过",
        "Greatest talk show"
    ]
    
    static func randomAvatar() -> String {
        let value = Int.random(in: 1...14)
        return String(value)
    }
    
    static func randomString(length: Int, chars: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ") -> String {
        var string = ""
        for _ in 0 ..< length {
            let index = Int(arc4random_uniform(UInt32(chars.count)))
            let start = chars.index(chars.startIndex, offsetBy: index)
            let end = chars.index(chars.startIndex, offsetBy: index)
            string.append(contentsOf: chars[start...end])
        }
        return string
    }
    
    static func randomRoomName() -> String {
        let index = Int(arc4random_uniform(UInt32(names.count)))
        return names[index]
    }
    
    static func checkNetworkStatus() -> ReachabilityStatus {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)

        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return .notReachable
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return .notReachable
        }

        if flags.contains(.reachable) == false {
            // The target host is not reachable.
            return .notReachable
        } else if flags.contains(.isWWAN) == true {
            // WWAN connections are OK if the calling application is using the CFNetwork APIs.
            return .reachableViaWWAN
        } else if flags.contains(.connectionRequired) == false {
            // If the target host is reachable and no connection is required then we'll assume that you're on Wi-Fi...
            return .reachableViaWiFi
        } else if (flags.contains(.connectionOnDemand) == true || flags.contains(.connectionOnTraffic) == true) && flags.contains(.interventionRequired) == false {
            // The connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs and no [user] intervention is needed
            return .reachableViaWiFi
        } else {
            return .notReachable
        }
    }
    
    static func checkNetworkPermission() -> Bool {
        return checkNetworkStatus() != .notReachable
    }
}
