//
//  Config.swift
//  InteractivePodcast
//
//  Created by XUCH on 2021/3/3.
//

import Foundation
import AgoraRtcKit

struct BuildConfig {
    static let AppId = ""
    static let Token: String? = nil
    
    static let LeanCloudAppId = ""
    static let LeanCloudAppKey = ""
    static let LeanCloudServerUrl = ""
    
    static var PrivacyPolicy: String {
        if (Utils.getCurrentLanguage() == "cn") {
            return "https://www.agora.io/cn/privacy-policy/"
        } else {
            return "https://www.agora.io/en/privacy-policy/"
        }
    }
    static var SignupUrl: String {
        if (Utils.getCurrentLanguage() == "cn") {
            return "https://sso.agora.io/cn/v3/signup"
        } else {
            return "https://sso.agora.io/en/v3/signup"
        }
    }
    static let PublishTime = "2021.XX.XX"
    static let SdkVersion = AgoraRtcEngineKit.getSdkVersion()
    static var AppVersion: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
}
