import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Scan", systemImage: "camera") {
                NavigationStack {
                    Text("Scan")
                        .navigationTitle("Scanner")
                }
            }

            Tab("Cave", systemImage: "square.grid.3x3") {
                NavigationStack {
                    Text("Cave")
                        .navigationTitle("Ma Cave")
                }
            }

            Tab("Vins", systemImage: "list.bullet") {
                NavigationStack {
                    Text("Vins")
                        .navigationTitle("Mes Vins")
                }
            }

            Tab("Stats", systemImage: "chart.bar") {
                NavigationStack {
                    Text("Stats")
                        .navigationTitle("Statistiques")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
