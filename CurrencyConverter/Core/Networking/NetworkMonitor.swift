//
//  NetworkMonitor.swift
//  CurrencyConverter
//
//  Created by Sawan Kumar on 10/07/26.
//

import Foundation
import Network

protocol NetworkMonitoring: Sendable {
    var isConnected: AsyncStream<Bool> { get }
}

final class NetworkMonitor: NetworkMonitoring {

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "network.monitor")

    private let stream: AsyncStream<Bool>
    private let continuation: AsyncStream<Bool>.Continuation

    init() {
        var continuation: AsyncStream<Bool>.Continuation!

        stream = AsyncStream {
            continuation = $0
        }

        self.continuation = continuation

        monitor.pathUpdateHandler = { [continuation] path in
            continuation.yield(path.status == .satisfied)
        }

        monitor.start(queue: queue)
    }

    var isConnected: AsyncStream<Bool> {
        stream
    }
}
