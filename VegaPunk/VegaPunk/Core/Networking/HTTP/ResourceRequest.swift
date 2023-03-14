//
//  ResourceRequest.swift
//  VegaPunk
//
//  Created by Dat Vu on 08/01/2023.
//

import Foundation
import Alamofire

var bearerTokenHeaders: HTTPHeaders? {
    guard let token = (AuthenticatedUser.retrieve()?.data?.token?.value) else { return nil }
    return [.authorization(bearerToken: token)]
}

class RequestEngine {
    
    // MARK: - User
    static func getAllUsers(_ completion: (() -> ())? = nil, onSuccess: (() -> ())? = nil) {
        guard let query = QueryBuilder.queryInfomation(.getAllUsers),
              let bearerTokenHeaders = bearerTokenHeaders else { return }
        AF.request(query.genUrl(), method: query.httpMethod, headers: bearerTokenHeaders).responseDecodable(of: [User].self) { response in
            switch response.result {
            case .success(let users):
                Friend(users).store()
                Mappings(users).store()
                if let onSuccess = onSuccess { onSuccess() }
                break
            case .failure:
                print("Request: failure, file - \(#file), class - \(self), func - \(#function), line: \(#line).")
                break
            }
            if let completion = completion { completion() }
        }
    }
    /// Update my user information
    static func updateUser(_ data: User, completion: (() -> ())? = nil) {
        guard let query = QueryBuilder.queryInfomation(.updateUser),
              let bearerTokenHeaders = bearerTokenHeaders else { return }
        AF.request(query.genUrl(), method: query.httpMethod, parameters: data, headers: bearerTokenHeaders).responseDecodable(of: User.self) { response in
            switch response.result {
            case .success(let user):
                var user = user
                let authenticatedUser = AuthenticatedUser.retrieve()?.data
                user.token = authenticatedUser?.token
                AuthenticatedUser.store(data: user)
                if let completion = completion { completion() }
                break
            case .failure:
                print("Request: failure, file - \(#file), class - \(self), func - \(#function), line: \(#line).")
                break
            }
        }
    }
    
    
    
    // MARK: - Mapping
//    static func getAllMappings(_ completion: (() -> ())? = nil, onSuccess: (() -> ())? = nil) {
//        guard let query = QueryBuilder.queryInfomation(.getAllMappings) else { return }
//        AF.request(query.genUrl(), method: query.httpMethod)
//            .responseDecodable(of: [Mapping.Resolve].self) { response in
//                switch response.result {
//                case .success(let mappingResolves):
//                    print(mappingResolves)
//                    Mappings(resolves: mappingResolves).store()
//                    if let onSuccess = onSuccess { onSuccess() }
//                    break
//                case .failure:
//                    print("getAllMappings fail!")
//                    break
//                }
//                if let completion = completion { completion() }
//            }
//    }
    static func getMyChatBoxes(_ completion: (() -> ())? = nil, onSuccess: (() -> ())? = nil) {
        guard let query = QueryBuilder.queryInfomation(.getMyChatBoxes),
              let bearerTokenHeaders = bearerTokenHeaders else { return }
        AF.request(query.genUrl(), method: query.httpMethod, headers: bearerTokenHeaders).responseDecodable(of: [Chatbox].self) { response in
            switch response.result {
            case .success(let chatBoxes):
                Chatboxes(chatBoxes).store()
                if let onSuccess = onSuccess { onSuccess() }
                break
            case .failure:
                print("Request: failure, file - \(#file), class - \(self), func - \(#function), line: \(#line).")
                break
            }
            if let completion = completion { completion() }
        }
    }
    static func createChatBox(_ friendId: UUID, _ completion: (() -> ())? = nil) {
        guard let query = QueryBuilder.queryInfomation(.createChatBox),
              let user = AuthenticatedUser.retrieve(),
              let data = user.data,
              let userId = data.id,
              let url = URL(string: query.genUrl()),
              let bearerTokenHeaders = bearerTokenHeaders else { return }
        let friendIdString = friendId.uuidString
        let userIdString = userId.uuidString
        let arrayData = [friendIdString, userIdString]
        var parameters: Parameters = [:]
        parameters["mappingIds"] = arrayData
        AF.request(url, method: query.httpMethod, parameters: parameters, headers: bearerTokenHeaders).responseData { response in
            switch response.response?.statusCode {
            case 201:
//            switch response.result {
//            case .success:
                if let completion = completion { completion() }
                break
            default:
                print("Request: failure, file - \(#file), class - \(self), func - \(#function), line: \(#line).")
                break
            }
        }
    }
    
    
    
