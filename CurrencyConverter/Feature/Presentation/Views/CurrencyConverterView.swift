import SwiftUI

struct CurrencyConverterView: View {

    @ObservedObject var viewModel: CurrencyConverterViewModel

    @State private var showingCurrencyPicker = false
    @FocusState private var isAmountFocused: Bool

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {

        NavigationStack {
            VStack(spacing: 20) {
                amountField
                currencyPickerButton
                content
            }
            .padding()
            .sheet(isPresented: $showingCurrencyPicker) {
                NavigationStack {
                    CurrencyListView(viewModel: viewModel.makeCurrencyListViewModel())
                }
            }
            .task {
                await viewModel.load()
            }
        }
    }
}


private extension CurrencyConverterView {
    var amountField: some View {
        TextField("Enter Amount", text: $viewModel.amount)
            .frame(height: 56)
            .textFieldStyle(.roundedBorder)
            .keyboardType(.decimalPad)
            .focused($isAmountFocused)
            .accessibilityIdentifier("amountTextField")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isAmountFocused = false }
                }
            }
    }
    
    var currencyPickerButton: some View {
        HStack {
            Spacer()
            
            Button {
                isAmountFocused = false
                showingCurrencyPicker = true
            } label: {
                HStack(spacing: 8) {
                    Text(viewModel.selectedCurrencyCode)
                        .font(.headline)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.regularMaterial)
                .clipShape(Capsule())
            }
            .accessibilityIdentifier("selectCurrencyButton")
        }
    }
    
    @ViewBuilder
    var content: some View {

        switch viewModel.state {

        case .idle, .isLoading:
            Spacer()
            ProgressView()
            Spacer()

        case .empty:
            Spacer()
            ContentUnavailableView.search
            Spacer()

        case .error(let message):
            Spacer()
            ContentUnavailableView("Unable to Load", systemImage: "tray", description: Text(message))
            Spacer()

        case .loaded(let currencies):
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(currencies, id: \.id) { currency in
                        CurrencyCard(currency: currency)
                    }
                }
            }
        }
    }
}

private struct CurrencyCard: View {

    let currency: Currency

    var body: some View {
        VStack(spacing: 8) {
            Text(currency.code)
                .font(.headline)

            Text(currency.value.formatted(.number.precision(.fractionLength(2))))
            .font(.title3.weight(.medium))
            .foregroundStyle(.secondary)
            .accessibilityIdentifier("currencyGrid_\(currency.code)")
        }
        .frame(maxWidth: .greatestFiniteMagnitude)
        .frame(height: 100)
        .padding()
        .background(.thinMaterial)
        .clipShape(
            RoundedRectangle(cornerRadius: 12)
        )
    }
}
