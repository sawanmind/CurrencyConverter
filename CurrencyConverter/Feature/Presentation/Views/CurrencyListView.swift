import SwiftUI

struct CurrencyListView: View {

    @Bindable var viewModel: CurrencyListViewModel

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .isLoading:
                ProgressView("Loading currencies...")
            case .empty:
                ContentUnavailableView.search
            case .error(let message):
                ContentUnavailableView("Unable to Load", image: "tray", description: Text(message))
            case .loaded(let currencies):
                List(currencies) { currency in
                    CurrencyRow(currency: currency) {
                        viewModel.selected(currency)
                        dismiss()
                    }
                }
                .listStyle(.plain)
                .accessibilityIdentifier("currencyList")
            }
        }
        .navigationTitle("Select Currency")
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search"
        )
        .animation(.default, value: viewModel.state)
        .task {
            await viewModel.load()
        }
    }
}

fileprivate struct CurrencyRow: View {
    let currency: Currency
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(currency.code)
                        .font(.headline)

                    Text(currency.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(currency.value.formatted(.number.precision(.fractionLength(2))))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("currencyCell_\(currency.code)")
        .id(currency.code)
    }
}
