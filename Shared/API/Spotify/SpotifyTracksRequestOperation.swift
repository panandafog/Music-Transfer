//
//  SpotifyTracksRequestOperation.swift
//  Music Transfer (iOS)
//
//  Created by panandafog on 10.10.2021.
//

import Foundation

class SpotifyTracksRequestOperation: MTOperation {
    
    typealias CompletionResult = Result<TracksData, TracksRequestError>
    typealias Completion = (CompletionResult) -> Void
    
    private let id: Int
    private let offset: Int
    private let tokensInfo: SpotifyService.TokensInfo
    private let completion: Completion
    
    private (set) var completed = false
    
    init(id: Int, offset: Int, tokensInfo: SpotifyService.TokensInfo, completion: @escaping Completion) {
        self.id = id
        self.offset = offset
        self.tokensInfo = tokensInfo
        self.completion = completion
    }
    
    func execute(executeCompletion: QueueCompletion?) {
        
        print(offset)
        
        var tmp = URLComponents()
        tmp.scheme = "https"
        tmp.host = "api.spotify.com"
        tmp.path = "/v1/me/tracks"
        tmp.queryItems = [
            URLQueryItem(name: "limit", value: "50"),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        
        guard let url = tmp.url else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let access_token = self.tokensInfo.access_token
        
        request.addValue("Bearer " + access_token, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { [self] (data, response, error) in
            
            guard error == nil else {
                complete(result: .failure(.unknown))
                executeCompletion?()
                return
            }
            
            guard let data = data, let dataString = String(data: data, encoding: .utf8) else {
                return
            }
            
            guard let tracksList = try? JSONDecoder().decode(SpotifySavedTracks.TracksList.self, from: data) else {
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 429 {
                    complete(result: .failure(.needToWait(seconds: Int(httpResponse.value(forHTTPHeaderField: "Retry-After") ?? "10") ?? 10)))
                    executeCompletion?()
                    return
                }
            }
            
            let tracks = SharedTrack.makeArray(from: tracksList)
            complete(result: .success(TracksData(tracks: tracks, gotNext: tracksList.next != nil)))
            executeCompletion?()
        }
        task.resume()
    }
    
    private func complete(result: CompletionResult) {
        completion(result)
        completed = true
    }
}

extension SpotifyTracksRequestOperation: Equatable {
    
    static func == (lhs: SpotifyTracksRequestOperation, rhs: SpotifyTracksRequestOperation) -> Bool {
        lhs.id == rhs.id
    }
}

extension SpotifyTracksRequestOperation {
    
    struct TracksData {
        let tracks: [SharedTrack]
        let gotNext: Bool
    }
    
    enum TracksRequestError: Error {
        case needToWait(seconds: Int)
        case unknown
    }
}
