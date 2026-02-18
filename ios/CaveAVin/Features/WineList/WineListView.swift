import SwiftUI

struct WineListView: View {
    @State private var viewModel = WineListViewModel()
    @State private var selectedWineId: String?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.wines.isEmpty {
                    ProgressView("Chargement...")
                } else if viewModel.wines.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image("empty-no-wines")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 240)
                            .clipShape(.rect(cornerRadius: 16))
                            .opacity(0.85)
                        Text("Aucun vin")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Ajoutez des vins en scannant une étiquette")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 0) {
                        Picker("Mode", selection: $viewModel.mode) {
                            ForEach(WineListMode.allCases) { mode in
                                Text(mode.label).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .accessibilityIdentifier("winelist-segment")

                        if viewModel.displayedWines.isEmpty {
                            ContentUnavailableView("Aucun vin 5 étoiles", systemImage: "star", description: Text("Notez vos vins préférés 5 étoiles"))
                                .frame(maxHeight: .infinity)
                        } else {
                            List {
                                ForEach(viewModel.groupedWines, id: \.0) { section, wines in
                                    Section(section) {
                                        ForEach(wines) { wine in
                                            Button {
                                                selectedWineId = wine.id
                                            } label: {
                                                HStack {
                                                    WineColorBadge(color: wine.color)
                                                    VStack(alignment: .leading) {
                                                        Text(wine.name)
                                                            .font(.headline)
                                                        HStack(spacing: 4) {
                                                            if let vintage = wine.vintage {
                                                                Text(verbatim: "\(vintage)")
                                                            }
                                                            if let region = wine.region {
                                                                Text("- \(region)")
                                                            }
                                                        }
                                                        .font(.subheadline)
                                                        .foregroundStyle(.secondary)
                                                    }
                                                    Spacer()
                                                    VStack(alignment: .trailing) {
                                                        if let price = wine.purchasePrice {
                                                            Text(String(format: "%.0f €", price))
                                                                .font(.subheadline)
                                                                .foregroundStyle(.secondary)
                                                        }
                                                        if let rating = wine.rating {
                                                            HStack(spacing: 1) {
                                                                ForEach(1...5, id: \.self) { star in
                                                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                                                        .foregroundStyle(star <= rating ? .yellow : .gray.opacity(0.3))
                                                                        .font(.caption2)
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            .tint(.primary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Mes Vins")
            .refreshable {
                await viewModel.load()
            }
            .task(id: viewModel.filterKey) {
                await viewModel.load()
            }
            .toolbar {
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
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityIdentifier("winelist-sort-menu")
                }
            }
            .sheet(item: Binding(
                get: { selectedWineId.map { WineIdWrapper(id: $0) } },
                set: { selectedWineId = $0?.id }
            )) { wrapper in
                WineDetailSheet(wineId: wrapper.id)
            }
        }
    }
}

private struct WineIdWrapper: Identifiable {
    let id: String
}
