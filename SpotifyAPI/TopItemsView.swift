//
//  ContentView.swift
//  SpotifyAPI
//
//  Created by Raphael Tarnoczi on 06.09.25.
//

import SwiftUI
import ToastUI

struct TopItemsView: View {
    
    @EnvironmentObject var spotifyController: SpotifyController
    @EnvironmentObject var network: Network
    
    @State private var selectedTimeRange: TimeRange = .short_term
    @State private var selectedPage: MusicType = .artist
    @State private var isLoading: Bool = false
    @State private var topArtists: [Artist] = []
    @State private var topTracks: [Track] = []
    @State private var devicesError: Bool = false
    @State private var deviceName: String = ""
    @State private var user: User?
    @State private var displayUserInfo: Bool = false
    @State private var isAuthorizing: Bool = true
    
    var body: some View {
        ZStack {
            if network.isTokenLoading {
                VStack {
                    Spacer()
                    ProgressView("Connecting to Spotify…")
                        .progressViewStyle(CircularProgressViewStyle())
                        .font(.title2)
                    Spacer()
                }
            }
            else if spotifyController.accessToken != nil {
                VStack {
                    HStack {
                        if let user = self.user,
                           let url = URL(string: user.firstImageURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 30, height: 30)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                    .shadow(radius: 3)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 30, height: 30)
                                    .overlay(ProgressView())
                            }
                            .onTapGesture {
                                self.displayUserInfo = true
                            }
                        }
                        Spacer()
                        Picker("Zeitraum", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 250)
                        .onChange(of: selectedTimeRange) {
                            fetchData()
                        }
                        Spacer()
                        Button(action: {
                            network.refreshToken() {
                                fetchData()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 15))
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(Circle().fill(Color.blue))
                                .shadow(radius: 5)
                        }
                    }
                    
                    TabView(selection: $selectedPage) {
                        VStack {
                            if isLoading {
                                Spacer()
                                ProgressView("Loading top artists...")
                                    .progressViewStyle(CircularProgressViewStyle())
                                Spacer()
                            }
                            else {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Top Artists")
                                            .font(.title)
                                            .bold()
                                        Text("Popularity: \(self.averagePopularity())")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal)
                                    
                                    Spacer()
                                }
                                TopArtistsView(topArtists: topArtists) { artist in
                                    network.fetchAvailableDevices() { devices in
                                        guard let device = devices.first else {
                                            print("⚠️ No devices available")
                                            self.devicesError = true
                                            return
                                        }
                                        self.deviceName = device.name
                                        network.playMusic(id: artist.id, type: .artist, deviceID: device.id)
                                    }
                                }
                                .refreshable {
                                    fetchData()
                                }
                            }
                        }
                        .tag(MusicType.artist)
                        VStack {
                            if isLoading {
                                Spacer()
                                ProgressView("Loading top tracks...")
                                    .progressViewStyle(CircularProgressViewStyle())
                                Spacer()
                            }
                            else {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Top Tracks")
                                            .font(.title)
                                            .bold()
                                        Text("Popularity: \(self.averagePopularity())")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal)
                                    
                                    Spacer()
                                }
                                TopTracksListView(topTracks: topTracks) { track in
                                    network.fetchAvailableDevices() { devices in
                                        guard let device = devices.first else {
                                            print("⚠️ No devices available")
                                            self.devicesError = true
                                            return
                                        }
                                        self.deviceName = device.name
                                        network.playMusic(id: track.id, type: .track, deviceID: device.id)
                                    }
                                }
                                .refreshable {
                                    fetchData()
                                }
                                
                            }
                        }
                        .tag(MusicType.track)
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .onChange(of: selectedPage) {
                        fetchData()
                    }
                }
                .toast(isPresented: $devicesError, dismissAfter: 1.5) {
                    Text("⚠️ No devices available")
                        .font(.title2)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .toast(
                    isPresented: Binding(
                        get: { !self.deviceName.isEmpty },
                        set: { _ in self.deviceName = "" }
                    ),
                    dismissAfter: 1.5,
                    onDismiss: { self.deviceName = "" }
                ) {
                    Text("✅ Music started playing on \(self.deviceName)")
                        .font(.title2)
                        .lineLimit(1)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .toast(isPresented: $displayUserInfo, dismissAfter: 1.5) {
                    Text("🙋 Hello, \(user?.name ?? "User")!")
                        .font(.title2)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .onAppear() {
                    
                    fetchData()
                    network.fetchUserInformation { user in
                        DispatchQueue.main.async {
                            self.user = user
                        }
                    }
                }
                
            }
        }
        .padding()
    }
    
    private func fetchData() {
        self.isLoading = true
        if self.selectedPage == .artist {
            network.fetchTopArtists(timeRange: selectedTimeRange) { artists in
                DispatchQueue.main.async {
                    self.topArtists = artists
                    self.isLoading = false
                }
            }
        } else if self.selectedPage == .track {
            network.fetchTopTracks(timeRange:selectedTimeRange) { tracks in
                DispatchQueue.main.async {
                    self.topTracks = tracks
                    self.isLoading = false
                }
            }
        }
        
    }
    
    private func averagePopularity() -> Int {
        if self.selectedPage == .artist {
            guard !topArtists.isEmpty else { return 0 }
            let total = topArtists.map { $0.popularity! }.reduce(0, +)
            return total / topArtists.count
        } else {
            guard !topTracks.isEmpty else { return 0 }
            let total = topTracks.map { $0.popularity }.reduce(0, +)
            return total / topTracks.count
        }
    }
}

#Preview {
    TopItemsView()
}
