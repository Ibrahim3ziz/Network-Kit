//
//  NetworkSessionInterface.swift
//  NetworkKit
//
//  Created by Ibrahim Abdul Aziz on 27/06/2025.
//

import Foundation
import Combine

/// Abstract interface for a network session, allowing for mocking/testing and dependency injection.
public protocol NetworkServiceInterface {
    /// Executes a network request and returns a publisher with a decoded result or a `NetworkError`.
    func execute<T: Codable>(_ request: BaseRequest, model: T.Type) -> AnyPublisher<T, NetworkError>
}
