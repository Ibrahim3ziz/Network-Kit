//
//  BaseRequest.swift
//  NetworkKit
//
//  Created by Ibrahim Abdul Aziz on 27/06/2025.
//

import Foundation

/// Describes a network request specification including endpoint, headers, query parameters, and body.
public protocol BaseRequest {
    var baseURL: String { get }
    var scheme: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var parameter: [String: String]? { get }
    var body: [String: Any]? { get }
}

/// Supported HTTP request methods.
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// Provides default values for properties in `BaseRequest`.
extension BaseRequest {
    
    var scheme: String {
        return "https"
    }
    
    var baseURL: String {
        return ""
    }
    
    var method: HTTPMethod {
        return .get
    }
    
    var headers: [String: String]? {
        return [:]
    }
    
    var parameter: [String: String]? {
        return [:]
    }
    
    var body: [String: Any]? {
        return nil
    }
}

/// Constructs a `URLRequest` from the request configuration using `URLComponents`.
extension BaseRequest {
    public func asURLRequest() -> URLRequest {
        var components = URLComponents()
        components.scheme = scheme
        components.host = baseURL
        components.path = "/" + path
        
        if let parameter = parameter, !parameter.isEmpty {
            components.queryItems = parameter.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = components.url else {
            preconditionFailure("❌ Invalid URL: \(components)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        if let headers = headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        }
        return request
    }
}