    // MARK: - Chat box
//    static func getMemberInChatBox(_ chatboxId: UUID, _ completion: (() -> ())? = nil) {
//        guard let query = QueryBuilder.queryInfomation(.getMemberInChatBox, ["chatBoxId": chatboxId.uuidString]) else { return }
//        AF.request(query.genUrl(), method: query.httpMethod)
//            .responseDecodable(of: [User].self) { response in
//                switch response.result {
//                case .success(let mappings):
//                    print(mappings)
//                    // write
//                    do {
//                        let encoder = JSONEncoder()
//                        let data = try encoder.encode(mappings)
//                        UserDefaults.standard.set(data, forKey: chatboxId.uuidString + "_Members_SAVE_KEY")
//                    } catch {
//                        print("Unable to Encode Array of Mappings (\(error))")
//                    }
//                    if let completion = completion { completion() }
//                    // read
////                    if let data = UserDefaults.standard.data(forKey: "notes") {
////                        do {
////                            // Create JSON Decoder
////                            let decoder = JSONDecoder()
////
////                            // Decode Note
////                            let notes = try decoder.decode([Note].self, from: data)
////
////                        } catch {
////                            print("Unable to Decode Notes (\(error))")
////                        }
////                    }
//                    break
//                case .failure:
//                    print("getMemberInChatBox fail!")
//                    break
//                }
//            }
//    }
    static func getMessagesOfChatBox(_ chatBoxId: UUID, onSuccess: (([ChatboxMessage.Resolve]) -> ())? = nil, completion: (() -> ())? = nil) {
        guard let query = QueryBuilder.queryInfomation(.getMessagesOfChatBox, ["chatBoxId": chatBoxId.uuidString]),
              let bearerTokenHeaders = bearerTokenHeaders else { return }
        AF.request(query.genUrl(), method: query.httpMethod, headers: bearerTokenHeaders).responseDecodable(of: [ChatboxMessage.Resolve].self) { response in
                switch response.result {
                case .success(let messages):
                    if let onSuccess = onSuccess { onSuccess(messages) }
                    break
                case .failure:
                    print("Request: failure, file - \(#file), class - \(self), func - \(#function), line: \(#line).")
                    break
                }
                if let completion = completion { completion() }
            }
    }
    static func getLastestUpdatedTimeStampChatBox(_ chatBoxId: UUID, _ completion: ((String) -> ())? = nil) {
        guard let query = QueryBuilder.queryInfomation(.getLastestUpdatedTimeStampChatBox, ["chatBoxId": chatBoxId.uuidString]),
              let bearerTokenHeaders = bearerTokenHeaders else { return }
        AF.request(query.genUrl(), method: query.httpMethod, headers: bearerTokenHeaders).responseDecodable(of: String.self) { response in
                switch response.result {
                case .success(let timeStamp):
                    if let completion = completion { completion(timeStamp) }
                    break
                case .failure:
                    print("Request: failure, file - \(#file), class - \(self), func - \(#function), line: \(#line).")
                    break
                }
            }
    }
    static func fetchMessages(from time: String, in chatBoxId: UUID, _ completion: (([ChatboxMessage.Resolve]) -> ())? = nil) {
        guard let query = QueryBuilder.queryInfomation(.getMessagesFromTimeChatBox, ["chatBoxId": chatBoxId.uuidString, "time": time]),
              let bearerTokenHeaders = bearerTokenHeaders else { return }
        AF.request(query.genUrl(), method: query.httpMethod, headers: bearerTokenHeaders).responseDecodable(of: [ChatboxMessage.Resolve].self) { response in
                switch response.result {
                case .success(let resolveMessages):
                    if (resolveMessages.count > 0) {
                        Messages(resolveMessages).store()
                    }
                    if let completion = completion { completion(resolveMessages) }
                    break
                case .failure:
                    print("Request: failure, file - \(#file), class - \(self), func - \(#function), line: \(#line).")
                    break
                }
            }
    }
    
