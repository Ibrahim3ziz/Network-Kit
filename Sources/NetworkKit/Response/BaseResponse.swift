//
//  BaseResponse.swift
//  NetworkKit
//
//  Created by Ibrahim Abdul Aziz on 27/06/2025.
//

import Foundation

/// Represents a standard API response wrapper containing metadata and a data payload.
struct BaseResponse<T: Decodable> {
    var statusCode: Int?
    var code: Int?
    var message: String?
    var data: T?
}

extension BaseResponse: Decodable {
    enum CodingKeys: String, CodingKey {
        case statusCode
        case code
        case message
        case data
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        statusCode = try values.decodeIfPresent(Int.self, forKey: .statusCode)
        code = try values.decodeIfPresent(Int.self, forKey: .code)
        message = try values.decodeIfPresent(String.self, forKey: .message)
        data = try values.decodeIfPresent(T.self, forKey: .data)
    }
}
