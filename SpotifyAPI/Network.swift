//
//  Network.swift
//  SpotifyAPI
//
//  Created by Raphael Tarnoczi on 06.09.25.
//

import Foundation
import Alamofire

class Network: ObservableObject {
    private let baseURL = "https://api.spotify.com/v1/"
    private var headers: HTTPHeaders = []
    
    init(spotifyController: SpotifyController) {
        self.headers = ["Authorization" : "Bearer \(String(describing: spotifyController.accessToken))"]
    }
    
    func refreshToken(spotifyController: SpotifyController) {
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
                spotifyController.setAccessToken(token: data.accessToken)
                spotifyController.setRefreshToken(token: data.refreshToken)
                spotifyController.setExpiration(date: Date().addingTimeInterval(TimeInterval(data.experation)))
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
    let experation: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case experation = "expires_in"
    }
}
