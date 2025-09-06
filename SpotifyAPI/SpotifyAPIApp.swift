//
//  SpotifyAPIApp.swift
//  SpotifyAPI
//
//  Created by Raphael Tarnoczi on 06.09.25.
//

import SwiftUI

@main
struct SpotifyAPIApp: App {
    
    @StateObject var spotifyController = SpotifyController()
    @StateObject var network: Network
    
    init() {
        let controller = SpotifyController()
        _spotifyController = StateObject(wrappedValue: controller)
        _network = StateObject(wrappedValue: Network(spotifyController: controller))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(spotifyController)
                .environmentObject(network)
                .onAppear() {
                    spotifyController.setNetwork(network: network)
                }
                .onOpenURL { url in
                    spotifyController.handleRedirectURL(url)
                }
        }
    }
}
