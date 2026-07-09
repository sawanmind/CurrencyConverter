//
//  CurrencyListView.swift
//  CurrencyConverter
//
//  Created by Sawan Kumar on 06/02/25.
//

import SwiftUI
import Combine

struct CurrencyListView: View {
    @ObservedObject var viewModel: CurrencyListViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            TextField("Search", text: $viewModel.searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .accessibilityIdentifier("currencySearchBar")

            ScrollView {
                LazyVStack {
                    ForEach(viewModel.filteredCurrencies, id: \.code) { currency in
                        Button(action: {
                            viewModel.selectCurrency(currency)
                            dismiss()
                        }) {
                            HStack {
                                Text(currency.code)
                                    .font(.headline)
                                Text("- \(currency.name)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            .padding(.vertical, 5)
                        }
                        .accessibilityIdentifier("currencyCell_\(currency.code)")
                    }
                }
            }
            .padding(.horizontal, 16)
            .accessibilityIdentifier("currencyList")
        }
        .navigationTitle("Select Currency")
    }
}
