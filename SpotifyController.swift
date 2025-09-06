//
//  SpotifyController.swift
//  SpotifyAPI
//
//  Created by Raphael Tarnoczi on 06.09.25.
//

import Foundation
import SpotifyiOS
import SwiftUI

class SpotifyController: NSObject, ObservableObject {
    let clientID = Bundle.main.object(forInfoDictionaryKey: "CLIENT_ID") as? String ?? ""
    let redirectURL = URL(string: "spotify-ios-quick-start://spotify-login-callback")!
    
    lazy var configuration: SPTConfiguration = {
        let config = SPTConfiguration(clientID: clientID, redirectURL: redirectURL)
        return config
    }()
    
    lazy var sessionManager: SPTSessionManager = {
        let manager = SPTSessionManager(configuration: configuration, delegate: self)
        return manager
    }()
    
    @Published var accessToken: String? = nil
    @Published var refreshToken: String? = nil
    private var expiration: Date?
    
    func authorize() {
        let scopes: SPTScope = [.userReadPrivate, .userTopRead, .userModifyPlaybackState]
        let campaign = "spotify_auth_test"
        
        if #available(iOS 13, *) {
            sessionManager.initiateSession(with: scopes, options: .default, campaign: campaign)
        }
    }
    
    func handleRedirectURL(_ url: URL) {
        sessionManager.application(UIApplication.shared, open: url, options: [:])
    }
    
    func setAccessToken(token: String?) {
        self.accessToken = token
        print("✅ New Access Token set: \(self.accessToken ?? "none")")
    }

    func setRefreshToken(token: String?) {
        self.refreshToken = token
        print("✅ New Refresh Token set: \(self.refreshToken ?? "none")")
    }

    func setExpiration(date: Date?) {
        self.expiration = date
        let formattedDate = self.expiration?.formatted(date: .numeric, time: .shortened) ?? "none"
        print("✅ New Expiration Date set: \(formattedDate)")
    }

}

extension SpotifyController: SPTSessionManagerDelegate {
    
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        print("✅ Spotify Session Initiated")
        DispatchQueue.main.async {
            self.setAccessToken(token: session.accessToken)
            self.setRefreshToken(token: session.refreshToken)
            self.setExpiration(date: session.expirationDate)
        }
    }
    
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        print("❌ Spotify Authorization Failed:", error.localizedDescription)
        DispatchQueue.main.async {
            self.setAccessToken(token: nil)
            self.setRefreshToken(token: nil)
            self.setExpiration(date: nil)
        }
    }
    
    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        print("🔄 Spotify Session Renewed")
        DispatchQueue.main.async {
            self.setAccessToken(token: session.accessToken)
            self.setRefreshToken(token: session.refreshToken)
            self.setExpiration(date: session.expirationDate)
        }
    }
}
