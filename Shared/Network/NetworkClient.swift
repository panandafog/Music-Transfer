//
//  NetworkService.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 10.10.2021.
//

import SwiftUI

enum NetworkClient {

    private static let validStatusCodes = (200...299)
    private static let wrongCredsStatusCode = 401

    private static let emptyCodable: EmptyCodableError.Type? = nil

    static func perform<DataType: Decodable, ErrorType: Codable & Error>(
        request: RequestInfo,
        errorType: ErrorType.Type,
        completion: @escaping (Result<DataType, Error>, HTTPURLResponse?) -> Void
    ) {
        perform(
            request: request,
            errorHandler: { error, response in
                completion(.failure(error), response)
            },
            responseHandler: getResponseHandler(
                dataType: DataType.self,
                errorType: errorType,
                dataCompletion: completion,
                emptyCompletion: nil
            )
        )
    }

    static func perform<DataType: Decodable>(
        request: RequestInfo,
        completion: @escaping (Result<DataType, Error>, HTTPURLResponse?) -> Void
    ) {
        perform(
            request: request,
            errorHandler: { error, response in
                completion(.failure(error), response)
            },
            responseHandler: getResponseHandler(
                dataType: DataType.self,
                errorType: emptyCodable,
                dataCompletion: completion,
                emptyCompletion: nil
            )
        )
    }

    static func perform<ErrorType: Codable & Error>(
        request: RequestInfo,
        errorType: ErrorType.Type,
        completion: @escaping (Result<Void, Error>, HTTPURLResponse?) -> Void
    ) {
        perform(
            request: request,
            errorHandler: { error, response in
                completion(.failure(error), response)
            },
            responseHandler: getResponseHandler(
                dataType: emptyCodable,
                errorType: errorType,
                dataCompletion: nil,
                emptyCompletion: completion
            )
        )
    }

    static func perform(
        request: RequestInfo,
        completion: @escaping (Result<Void, Error>, HTTPURLResponse?) -> Void
    ) {
        perform(
            request: request,
            errorHandler: { error, response in
                completion(.failure(error), response)
            },
            responseHandler: getResponseHandler(
                dataType: emptyCodable,
                errorType: emptyCodable,
                dataCompletion: nil,
                emptyCompletion: completion
            )
        )
    }

    private static func perform(
        request requestInfo: RequestInfo,
        errorHandler: @escaping ((Error, HTTPURLResponse?) -> Void),
        responseHandler: @escaping ((URLRequest, HTTPURLResponse, Data?) -> Void)
    ) {
        var request = URLRequest(url: requestInfo.url)
        request.httpMethod = requestInfo.method.rawValue
        request.httpBody = requestInfo.body

        var requestBodyString = "none"
        if let body = requestInfo.body, let decoded = String(data: body, encoding: .utf8) {
            requestBodyString = decoded
        }
        
        for header in requestInfo.headers {
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }

        Logger.write(
            to: .network,
            "Sending request \(String(describing: request))",
            "Body: \(requestBodyString)"
        )

        URLSession.shared.dataTask(with: request) { data, response, error in
            let httpResponse = response as? HTTPURLResponse
            
            if let error = error {
                Logger.write(
                    to: .network,
                    type: .error,
                    "URL request failed.",
                    "Request: \(request.description)",
                    "Error: \(error.localizedDescription)"
                )
                errorHandler(
                    NetworkError(type: .unknown, message: error.localizedDescription),
                    httpResponse
                )
                return
            }

            guard let httpResponse = httpResponse else {
                Logger.write(
                    to: .network,
                    type: .error,
                    "Got no response on URL request.",
                    "Request: \(request.description)"
                )
                errorHandler(
                    NetworkError(type: .noResponse, message: nil),
                    httpResponse
                )
                return
            }

            responseHandler(request, httpResponse, data)
        }
        .resume()
    }
    
    private static func getResponseHandler<DataType: Decodable, ErrorType: Codable & Error>(
        dataType: DataType.Type? = nil,
        errorType: ErrorType.Type? = nil,
        dataCompletion: ((Result<DataType, Error>, HTTPURLResponse?) -> Void)? = nil,
        emptyCompletion: ((Result<Void, Error>, HTTPURLResponse?) -> Void)? = nil
    ) -> ((URLRequest, HTTPURLResponse, Data?) -> Void) {
        { request, response, data in
            Logger.write(
                to: .network,
                "Received response.",
                "Request: \(request.description)",
                "Code: \(response.statusCode)",
                "Response: \(response.description)",
                "Data: \(String(describing: String(data: data ?? Data(), encoding: .utf8)))"
            )
            
            if let data = data {
                if let errorType = errorType, let decoded = try? JSONDecoder().decode(errorType.self, from: data) {
                    Logger.write(
                        to: .network,
                        type: .error,
                        "Received error.",
                        "Code: \(response.statusCode)",
                        "Request: \(request.description)",
                        "Error: \(String(describing: decoded))",
                        "Response: \(response.description)"
                    )
                    dataCompletion?(.failure(decoded), response)
                    emptyCompletion?(.failure(decoded), response)
                    return
                }
            }

            guard validStatusCodes.contains(response.statusCode) else {
                Logger.write(
                    to: .network,
                    type: .error,
                    "Response on URL request has ivalid status code.",
                    "Code: \(response.statusCode)",
                    "Request: \(request.description)",
                    "Response: \(response.description)"
                )
                let requestError = NetworkError(
                    type: .invalidStatusCode(
                        code: response.statusCode
                    ),
                    message: nil
                )
                dataCompletion?(.failure(requestError), response)
                emptyCompletion?(.failure(requestError), response)
                return
            }

            guard let dataType = dataType else {
                emptyCompletion?(.success(()), response)

                return
            }

            if let data = data {
                if let decoded = try? JSONDecoder().decode(dataType.self, from: data) {
                    dataCompletion?(.success(decoded), response)
                } else {
                    Logger.write(
                        to: .network,
                        type: .error,
                        "Unable to decode response.",
                        "Code: \(response.statusCode)",
                        "Request: \(request.description)",
                        "Response: \(response.description)",
                        "Data: \(String(describing: String(data: data, encoding: .utf8)))"
                    )
                    dataCompletion?(
                        .failure(NetworkError(type: .decoding, message: nil)),
                        response
                    )
                }
            } else {
                dataCompletion?(
                    .failure(NetworkError(type: .noData, message: nil)),
                    response
                )
            }
        }
    }
}

extension NetworkClient {
    
    struct RequestInfo {
        let url: URL
        let method: RequestMethod
        let body: Data?
        let headers: [(key: String, value: String)]
    }
}

private extension NetworkClient {

    struct EmptyCodableError: Codable, Error { }
}
