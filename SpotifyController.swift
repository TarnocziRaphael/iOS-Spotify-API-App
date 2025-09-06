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
    private var network: Network?
    private let refreshTokenKey = "spotifyRefreshToken"
    
    override init() {
        super.init()
        loadInformation()
    }
    
    func authorize() {
        let scopes: SPTScope = [.userReadPrivate, .userTopRead, .userModifyPlaybackState, .userReadPlaybackState, .userReadEmail, .userReadPrivate]
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
    }
    
    func setRefreshToken(token: String?) {
        self.refreshToken = token
    }
    
    func setExpiration(date: Date?) {
        self.expiration = date
    }
    
    func setNetwork(network: Network) {
        self.network = network
    }
    
    func saveInformation(accessToken: String, refreshToken: String, expiration: Date) {
        self.setAccessToken(token: accessToken)
        UserDefaults.standard.set(refreshToken, forKey: refreshTokenKey)
        self.setRefreshToken(token: refreshToken)
        self.setExpiration(date: expiration)
        print("✅ Stored information successfully")
    }
    
    func loadInformation() {
        if let refreshToken = UserDefaults.standard.string(forKey: refreshTokenKey) {
            self.setRefreshToken(token: refreshToken)
        } else {
            print("⚠️ No saved token found")
        }
    }
    
    func clearInformation() {
        self.accessToken = nil
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        self.refreshToken = nil
        self.expiration = nil
    }
}

extension SpotifyController: SPTSessionManagerDelegate {
    
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        print("✅ Spotify Session Initiated")
        DispatchQueue.main.async {
            self.saveInformation(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                expiration: session.expirationDate
            )
            if let network = self.network {
                network.updateHeaders()
            }
        }
    }
    
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        print("❌ Spotify Authorization Failed:", error.localizedDescription)
        DispatchQueue.main.async {
            self.clearInformation()
        }
    }
    
    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        print("🔄 Spotify Session Renewed")
        DispatchQueue.main.async {
            self.saveInformation(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                expiration: session.expirationDate
            )
        }
    }
}
