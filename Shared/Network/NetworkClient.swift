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

    static func perform<DataType: Codable, ErrorType: Codable & Error>(
        url: URL,
        method: RequestMethod,
        body: Data?,
        errorType: ErrorType.Type,
        completion: @escaping (Result<DataType, Error>) -> Void
    ) {
        perform(
            url: url,
            method: method,
            body: body,
            errorHandler: { error in
                completion(.failure(error))
            },
            responseHandler: getResponseHandler(
                dataType: DataType.self,
                errorType: errorType,
                dataCompletion: completion,
                emptyCompletion: nil
            )
        )
    }

    static func perform<DataType: Codable>(
        url: URL,
        method: RequestMethod,
        body: Data?,
        completion: @escaping (Result<DataType, Error>) -> Void
    ) {
        perform(
            url: url,
            method: method,
            body: body,
            errorHandler: { error in
                completion(.failure(error))
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
        url: URL,
        method: RequestMethod,
        body: Data?,
        errorType: ErrorType.Type,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        perform(
            url: url,
            method: method,
            body: body,
            errorHandler: { error in
                completion(.failure(error))
            },
            responseHandler: getResponseHandler(
                dataType: emptyCodable,
                errorType: emptyCodable,
                dataCompletion: nil,
                emptyCompletion: completion
            )
        )
    }

    static func perform(
        url: URL,
        method: RequestMethod,
        body: Data?,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        perform(
            url: url,
            method: method,
            body: body,
            errorHandler: { error in
                completion(.failure(error))
            },
            responseHandler: getResponseHandler(
                dataType: emptyCodable,
                errorType: emptyCodable,
                dataCompletion: nil,
                emptyCompletion: completion
            )
        )
    }

    private static func getResponseHandler<DataType: Codable, ErrorType: Codable & Error>(
        dataType: DataType.Type? = nil,
        errorType: ErrorType.Type? = nil,
        dataCompletion: ((Result<DataType, Error>) -> Void)? = nil,
        emptyCompletion: ((Result<Void, Error>) -> Void)? = nil
    ) -> ((URLRequest, HTTPURLResponse, Data?) -> Void) {
        { request, response, data in
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
                    dataCompletion?(.failure(decoded))
                    emptyCompletion?(.failure(decoded))
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
                let requestError = RequestError(
                    type: .invalidStatusCode(
                        code: response.statusCode
                    ),
                    message: nil
                )
                dataCompletion?(.failure(requestError))
                emptyCompletion?(.failure(requestError))
                return
            }

            guard let dataType = dataType else {
                emptyCompletion?(.success(()))

                return
            }

            if let data = data {
                if let decoded = try? JSONDecoder().decode(dataType.self, from: data) {
                    dataCompletion?(.success(decoded))
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
                    dataCompletion?(.failure(RequestError(type: .decoding, message: nil)))
                }
            } else {
                dataCompletion?(.failure(RequestError(type: .noData, message: nil)))
            }
        }
    }

    private static func perform(
        url: URL,
        method: RequestMethod,
        body: Data?,
        errorHandler: @escaping ((Error) -> Void),
        responseHandler: @escaping ((URLRequest, HTTPURLResponse, Data?) -> Void)
    ) {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body

        var requestBodyString = "none"
        if let body = body, let decoded = String(data: body, encoding: .utf8) {
            requestBodyString = decoded
        }

        Logger.write(
            to: .network,
            "Sending request \(String(describing: request))",
            "Body: \(requestBodyString)"
        )

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                Logger.write(
                    to: .network,
                    type: .error,
                    "URL request failed.",
                    "Request: \(request.description)",
                    "Error: \(error.localizedDescription)"
                )
                errorHandler(RequestError(type: .unknown, message: error.localizedDescription))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                Logger.write(
                    to: .network,
                    type: .error,
                    "Got no response on URL request.",
                    "Request: \(request.description)"
                )
                errorHandler(RequestError(type: .noResponse, message: nil))
                return
            }

            responseHandler(request, httpResponse, data)
        }
        .resume()
    }
}

private extension NetworkClient {

    struct EmptyCodableError: Codable, Error { }
}
