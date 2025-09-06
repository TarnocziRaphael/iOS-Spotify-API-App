//
//  Network.swift
//  SpotifyAPI
//
//  Created by Raphael Tarnoczi on 06.09.25.
//

import Foundation
import Alamofire
import SwiftUI

class Network: ObservableObject {
    private var spotifyController: SpotifyController
    private let baseURL = "https://api.spotify.com/v1/"
    private var headers: HTTPHeaders = []
    
    init(spotifyController: SpotifyController) {
        self.spotifyController = spotifyController
        self.updateHeaders()
    }
    func updateHeaders() {
        if let token = spotifyController.accessToken {
            headers = ["Authorization": "Bearer \(token)"]
        }
    }
    
    func refreshToken() {
        guard let refreshToken = spotifyController.refreshToken,
              let clientId = Bundle.main.object(forInfoDictionaryKey: "CLIENT_ID") as? String else {
            print("❌ Missing refresh token or client ID")
            return
        }
        
        let body: [String: String] = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": clientId
        ]
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        
        AF.request(
            "https://accounts.spotify.com/api/token",
            method: .post,
            parameters: body,
            encoder: URLEncodedFormParameterEncoder.default,
            headers: headers
        )
        .responseDecodable(of: TokenRefresh.self) { response in
            switch response.result {
            case .success(let data):
                print("✅ Spotify Token Refresh Successful")
                self.spotifyController.saveInformation(
                    accessToken: data.accessToken,
                    refreshToken: data.refreshToken,
                    expiration: Date().addingTimeInterval(TimeInterval(data.expiration))
                )
            case .failure(let error):
                if let data = response.data, let text = String(data: data, encoding: .utf8) {
                    print("❌ Spotify Token Refresh Failed (response):", text)
                } else {
                    print("❌ Spotify Token Refresh Failed:", error.localizedDescription)
                }
            }
        }
    }
    
}


struct TokenRefresh: Codable {
    let accessToken: String
    let refreshToken: String
    let expiration: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiration = "expires_in"
    }
}
