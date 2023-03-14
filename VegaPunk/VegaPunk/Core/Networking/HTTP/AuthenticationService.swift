//
//  Auth.swift
//  Social Messaging
//
//  Created by Vũ Quý Đạt  on 24/12/2020.
//

import UIKit
import Alamofire

class Auth {
    static func signIn(_ credential: Credential, completion: (() -> ())? = nil, onSuccess: (() -> ())? = nil, onFailure: (() -> ())? = nil) {
        AuthenticatedUser.store(credential: credential)
        let headers: HTTPHeaders = [.authorization(username: credential.username, password: credential.password)]
        guard let query = QueryBuilder.queryInfomation(.signIn) else { return }
        AF.request(query.genUrl(), method: query.httpMethod, headers: headers).responseDecodable(of: User.self) { response in
                switch response.result {
                case .success(let user):
                    if (user.id != nil) {
                        AuthenticatedUser.store(data: user)
                        ConcurrencyInteraction.mainQueueAsync(onSuccess)
                    } else {
                        ConcurrencyInteraction.mainQueueAsync(onFailure)
                    }
                    break
                case .failure(let error):
                    print("Request failure: file - \(#file), class - \(self), func - \(#function), line: \(#line) \n \(error)")
                    ConcurrencyInteraction.mainQueueAsync(onFailure)
                    break
                }
                ConcurrencyInteraction.mainQueueAsync(completion)
            }
    }
    static func signUp(_ user: User, _ completion: (() -> ())? = nil) {
        guard let query = QueryBuilder.queryInfomation(.signUp) else { return }
//        var parameters: Parameters = [:]
//        parameters["id"] = user.id
//        parameters["name"] = user.name
//        parameters["username"] = user.username
//        if let email = user.email { parameters["email"] = email }
//        if let gender = user.gender { parameters["gender"] = gender.rawValue }
//        if let join = user.join { parameters["join"] = join }
//        if let phone = user.phone { parameters["phone"] = phone }
//        if let birth = user.birth { parameters["birth"] = birth }
//        if let avatar = user.avatar { parameters["avatar"] = avatar }
//        if let password = user.password { parameters["password"] = password }
//        if let country = user.country { parameters["country"] = country }
//        if let country = user.country { parameters["country"] = country }
        AF.request(query.genUrl(), method: query.httpMethod, parameters: user).responseDecodable(of: User.self) { response in
            switch response.result {
            case .success(_):
                ConcurrencyInteraction.mainQueueAsync(completion)
                break
            case .failure:
                print("Request: failure, file - \(#file), class - \(self), func - \(#function), line: \(#line).")
                break
            }
        }
    }
//    static func getUserMapping(completion: (() -> ())? = nil,
//                               onSuccess: (() -> ())? = nil,
//                               onFailure: (() -> ())? = nil) {
//        guard let query = QueryBuilder.queryInfomation(.getUserMapping) else { return }
//        AF.request(query.genUrl(), method: query.httpMethod)
//            .responseDecodable(of: [ResolveMapping].self) { response in
//                switch response.result {
//                case .success(let resolvedMapping):
//                    print(resolvedMapping)
//                    guard var user = AuthenticatedUser.retrieve() else { break }
//                    if resolvedMapping.count > 0 {
//                        user.data?.mappingId = resolvedMapping[0].id
//                        user.store()
//                    }
//                    ConcurrencyInteraction.mainQueueAsync(onSuccess)
//                    break
//                case .failure:
//                    print("getUserMapping() fail!")
//                    ConcurrencyInteraction.mainQueueAsync(onFailure)
//                    break
//                }
//                ConcurrencyInteraction.mainQueueAsync(completion)
//            }
//    }
}
