// The Swift Programming Language
// https://docs.swift.org/swift-book

import Combine
import Foundation

/// A concrete implementation of `NetworkSessionInterface` to perform HTTP requests using Combine.
public final class NetworkManager: NetworkServiceInterface, @unchecked Sendable {
    
    /// Shared singleton instance of `NetworkManager`.
    public static let shared = NetworkManager()
    
    /// Enable/disable logging (enabled in DEBUG builds by default)
    public var isLoggingEnabled: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    private init() {}
    
    /// Executes a network request and decodes the response into a decodable model.
    /// - Parameters:
    ///   - request: A type conforming to `BaseRequest`, which describes the endpoint.
    ///   - model: The expected response model type.
    /// - Returns: A publisher emitting either the decoded model or a `NetworkError`.
    public func execute<T: Decodable>(_ request: BaseRequest, model: T.Type) -> AnyPublisher<T, NetworkError> {
        let urlRequest = request.asURLRequest()
        let decoder = JSONDecoder()
        
        // Log the request
        logRequest(urlRequest)
        
        return URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { [weak self] data, response in
                // Log the response
                self?.logResponse(response, data: data, request: urlRequest)
                return try self?.handleResponse(response, data: data) ?? data
            }
            .decodeWrappedResponse(model, using: decoder)
            .handleEvents(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.logError(error, request: urlRequest)
                    }
                }
            )
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

// MARK: - Logger
extension NetworkManager {
    
    /// Logs the outgoing network request
    private func logRequest(_ request: URLRequest) {
        guard isLoggingEnabled else { return }
        
        print("\n" + String(repeating: "=", count: 80))
        print("🌐 NETWORK REQUEST")
        print(String(repeating: "=", count: 80))
        
        // URL
        if let url = request.url {
            print("📍 URL: \(url.absoluteString)")
        }
        
        // Method
        if let method = request.httpMethod {
            print("📤 Method: \(method)")
        }
        
        // Headers
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            print("📋 Headers:")
            headers.forEach { key, value in
                print("   \(key): \(value)")
            }
        }
        
        // Body
        if let body = request.httpBody {
            if let jsonString = String(data: body, encoding: .utf8) {
                print("📦 Body:")
                print(jsonString.prettyPrintedJSON)
            } else {
                print("📦 Body: \(body.count) bytes (binary data)")
            }
        }
        
        print(String(repeating: "=", count: 80) + "\n")
    }
    
    /// Logs the incoming network response
    private func logResponse(_ response: URLResponse, data: Data, request: URLRequest) {
        guard isLoggingEnabled else { return }
        
        print("\n" + String(repeating: "=", count: 80))
        print("📥 NETWORK RESPONSE")
        print(String(repeating: "=", count: 80))
        
        // URL
        if let url = request.url {
            print("📍 URL: \(url.absoluteString)")
        }
        
        // Status Code & Duration
        if let httpResponse = response as? HTTPURLResponse {
            let statusEmoji = statusCodeEmoji(httpResponse.statusCode)
            print("\(statusEmoji) Status Code: \(httpResponse.statusCode)")
            
            // Response Headers
            if !httpResponse.allHeaderFields.isEmpty {
                print("📋 Response Headers:")
                httpResponse.allHeaderFields.forEach { key, value in
                    print("   \(key): \(value)")
                }
            }
        }
        
        // Response Body
        if data.isEmpty {
            print("📭 Response Body: Empty")
        } else {
            print("📦 Response Body: \(data.count) bytes")
            if let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString.prettyPrintedJSON)
            } else {
                print("   (Binary data)")
            }
        }
        
        print(String(repeating: "=", count: 80) + "\n")
    }
    
    /// Logs network errors
    private func logError(_ error: Error, request: URLRequest) {
        guard isLoggingEnabled else { return }
        
        print("\n" + String(repeating: "=", count: 80))
        print("❌ NETWORK ERROR")
        print(String(repeating: "=", count: 80))
        
        if let url = request.url {
            print("📍 URL: \(url.absoluteString)")
        }
        
        if let networkError = error as? NetworkError {
            print("🔴 Error: \(networkError.specificError ?? .unknownError)")
            print("💬 Message: \(networkError.localizedDescription)")
        } else {
            print("🔴 Error: \(error.localizedDescription)")
        }
        
        print(String(repeating: "=", count: 80) + "\n")
    }
    
    /// Returns an emoji based on the HTTP status code
    private func statusCodeEmoji(_ code: Int) -> String {
        switch code {
        case 200..<300: return "✅"
        case 300..<400: return "↩️"
        case 400..<500: return "⚠️"
        case 500..<600: return "❌"
        default: return "❓"
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
