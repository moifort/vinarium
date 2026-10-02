import SwiftUI

/// Coordinator for the Admin screen: it owns (or receives) the ViewModel, loads on
/// appear and delegates all rendering to `AdminPage`. Opened as a sheet from the
/// home screen's toolbar and pushed from the settings row.
struct AdminView: View {
    @State private var viewModel: AdminViewModel

    init(viewModel: AdminViewModel = AdminViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        AdminPage(
            metrics: viewModel.metrics,
            isLoading: viewModel.isLoading,
            loadFailed: viewModel.errorMessage != nil
        )
        .task {
            if viewModel.metrics == nil { await viewModel.load() }
        }
        .refreshable { await viewModel.load() }
    }
}

#Preview {
    NavigationStack {
        AdminView()
    }
}
