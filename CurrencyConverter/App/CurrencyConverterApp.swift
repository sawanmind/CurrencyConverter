//
//  CurrencyConverterApp.swift
//  CurrencyConverter
//
//  Created by Sawan Kumar on 06/02/25.
//

import SwiftUI

@main
struct CurrencyConverterApp: App {

    var body: some Scene {

        WindowGroup {
            mainView()
        }
    }
}

extension CurrencyConverterApp {
    func mainView() -> CurrencyConverterView {
        let configuration = APIConfiguration.default

        let client = URLSessionHTTPClient()

        let remote = RESTCurrencyRemoteDataSource(
            client: client,
            configuration: configuration
        )

        let local = SwiftDataCurrencyLocalDataSource(modelContainer: SwiftDataStack.shared)
        let repository = CurrencyRepository(remote: remote,local: local, freshnessStore: UserDefaultsRateFreshnessStore())
        let vm = CurrencyConverterViewModel(repository: repository, networkMonitor: NetworkMonitor())
        return CurrencyConverterView(viewModel: vm)
    }
}
