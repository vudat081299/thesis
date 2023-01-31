//
//  ResourceRequest.swift
//  VegaPunk
//
//  Created by Dat Vu on 08/01/2023.
//

import Foundation
import Alamofire

var queries = Queries()
var bearerTokenHeaders: HTTPHeaders? {
    guard let token = (UserData.retrieve()?.token) else { return nil }
    return [.authorization(bearerToken: token)]
}

var pivotGlobal = DataCentral.getPivot()

class DataCentral {
    
    static func getPivot() -> [ResolvePivot] {
        if let data = UserDefaults.standard.data(forKey: "Pivot_SAVE_KEY") {
            do {
                let decoder = JSONDecoder()
                let pivot = try decoder.decode([ResolvePivot].self, from: data)
                return pivot
            } catch {
                print("Unable to Decode ResolvePivot (\(error))")
            }
        }
        return []
    }
    static func getMessages(of chatBoxId: UUID) -> [WebSocketMessage] {
        if let data = UserDefaults.standard.data(forKey: chatBoxId.uuidString + "_Messages_SAVE_KEY") {
            do {
                let decoder = JSONDecoder()
                let messages = try decoder.decode([WebSocketMessage].self, from: data)
                return messages
            } catch {
                print("Unable to Decode ResolvePivot (\(error))")
            }
        }
        return []
    }
    static func getMembers(of chatBoxId: UUID) -> [ResolveMapping] {
        if let data = UserDefaults.standard.data(forKey: chatBoxId.uuidString + "_Members_SAVE_KEY") {
            do {
                let decoder = JSONDecoder()
                let members = try decoder.decode([ResolveMapping].self, from: data)
                return members
            } catch {
                print("Unable to Decode ResolvePivot (\(error))")
            }
        }
        return []
    }
}

class RequestEngine {
    
    // MARK: - User
    static func getAllUsers(_ completion: (() -> ())? = nil) {
        guard let query = queries.queryInfomation(.getAllUsers) else { return }
        AF.request(query.genUrl(), method: query.httpMethod)
            .responseDecodable(of: [User].self) { response in
                switch response.result {
                case .success(let users):
                    print(users)
                    Friend(users).store()
                    if let completion = completion { completion() }
                    break
                case .failure:
                    print("getAllUsers fail!")
                    break
                }
            }
    }
    /// Update my user information
    static func updateUser(_ myUserInformation: User, _ completion: (() -> ())? = nil) {
        guard let query = queries.queryInfomation(.updateUser) else { return }
        AF.request(
            query.genUrl(),
            method: query.httpMethod,
            parameters: myUserInformation,
            headers: bearerTokenHeaders
        )
        .responseDecodable(of: User.self) { response in
            switch response.result {
            case .success(let users):
                let _ = UserData.store(userInformation: users)
                if let completion = completion { completion() }
                break
            case .failure:
                break
            }
        }
    }
    
    
    
    // MARK: - Mapping
    static func getAllMappings(_ completion: (() -> ())? = nil) {
        guard let query = queries.queryInfomation(.getAllMappings) else { return }
        AF.request(query.genUrl(), method: query.httpMethod)
            .responseDecodable(of: [ResolveMapping].self) { response in
                switch response.result {
                case .success(let mappings):
                    print(mappings)
                    Mappings(resolveMappings: mappings).store()
                    if let completion = completion { completion() }
                    break
                case .failure:
                    print("getAllMappings fail!")
                    break
                }
            }
    }
    static func getMyChatBoxes(_ completion: (() -> ())? = nil) {
        guard let query = queries.queryInfomation(.getMyChatBoxes) else { return }
        AF.request(query.genUrl(), method: query.httpMethod)
            .responseDecodable(of: [ChatBox].self) { response in
                switch response.result {
                case .success(let chatBoxes):
                    print(chatBoxes)
                    ChatBoxes(chatBoxes).store()
                    if let completion = completion { completion() }
                    break
                case .failure:
                    print("getMyChatBoxes fail!")
                    break
                }
            }
    }
    static func createChatBox(_ friendMappingId: UUID, _ completion: (() -> ())? = nil) {
        guard let query = queries.queryInfomation(.createChatBox),
              let userData = UserData.retrieve(),
              let myMappingId = userData.mappingId,
              let url = URL(string: query.genUrl()),
              let bearerTokenHeaders = bearerTokenHeaders else { return }
        let friendMappingIdString = friendMappingId.uuidString
        let myMappingIdString = myMappingId.uuidString
        let arrayData = [friendMappingIdString, myMappingIdString]
        var parameters: Parameters = [:]
        parameters["mappingIds"] = arrayData
        AF.request(
            url,
            method: query.httpMethod,
            parameters: parameters,
            headers: bearerTokenHeaders)
            .responseData { response in
                switch response.result {
                case .success:
                    print("Create chat box successful!")
                    if let completion = completion { completion() }
                    break
                case let .failure(error):
                    print(error)
                    break
                }
            }
    }
    
    
    
