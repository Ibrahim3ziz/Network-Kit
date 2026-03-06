// The Swift Programming Language
// https://docs.swift.org/swift-book

import Combine
import Foundation

/// A concrete implementation of `NetworkSessionInterface` to perform HTTP requests using Combine.
public final class NetworkManager: NetworkServiceInterface, @unchecked Sendable {
    
    /// Shared singleton instance of `NetworkManager`.
    public static let shared = NetworkManager()
    
    private init() {}
    
    /// Executes a network request and decodes the response into a decodable model.
    /// - Parameters:
    ///   - request: A type conforming to `BaseRequest`, which describes the endpoint.
    ///   - model: The expected response model type.
    /// - Returns: A publisher emitting either the decoded model or a `NetworkError`.
    public func execute<T: Decodable>(_ request: BaseRequest, model: T.Type) -> AnyPublisher<T, NetworkError> {
        let urlRequest = request.asURLRequest()
        let decoder = JSONDecoder()
        
        return URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response in
                try self.handleResponse(response, data: data)
            }
            .decodeWrappedResponse(model, using: decoder)
            .mapError { error in
                (error as? NetworkError) ?? NetworkError(errorType: .unknownError)
            }
            .eraseToAnyPublisher()
    }
    
    /// Validates the HTTP response and returns the response data or throws a `NetworkError`.
    private func handleResponse(_ response: URLResponse, data: Data) throws -> Data {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError(errorType: .invalidResponse)
        }
        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 400...499, 500...599:
            throw NetworkError(errorType: .serverError)
        default:
            throw NetworkError(errorType: .unknownError)
        }
    }
}

extension Publisher where Output == Data, Failure == Error {
    /// Attempts to decode a wrapped `BaseResponse<T>` from data, falling back to decoding `T` directly if needed.
    /// - Parameters:
    ///   - type: The expected decodable type.
    ///   - decoder: A `JSONDecoder` used for decoding the data.
    /// - Returns: A publisher emitting the decoded model or an error.
    func decodeWrappedResponse<T: Decodable>(_ type: T.Type, using decoder: JSONDecoder) -> AnyPublisher<T, Error> {
        return tryMap { data in
            do {
                // Try to decode BaseResponse<T>
                let wrapped = try decoder.decode(BaseResponse<T>.self, from: data)
                guard let data = wrapped.data else {
                    throw NetworkError(errorType: .decodingError)
                }
                return data
            } catch let wrappedError {
                do {
                    // Fallback: decode plain T
                    let direct = try decoder.decode(T.self, from: data)
                    return direct
                } catch let directError {
                    throw directError
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
