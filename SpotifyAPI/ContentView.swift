//
//  ContentView.swift
//  SpotifyAPI
//
//  Created by Raphael Tarnoczi on 06.09.25.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var spotifyController: SpotifyController
    @EnvironmentObject var network: Network
    
    var body: some View {
        VStack {
            if let token = spotifyController.accessToken {
                Text("🔓 Authorized")
                Button(action: {
                    network.refreshToken(spotifyController: spotifyController)
                }) {
                    Text("Refresh Spotify token")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            } else {
                Text("🔒 Not Authorized")
                Button(action: {
                    spotifyController.authorize()
                }) {
                    Text("Connect to Spotify")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