    // MARK: - Chat box
    static func getMemberInChatBox(_ chatBoxId: UUID, _ completion: (() -> ())? = nil) {
        guard let query = queries.queryInfomation(.getMemberInChatBox, chatBoxId) else { return }
        AF.request(query.genUrl(), method: query.httpMethod)
            .responseDecodable(of: [ResolveMapping].self) { response in
                switch response.result {
                case .success(let mappings):
                    print(mappings)
                    // write
                    do {
                        let encoder = JSONEncoder()
                        let data = try encoder.encode(mappings)
                        UserDefaults.standard.set(data, forKey: chatBoxId.uuidString + "_Members_SAVE_KEY")
                    } catch {
                        print("Unable to Encode Array of Mappings (\(error))")
                    }
                    if let completion = completion { completion() }
                    // read
//                    if let data = UserDefaults.standard.data(forKey: "notes") {
//                        do {
//                            // Create JSON Decoder
//                            let decoder = JSONDecoder()
//
//                            // Decode Note
//                            let notes = try decoder.decode([Note].self, from: data)
//
//                        } catch {
//                            print("Unable to Decode Notes (\(error))")
//                        }
//                    }
                    break
                case .failure:
                    print("getMemberInChatBox fail!")
                    break
                }
            }
    }
    static func getMessagesOfChatBox(_ chatBoxId: UUID, _ completion: (([WebSocketMessage]) -> ())? = nil) {
        guard let query = queries.queryInfomation(.getMessagesOfChatBox, chatBoxId) else { return }
        AF.request(query.genUrl(), method: query.httpMethod)
            .responseDecodable(of: [WebSocketMessage].self) { response in
                switch response.result {
                case .success(let messages):
                    print(messages)
                    do {
                        let encoder = JSONEncoder()
                        let data = try encoder.encode(messages)
                        UserDefaults.standard.set(data, forKey: chatBoxId.uuidString + "_Messages_SAVE_KEY")
                    } catch {
                        print("Unable to Encode Array of Mappings (\(error))")
                    }
                    if let completion = completion { completion(messages) }
                    break
                case .failure:
                    print("getMessagesOfChatBox fail!")
                    break
                }
            }
    }
    
    
    
    // MARK: - Messages
    static func createMessage(_ message: Message, _ completion: (() -> ())? = nil) {
        guard let query = queries.queryInfomation(.createMessage),
              let url = URL(string: query.genUrl()),
              let bearerTokenHeaders = bearerTokenHeaders else { return }
        var parameters: Parameters = [:]
        parameters["createdAt"] = message.createdAt
        parameters["sender"] = message.sender
        parameters["chatBoxId"] = message.chatBoxId
        parameters["message"] = message.message
        AF.request(
            url,
            method: query.httpMethod,
            parameters: parameters,
            headers: bearerTokenHeaders)
            .responseData { response in
                switch response.result {
                case .success:
                    print("Create chat box successful!")
                    if let completion = completion { completion() }
                    break
                case let .failure(error):
                    print(error)
                    break
                }
            }
    }
    
    
    
    // MARK: - Pivot
    static func getAllMappingPivots(_ completion: (() -> ())? = nil) {
        guard let query = queries.queryInfomation(.getAllMappingPivots) else { return }
        AF.request(query.genUrl(), method: query.httpMethod)
            .responseDecodable(of: [ResolvePivot].self) { response in
                switch response.result {
                case .success(let pivot):
                    print(pivot)
                    do {
                        let encoder = JSONEncoder()
                        let data = try encoder.encode(pivot)
                        UserDefaults.standard.set(data, forKey: "Pivot_SAVE_KEY")
                    } catch {
                        print("Unable to Encode Array of Mappings (\(error))")
                    }
                    pivotGlobal = DataCentral.getPivot()
                    if let completion = completion { completion() }
                    break
                case .failure:
                    break
                }
            }
    }
}


struct Message: Codable {
    let id: UUID?
    let sender: UUID
    let createdAt: String?
    let chatBoxId: UUID
    let message: String
    let mediaType: MediaType
}

enum MediaType: Int, Codable {
    case text, file
}

struct ChatBox: Codable {
    let id: UUID
    let name: String?
    let avatar: String?
}
extension ChatBox: Hashable {} // To use UICollectionViewDiffableDataSource

/// Resolve Mapping structure or other Structure have mapping(sibling) relationship.
struct ResolveMapping: Codable {
    let id: UUID
    let user: ResolveUUID
    
    func flatten() -> Mapping {
        Mapping(id: id, userId: user.id)
    }
}

struct Mapping: Codable {
    let id: UUID
    let userId: UUID
}

struct Pivot {
    let id: UUID
    let mappingId: UUID
    let chatBoxId: UUID
}

struct ResolvePivot: Codable {
    let id: UUID
    let mapping: ResolveUUID
    let chatBox: ResolveUUID
    
    func flatten() -> Pivot {
        Pivot(id: id, mappingId: mapping.id, chatBoxId: chatBox.id)
    }
}


struct ResolveUUID: Codable {
    let id: UUID
}

struct WebSocketMessage: Codable {
    let id: UUID
    let chatBox: ResolveUUID
    let message: String
    let sender: UUID
    let createdAt: String
}

struct User: Codable {
    var id: UUID?
    var name: String?
    var username: String?
    var email: String?
    var join: String?
    var bio: String?
    var phone: String?
    var birth: String?
    var siwaIdentifier: String?
    var avatar: String?
    var password: String?
    var country: String?
    var gender: Int?
}

