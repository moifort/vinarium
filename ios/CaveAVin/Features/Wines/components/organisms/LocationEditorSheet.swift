import MapKit
import SwiftUI

struct DiscoveryLocationDraft: Sendable, Equatable {
    var latitude: Double
    var longitude: Double
    var placeName: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct LocationEditorSheet: View {
    let initial: DiscoveryLocationDraft?
    let onConfirm: (DiscoveryLocationDraft?) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var cameraPosition: MapCameraPosition
    @State private var pinCoordinate: CLLocationCoordinate2D?
    @State private var placeName: String?
    @State private var searchQuery = ""
    @State private var searchResults: [SearchSuggestion] = []
    @State private var isResolving = false

    init(initial: DiscoveryLocationDraft?, onConfirm: @escaping (DiscoveryLocationDraft?) async -> Void) {
        self.initial = initial
        self.onConfirm = onConfirm
        let starting = initial?.coordinate
            ?? CLLocationCoordinate2D(latitude: 46.6, longitude: 2.5) // France center fallback
        let span = MKCoordinateSpan(
            latitudeDelta: initial == nil ? 8 : 0.1,
            longitudeDelta: initial == nil ? 8 : 0.1
        )
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(center: starting, span: span)))
        _pinCoordinate = State(initialValue: initial?.coordinate)
        _placeName = State(initialValue: initial?.placeName)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MapReader { proxy in
                    Map(position: $cameraPosition) {
                        if let pinCoordinate {
                            Marker(placeName ?? "S\u{00E9}lection", coordinate: pinCoordinate)
                        }
                    }
                    .onTapGesture { screenPoint in
                        if let coordinate = proxy.convert(screenPoint, from: .local) {
                            updatePin(to: coordinate)
                        }
                    }
                }

                VStack {
                    searchBar
                    Spacer()
                    actionsBar
                }
                .padding()
            }
            .navigationTitle("Lieu de d\u{00E9}couverte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .destructiveAction) {
                    if initial != nil {
                        Button("Effacer", systemImage: "trash", role: .destructive) {
                            Task {
                                await onConfirm(nil)
                                dismiss()
                            }
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    AsyncToolbarButton(title: "Enregistrer", systemImage: "checkmark") {
                        if let pinCoordinate {
                            await onConfirm(
                                DiscoveryLocationDraft(
                                    latitude: pinCoordinate.latitude,
                                    longitude: pinCoordinate.longitude,
                                    placeName: placeName
                                )
                            )
                        }
                    }
                    .disabled(pinCoordinate == nil)
                }
            }
        }
    }

    private var searchBar: some View {
        VStack(spacing: 0) {
            TextField("Rechercher un lieu", text: $searchQuery)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.search)
                .onSubmit { Task { await runSearch() } }

            if !searchResults.isEmpty {
                List(searchResults) { suggestion in
                    Button {
                        select(suggestion)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(suggestion.title).font(.subheadline)
                            if !suggestion.subtitle.isEmpty {
                                Text(suggestion.subtitle).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
                .frame(maxHeight: 200)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var actionsBar: some View {
        HStack {
            Button {
                Task { await useCurrentLocation() }
            } label: {
                Label("Ma position", systemImage: "location.fill")
            }
            .buttonStyle(.borderedProminent)

            Spacer()

            if isResolving {
                ProgressView()
            } else if let placeName {
                Text(placeName)
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.regularMaterial, in: Capsule())
            }
        }
    }

    private func updatePin(to coordinate: CLLocationCoordinate2D) {
        pinCoordinate = coordinate
        cameraPosition = .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        )
        Task { await resolveName(for: coordinate) }
    }

    private func resolveName(for coordinate: CLLocationCoordinate2D) async {
        isResolving = true
        let name = await PlaceNameResolver.resolve(coordinate)
        isResolving = false
        if pinCoordinate?.latitude == coordinate.latitude
            && pinCoordinate?.longitude == coordinate.longitude {
            placeName = name
        }
    }

    private func useCurrentLocation() async {
        if let coordinate = await LocationService.shared.requestCurrentCoordinate() {
            updatePin(to: coordinate)
        }
    }

    private func runSearch() async {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        do {
            let response = try await MKLocalSearch(request: request).start()
            searchResults = response.mapItems.prefix(8).map { item in
                SearchSuggestion(
                    id: UUID(),
                    title: item.name ?? query,
                    subtitle: item.address?.fullAddress ?? "",
                    coordinate: item.location.coordinate
                )
            }
        } catch {
            searchResults = []
        }
    }

    private func select(_ suggestion: SearchSuggestion) {
        searchResults = []
        searchQuery = suggestion.title
        updatePin(to: suggestion.coordinate)
    }
}

private struct SearchSuggestion: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
}

#Preview("Empty") {
    LocationEditorSheet(initial: nil) { _ in }
}

#Preview("Pre-filled") {
    LocationEditorSheet(
        initial: DiscoveryLocationDraft(
            latitude: 44.84,
            longitude: -0.58,
            placeName: "Bordeaux, France"
        )
    ) { _ in }
}
