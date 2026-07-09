//
//  CurrencyConverterView.swift
//  CurrencyConverter
//
//  Created by Sawan Kumar on 06/02/25.
//

import SwiftUI

enum NavigationDestination: Hashable {
    case currencyList
}


struct CurrencyConverterView: View {
    @ObservedObject var viewModel: CurrencyConverterViewModel
    @State private var navigationPath = NavigationPath()
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(alignment: .leading) {
                TextField("Enter amount", text: $viewModel.amount)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .padding()
                    .focused($isTextFieldFocused)
                    .accessibilityIdentifier("amountTextField")
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                isTextFieldFocused = false
                            }
                        }
                    }

                HStack {
                    Spacer()
                    Button(action: {
                        isTextFieldFocused = false
                        navigationPath.append(NavigationDestination.currencyList)
                    }) {
                        HStack {
                            Text(viewModel.selectedCurrency)
                                .font(.headline)
                                .foregroundColor(.black)
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))
                    }
                    .accessibilityIdentifier("selectCurrencyButton")
                }
                .padding(.trailing, 16)
                
                Spacer()
                
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                        ForEach(viewModel.convertedCurrencies, id: \.code) { currency in
                            VStack {
                                Text(currency.code)
                                    .font(.headline)
                                Text(String(format: "%.2f", currency.value))
                                    .font(.subheadline)
                            }
                            .frame(width: UIScreen.main.bounds.width / 3.5, height: 100)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.2)))
                            .accessibilityIdentifier("currencyGrid_\(currency.code)")
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: .infinity)
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("Error"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .currencyList:
                    viewModel.currencyListView()
                }
            }
        }
    }
}
