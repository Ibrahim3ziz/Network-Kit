//
//  File.swift
//  NetworkKit
//
//  Created by Ibrahim Abdul Aziz on 09/03/2026.
//

import Foundation

// MARK: - String Extension for Pretty JSON
extension String {
    /// Returns a pretty-printed JSON string if the string is valid JSON
    var prettyPrintedJSON: String {
        guard let data = self.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: []),
              let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return self
        }
        return prettyString
    }
}
