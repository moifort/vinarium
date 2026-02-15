import SwiftUI

struct WineListView: View {
    @State private var viewModel = WineListViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.wines.isEmpty {
                    ProgressView("Chargement...")
                } else if viewModel.wines.isEmpty {
                    ContentUnavailableView("Aucun vin", systemImage: "wineglass", description: Text("Ajoutez des vins en scannant une étiquette"))
                } else {
                    List(viewModel.wines) { wine in
                        NavigationLink(value: wine.id) {
                            HStack {
                                WineColorBadge(color: wine.color)
                                VStack(alignment: .leading) {
                                    Text(wine.name)
                                        .font(.headline)
                                    HStack(spacing: 4) {
                                        if let vintage = wine.vintage {
                                            Text("\(vintage)")
                                        }
                                        if let region = wine.region {
                                            Text("- \(region)")
                                        }
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if let price = wine.purchasePrice {
                                    Text(String(format: "%.0f €", price))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Mes Vins")
            .navigationDestination(for: String.self) { wineId in
                WineDetailView(wineId: wineId)
            }
            .refreshable {
                await viewModel.load()
            }
            .task {
                await viewModel.load()
            }
            .onChange(of: viewModel.sort) { _, _ in
                Task { await viewModel.load() }
            }
            .onChange(of: viewModel.sortDescending) { _, _ in
                Task { await viewModel.load() }
            }
            .onChange(of: viewModel.statusFilter) { _, _ in
                Task { await viewModel.load() }
            }
            .onChange(of: viewModel.minRating) { _, _ in
                Task { await viewModel.load() }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.minRating = viewModel.minRating == 5 ? 0 : 5
                    } label: {
                        Image(systemName: viewModel.minRating == 5 ? "star.fill" : "star")
                    }
                    .tint(viewModel.minRating == 5 ? .yellow : nil)
                    .accessibilityLabel("Top vins")
                    .accessibilityHint(viewModel.minRating == 5 ? "Affiche tous les vins" : "Filtre les vins 5 étoiles")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Tri", selection: $viewModel.sort) {
                            ForEach(WineSort.allCases) { s in
                                Text(s.label).tag(s)
                            }
                        }
                        Toggle(viewModel.sortDescending ? "Décroissant" : "Croissant", isOn: $viewModel.sortDescending)

                        Divider()

                        Picker("Statut", selection: $viewModel.statusFilter) {
                            ForEach(WineStatusFilter.allCases) { f in
                                Text(f.label).tag(f)
                            }
                        }

                        Divider()

                        Picker("Note minimum", selection: $viewModel.minRating) {
                            Text("Toutes").tag(0)
                            ForEach(1...5, id: \.self) { rating in
                                Text(String(repeating: "\u{2605}", count: rating)).tag(rating)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }
}
