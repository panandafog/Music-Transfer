//
//  NetworkService.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 10.10.2021.
//

import SwiftUI

enum NetworkService {
    
    private static let validStatusCodes = (200...299)
    private static let wrongCredsStatusCode = 401
    
    static func perform<DataType: Codable>(request: URLRequest, completion: @escaping (Result<DataType, RequestError>) -> Void) {
        var requestBodyString = "none"
        if let body = request.httpBody, let decoded = String(data: body, encoding: .utf8) {
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
                completion(.failure(RequestError.clientError(message: error.localizedDescription)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                Logger.write(
                    to: .network,
                    type: .error,
                    "Got no response on URL request.",
                    "Request: \(request.description)"
                )
                completion(.failure(RequestError.serverError(message: nil)))
                return
            }
            
            guard validStatusCodes.contains(httpResponse.statusCode) else {
                Logger.write(
                    to: .network,
                    type: .error,
                    "Response on URL request has ivalid status code.",
                    "Code: \(httpResponse.statusCode)",
                    "Request: \(request.description)"
                )
                handleRequestError(request: request, completion: completion, data: data, response: response, error: error)
                return
            }
            
            guard let mimeType = httpResponse.mimeType,
                  mimeType == "application/json",
                  let tmpData = data
            else {
                Logger.write(
                    to: .network,
                    type: .error,
                    "Failed to get URL request response data.",
                    "Request: \(request.description)"
                )
                
                completion(.failure(.parsingError(message: nil)))
                return
            }
            
            decode(from: tmpData, completion: completion)
        }
        .resume()
    }
    
    static func perform(request: URLRequest, completion: @escaping (RequestError?) -> Void) {
        var requestBodyString = "none"
        if let body = request.httpBody, let decoded = String(data: body, encoding: .utf8) {
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
                completion(RequestError.clientError(message: error.localizedDescription))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                Logger.write(
                    to: .network,
                    type: .error,
                    "Got no response on URL request.",
                    "Request: \(request.description)"
                )
                completion(RequestError.serverError(message: nil))
                return
            }
            
            guard validStatusCodes.contains(httpResponse.statusCode) else {
                Logger.write(
                    to: .network,
                    type: .error,
                    "Response on URL request has ivalid status code.",
                    "Code: \(httpResponse.statusCode)",
                    "Request: \(request.description)"
                )
                handleRequestError(request: request, completion: completion, data: data, response: response, error: error)
                return
            }
            
            guard let mimeType = httpResponse.mimeType,
                  mimeType == "application/json",
                  let tmpData = data
            else {
                Logger.write(
                    to: .network,
                    type: .error,
                    "Failed to get URL request response data.",
                    "Request: \(request.description)"
                )
                
                completion(.parsingError(message: nil))
                return
            }
            
            completion(nil)
        }
        .resume()
    }
    
    static func decode<DataType: Codable>(from data: Data, completion: @escaping (Result<DataType, RequestError>) -> Void) {
        let decoded: DataType
        var errorMsg: String?
        
        do {
            decoded = try JSONDecoder().decode(DataType.self, from: data)
            Logger.write(
                to: .network,
                "Successfully decoded \(DataType.self).",
                "Decoded data: \(decoded)"
            )
            completion(.success(decoded))
            return
            
        } catch let DecodingError.dataCorrupted(context) {
            errorMsg = "Data corrupted" + context.debugDescription
            
        } catch let DecodingError.keyNotFound(key, context) {
            errorMsg = "Key '\(key)' not found:"
                + context.debugDescription
                + "codingPath:"
                + context.codingPath.debugDescription
            
        } catch let DecodingError.valueNotFound(value, context) {
            errorMsg = "Value '\(value)' not found:"
                + context.debugDescription
                + "codingPath:"
                + context.codingPath.debugDescription
            
        } catch let DecodingError.typeMismatch(type, context) {
            errorMsg = "Type '\(type)' mismatch:"
                + context.debugDescription
                + "codingPath:"
                + context.codingPath.debugDescription
            
        } catch {
            errorMsg = error.localizedDescription
        }
        
        // TODO
//        if let serverErrorMessage = try? JSONDecoder().decode(ResponseMessage.self, from: data) {
//            errorMsg = serverErrorMessage.message
//        }
        
        Logger.write(
            to: .network,
            type: .error,
            "Failed to decode data.",
            "Error: \(String(describing: errorMsg))"
        )
        completion(.failure(.clientError(message: errorMsg)))
    }
    
    private static func handleRequestError<DataType: Codable>(
        request: URLRequest,
        completion: @escaping (Result<DataType, RequestError>) -> Void,
        data: Data?,
        response: URLResponse?,
        error: Error?
    ) {
        var errorMessage: String?
        
        // TODO
//        if let tmpData = data {
//            errorMessage = try? JSONDecoder().decode(ResponseMessage.self, from: tmpData).message
//        }
        
        var error = RequestError.unknownError(message: errorMessage)
        
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case wrongCredsStatusCode:
                error = RequestError.wrongCredentials(message: errorMessage)
            default:
                if errorMessage == nil {
                    errorMessage = String(httpResponse.statusCode)
                }
                error = RequestError.serverError(message: errorMessage)
            }
        }
        
        completion(.failure(error))
    }
    
    private static func handleRequestError(
        request: URLRequest,
        completion: @escaping (RequestError?) -> Void,
        data: Data?,
        response: URLResponse?,
        error: Error?
    ) {
        var errorMessage: String?
        
        // TODO
//        if let tmpData = data {
//            errorMessage = try? JSONDecoder().decode(ResponseMessage.self, from: tmpData).message
//        }
        
        var error = RequestError.unknownError(message: errorMessage)
        
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case wrongCredsStatusCode:
                error = RequestError.wrongCredentials(message: errorMessage)
            default:
                if errorMessage == nil {
                    errorMessage = String(httpResponse.statusCode)
                }
                error = RequestError.serverError(message: errorMessage)
            }
        }
        
        completion(error)
    }
}
