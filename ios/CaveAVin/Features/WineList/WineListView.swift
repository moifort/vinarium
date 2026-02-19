import SwiftUI

struct WineListView: View {
    @Binding var showFavorites: Bool
    @State private var viewModel = WineListViewModel()
    @State private var selectedWineId: String?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.wines.isEmpty {
                    ProgressView("Chargement...")
                } else if viewModel.wines.isEmpty && !viewModel.hasWines {
                    VStack(spacing: 16) {
                        Spacer()
                        Image("empty-no-wines")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 240)
                            .clipShape(.rect(cornerRadius: 16))
                            .opacity(0.85)
                            .accessibilityHidden(true)
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
                            switch viewModel.mode {
                            case .favorites:
                                ContentUnavailableView("Aucun favori", systemImage: "heart", description: Text("Ajoutez vos vins préférés en favoris"))
                                    .frame(maxHeight: .infinity)
                            case .gifted:
                                ContentUnavailableView("Aucun vin offert", systemImage: "gift", description: Text("Les vins offerts apparaîtront ici"))
                                    .frame(maxHeight: .infinity)
                            default:
                                ContentUnavailableView("Aucun vin", systemImage: "wineglass", description: Text("Aucun vin ne correspond à ce filtre"))
                                    .frame(maxHeight: .infinity)
                            }
                        } else {
                            List {
                                ForEach(viewModel.groupedWines, id: \.0) { section, wines in
                                    Section(section) {
                                        ForEach(wines) { wine in
                                            Button {
                                                selectedWineId = wine.id
                                            } label: {
                                                HStack(alignment: .firstTextBaseline) {
                                                    WineColorBadge(color: wine.color)
                                                    VStack(alignment: .leading) {
                                                        Text(wine.name)
                                                            .font(.headline)
                                                        HStack(spacing: 4) {
                                                            if let vintage = wine.vintage {
                                                                Text(verbatim: "\(vintage)")
                                                            }
                                                            if wine.vintage != nil, wine.region != nil {
                                                                Text("•")
                                                            }
                                                            if let region = wine.region {
                                                                Text(region)
                                                            }
                                                            if let price = wine.purchasePrice {
                                                                if wine.vintage != nil || wine.region != nil {
                                                                    Text("•")
                                                                }
                                                                Text(String(format: "%.0f €", price))
                                                            }
                                                            if wine.giftedTo != nil {
                                                                Text("• Offert")
                                                            }
                                                        }
                                                        .font(.subheadline)
                                                        .foregroundStyle(.secondary)
                                                    }
                                                    Spacer()
                                                    VStack(alignment: .trailing) {
                                                        if let rating = wine.rating, rating != 5 {
                                                            HStack(spacing: 1) {
                                                                ForEach(1...5, id: \.self) { star in
                                                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                                                        .foregroundStyle(star <= rating ? .yellow : .gray.opacity(0.3))
                                                                        .font(.caption2)
                                                                }
                                                            }
                                                            .accessibilityElement(children: .ignore)
                                                            .accessibilityLabel("Note : \(rating) sur 5")
                                                        }
                                                    }
                                                    if wine.rating == 5 {
                                                        Image(systemName: "heart.fill")
                                                            .foregroundStyle(.red)
                                                            .font(.default)
                                                            .frame(maxHeight: .infinity, alignment: .center)
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
            .navigationBarTitleDisplayMode(.large)
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
                                Label(s.label, systemImage: s.icon).tag(s)
                            }
                        }
                        Toggle(viewModel.sortDescending ? "Décroissant" : "Croissant", isOn: $viewModel.sortDescending)

                        Divider()

                        Picker("Statut", selection: $viewModel.statusFilter) {
                            ForEach(WineStatusFilter.allCases) { f in
                                Label(f.label, systemImage: f.icon).tag(f)
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
            .onChange(of: showFavorites) {
                if showFavorites {
                    viewModel.mode = .favorites
                    showFavorites = false
                }
            }
        }
    }
}

private struct WineIdWrapper: Identifiable {
    let id: String
}

#Preview("Liste de vins") {
    @Previewable @State var showFavorites = false
    WineListView(showFavorites: $showFavorites)
}
