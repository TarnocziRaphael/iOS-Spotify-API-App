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
    private var headers: HTTPHeaders = [:]
    
    init(spotifyController: SpotifyController) {
        self.spotifyController = spotifyController
        self.refreshToken() {
            self.updateHeaders()
        }
    }
    
    func updateHeaders() {
        if let token = spotifyController.accessToken {
            headers = [
                "Authorization": "Bearer \(token)",
                "Content-Type": "application/json"
            ]
        }
    }
    
    func refreshToken(completion: @escaping() -> Void) {
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
                completion()
            case .failure(let error):
                if let data = response.data, let text = String(data: data, encoding: .utf8) {
                    print("❌ Spotify Token Refresh Failed (response):", text)
                } else {
                    print("❌ Spotify Token Refresh Failed:", error.localizedDescription)
                }
            }
        }
    }
    
    func fetchTopArtists(timeRange: TimeRange, completion: @escaping([Artist]) -> Void) {
        AF.request(
            "\(baseURL)me/top/artists?time_range=\(timeRange.rawValue)&limit=50",
            method: .get,
            headers: self.headers
        )
        .responseDecodable(of: TopArtistsResponse.self) { response in
            switch response.result {
            case .success(let data):
                print("✅ Fetch of top artists successful")
                completion(data.items)
            case .failure(let error):
                if let data = response.data, let text = String(data: data, encoding: .utf8) {
                    print("❌ Fetch of top artists failed (response):", text)
                } else {
                    print("❌ Fetch of top artists failed:", error.localizedDescription)
                }
            }
        }
    }
    
    func fetchTopTracks(timeRange: TimeRange, completion: @escaping([Track]) -> Void) {
        AF.request(
            "\(baseURL)me/top/tracks?time_range=\(timeRange.rawValue)&limit=50",
            method: .get,
            headers: self.headers
        )
        .responseDecodable(of: TopTracksResponse.self) { response in
            switch response.result {
            case .success(let data):
                print("✅ Fetch of top tracks successful")
                completion(data.items)
            case .failure(let error):
                if let data = response.data, let text = String(data: data, encoding: .utf8) {
                    print("❌ Fetch of top tracks failed (response):", text)
                } else {
                    print("❌ Fetch of top tracks failed:", error.localizedDescription)
                }
            }
        }
    }
    
    func playMusic(id: String, type: MusicType, deviceID: String) {
        var body: [String: Any] = [:]
        if type == .artist {
            body = [
                "context_uri": "spotify:artist:\(id)",
                "position_ms": 0
            ]
        } else if type == .track {
            body = [
                "uris": ["spotify:track:\(id)"],
                "position_ms": 0
            ]
        }
        AF.request(
            "\(baseURL)me/player/play?device_id=\(deviceID)",
            method: .put,
            parameters: body,
            encoding: JSONEncoding.default,
            headers: self.headers
        )
        .response { response in
            switch response.result {
            case .success:
                print("✅ Music started playing successfully")
            case .failure(let error):
                if let data = response.data, let text = String(data: data, encoding: .utf8) {
                    print("❌ Playing music failed (response):", text)
                } else {
                    print("❌ Playing music failed:", error.localizedDescription)
                }
            }
        }
    }
    
    func fetchAvailableDevices(completion: @escaping([Device]) -> Void) {
        AF.request(
            "\(baseURL)me/player/devices",
            method: .get,
            headers: self.headers
        ).responseDecodable(of: DevicesResponse.self) { response in
            switch response.result {
            case .success(let data):
                print("✅ Fetch of available devices successful")
                completion(data.devices)
            case .failure(let error):
                if let data = response.data, let text = String(data: data, encoding: .utf8) {
                    print("❌ Fetch of available devices failed (response):", text)
                } else {
                    print("❌ Fetch of available devices failed:", error.localizedDescription)
                }
            }
        }
    }
    
    func fetchUserInformation(completion: @escaping(User) -> Void) {
        AF.request(
            "\(baseURL)me",
            method: .get,
            headers: self.headers
        )
        .responseDecodable(of: User.self) { response in
            switch response.result {
            case .success(let data):
                print("✅ Fetch of user data successful")
                completion(data)
            case .failure(let error):
                if let data = response.data, let text = String(data: data, encoding: .utf8) {
                    print("❌ Fetch of user data failed (response):", text)
                } else {
                    print("❌ Fetch of user data failed:", error.localizedDescription)
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

struct Track: Codable, Identifiable {
    let id: String
    let name: String
    let popularity: Int
    let album: Album
    let artists: [Artist]
    
    var artistNames: String {
        artists.map { $0.name }.joined(separator: ", ")
    }
}

struct Picture: Codable {
    let url: String
}

struct Album: Codable {
    let name: String
    let images: [Picture]
    
    var firstImageURL: String? {
        return images.first?.url
    }
}

struct Artist: Codable, Identifiable {
    let id: String
    let name: String
    let popularity: Int?
    let images: [Picture]?
    
    var firstImageURL: String? {
        return images?.first?.url
    }
}

struct TopTracksResponse: Codable {
    let items: [Track]
}

struct TopArtistsResponse: Codable {
    let items: [Artist]
}

struct Device: Codable, Identifiable {
    let id: String
    let name: String
}

struct DevicesResponse: Codable {
    let devices: [Device]
}

struct User: Codable, Identifiable {
    let id: String
    let name: String
    let images: [Picture]
    
    var firstImageURL: String {
        return images.first!.url
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name = "display_name"
        case images
    }
}
