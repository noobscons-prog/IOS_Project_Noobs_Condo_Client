import SwiftUI

struct HomeView: View {
    @State private var showGame = false
    
    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.12).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Text("ROBLOX").font(.title).fontWeight(.heavy).foregroundColor(.white)
                    Spacer()
                    Image(systemName: "magnifyingglass").foregroundColor(.gray).padding()
                    Image(systemName: "bell").foregroundColor(.gray).padding()
                }
                .padding(.horizontal)
                .background(Color(red: 0.12, green: 0.12, blue: 0.14))
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Friends Section (Placeholder)
                        Text("Friends (0)").font(.headline).foregroundColor(.white).padding(.horizontal)
                        
                        // Recommended Section
                        Text("Recommended For You").font(.headline).foregroundColor(.white).padding(.horizontal)
                        
                        // The Game Card (Baseplate)
                        Button(action: { showGame = true }) {
                            VStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 150)
                                    .overlay(
                                        Text("Baseplate").font(.title).fontWeight(.bold).foregroundColor(.white)
                                    )
                                Text("A Social baseplate")
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                                Text("72% Rating").foregroundColor(.gray).font(.caption)
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer()
                    }
                    .padding(.top)
                }
            }
            // Full screen game view
            if showGame {
                GameView(showGame: $showGame)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
        }
    }
}