    static func add(member userId: UUID, into chatBoxId: UUID, onSuccess: (() -> ())? = nil, onFailure: (() -> ())? = nil, completion: (() -> ())? = nil) {
        guard let query = QueryBuilder.queryInfomation(.addMemberIntoChatBox, ["chatBoxId": chatBoxId.uuidString]),
              let bearerTokenHeaders = bearerTokenHeaders else { return }
        let userIds = [userId.uuidString]
        var parameters: Parameters = [:]
        parameters["mappingIds"] = userIds
        AF.request(query.genUrl(), method: query.httpMethod, parameters: parameters, headers: bearerTokenHeaders).responseData { response in
            switch response.result {
            case .success:
                if let onSuccess = onSuccess { onSuccess() }
                break
            case let .failure(error):
                print("Request: failure, file - \(#file), class - \(self), func - \(#function), line: \(#line), \(error).")
                if let onFailure = onFailure { onFailure() }
                break
            }
            if let completion = completion { completion() }
        }
    }
    static func delete(member userId: UUID, from chatBoxId: UUID, onSuccess: (() -> ())? = nil, onFailure: (() -> ())? = nil, completion: (() -> ())? = nil) {
        guard let query = QueryBuilder.queryInfomation(.deleteMemberFromChatBox,
                                                       ["chatBoxId": chatBoxId.uuidString,
                                                        "mappingId": userId.uuidString]),
              let bearerTokenHeaders = bearerTokenHeaders else { return }
        AF.request(query.genUrl(), method: query.httpMethod, headers: bearerTokenHeaders).responseData { response in
            switch response.result {
            case .success:
                if let onSuccess = onSuccess { onSuccess() }
                break
            case let .failure(error):
                print("Request: failure, file - \(#file), class - \(self), func - \(#function), line: \(#line), \(error).")
                if let onFailure = onFailure { onFailure() }
                break
            }
            if let completion = completion { completion() }
        }
    }
    
    
    
    // MARK: - Messages
//    static func createMessage(_ message: ChatboxMessage, _ completion: (() -> ())? = nil) {
//        guard let query = QueryBuilder.queryInfomation(.createMessage),
//              let url = URL(string: query.genUrl()),
//              let bearerTokenHeaders = bearerTokenHeaders else { return }
//        var parameters: Parameters = [:]
//        parameters["createdAt"] = message.createdAt
//        parameters["sender"] = message.sender
//        parameters["chatBoxId"] = message.chatboxId
//        parameters["message"] = message.content
//        AF.request(url, method: query.httpMethod, parameters: parameters, headers: bearerTokenHeaders).responseData { response in
//            switch response.result {
//            case .success:
//                if let completion = completion { completion() }
//                break
//            case let .failure(error):
//                print(error)
//                break
//            }
//        }
//    }
    
    
    
    // MARK: - Pivot
    static func getAllMappingPivots(_ completion: (() -> ())? = nil, onSuccess: (() -> ())? = nil) {
        guard let query = QueryBuilder.queryInfomation(.getAllMappingPivots),
              let bearerTokenHeaders = bearerTokenHeaders else { return }
        AF.request(query.genUrl(), method: query.httpMethod, headers: bearerTokenHeaders).responseDecodable(of: [ChatboxMember.Resolve].self) { response in
            switch response.result {
            case .success(let pivot):
                ChatboxMembers(resolvePivots: pivot).store()
                if let onSuccess = onSuccess { onSuccess() }
                break
            case let .failure(error):
                print("Request: failure, file - \(#file), class - \(self), func - \(#function), line: \(#line), \(error).")
                break
            }
            if let completion = completion { completion() }
        }
    }
    
    
    // MARK: - File
    static func upload(_ data: Data, _ completion: ((String) -> ())? = nil) {
        guard let query = QueryBuilder.queryInfomation(.uploadFile),
              let url = URL(string: query.genUrl()),
              let bearerTokenHeaders = bearerTokenHeaders else { return }
        AF.upload(multipartFormData: { multipartFormData in
            //Parameter for Upload files
            multipartFormData.append(data, withName: "data")
        }, to: url, usingThreshold: UInt64.init(), // URL Here
                  method: query.httpMethod,
                  headers: bearerTokenHeaders) //pass header dictionary here
        .responseDecodable(of: ResolveId.self) { response in
            switch response.result {
            case .success(let object):
                if let completion = completion { completion(object.id) }
                break
            case let .failure(error):
                print("Request: failure, file - \(#file), class - \(self), func - \(#function), line: \(#line), \(error).")
                break
            }
        }
        
        
        
//        AF.request(
//            url,
//            method: query.httpMethod,
//            parameters: parameters,
//            headers: bearerTokenHeaders)
//        .responseDecodable(of: String.self) { response in
//                switch response.result {
//                case .success(let fileId):
//                    print("Create chat box successful!")
//                    if let completion = completion { completion(fileId) }
//                    break
//                case let .failure(error):
//                    print(error)
//                    break
//                }
//            }
    }
}




struct ResolveUUID: Codable {
    let id: UUID
}

struct ResolveId: Codable {
    let id: String
}



