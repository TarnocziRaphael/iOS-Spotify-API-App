import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var spotifyController: SpotifyController
    @EnvironmentObject var network: Network
    
    var body: some View {
        VStack {
            if network.isTokenLoading {
                VStack {
                    Spacer()
                    ProgressView("Connecting to Spotify…")
                        .progressViewStyle(CircularProgressViewStyle())
                        .font(.title2)
                    Spacer()
                }
            } else if spotifyController.accessToken != nil {
                LandingView()
                
            } else {
                VStack(spacing: 20) {
                    Text("🔒 Not Authorized")
                        .font(.title2)
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
        }
    }
}

struct LandingView: View {
    
    @EnvironmentObject var spotifyController: SpotifyController
    @EnvironmentObject var network: Network
    @EnvironmentObject var navModel: NavigationModel
    
    @State private var user: User?
    @State private var isLoading = true
    
    var body: some View {
        VStack {
            if !isLoading {
                NavigationStack(path: $navModel.path) {
                    VStack(spacing: 40) {
                        HStack(alignment: .center, spacing: 10) {
                            Text("Welcome \(user?.name ?? "User")!")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            if let user = self.user,
                               let url = URL(string: user.firstImageURL) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 40, height: 40)
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                        .shadow(radius: 3)
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 40, height: 40)
                                        .overlay(ProgressView())
                                }
                            }
                        }
                        .padding([.horizontal, .top])
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Spacer()
                        Button(action: {
                            navModel.path.append(NavigationGoal.topItem)
                        }) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .font(.title)
                                Text("My Top Items")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .navigationTitle("Start")   
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(15)
                            .shadow(radius: 5)
                        }
                        Button(action: {
                            navModel.path.append(NavigationGoal.playlist)
                        }) {
                            HStack {
                                Image(systemName: "music.note.list")
                                    .font(.title)
                                Text("Saved Playlists")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .navigationTitle("Start")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(15)
                            .shadow(radius: 5)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 30)
                    .navigationDestination(for: NavigationGoal.self) { value in
                        switch value {
                        case NavigationGoal.topItem:
                            TopItemsView()
                        case NavigationGoal.playlist:
                            PlaylistView()
                        case NavigationGoal.playlistDetail(let playlist):
                            PlaylistDetailView(playlist: playlist)
                        }
                    }
                    .toolbar(.hidden, for: .navigationBar)
                }
            } else {
                Spacer()
                ProgressView("Loading data...")
                    .progressViewStyle(CircularProgressViewStyle())
                Spacer()
            }
        }
        .onAppear() {
            fetchData()
        }
        
    }
    private func fetchData() {
        self.isLoading = true
        network.fetchUserInformation { user in
            DispatchQueue.main.async {
                self.user = user
                self.isLoading = false
            }
        }
    }
}
