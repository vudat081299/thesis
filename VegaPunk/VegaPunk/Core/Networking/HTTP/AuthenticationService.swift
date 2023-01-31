//
//  Auth.swift
//  Social Messaging
//
//  Created by Vũ Quý Đạt  on 24/12/2020.
//

import UIKit
import Alamofire

class Auth {
    static func signIn(_ credential: Credential,
                       completion: (() -> ())? = nil,
                       onSuccess: (() -> ())? = nil,
                       onFailure: (() -> ())? = nil) {
        let _ = UserData.store(credential: credential)
        let headers: HTTPHeaders = [.authorization(username: credential.username, password: credential.password)]
        guard let query = queries.queryInfomation(.signIn) else { return }
        AF.request(query.genUrl(), method: query.httpMethod, headers: headers)
            .responseDecodable(of: Token.self) { response in
                switch response.result {
                case .success(let token):
                    print(token.value)
                    let _ = UserData.store(token: token)
                    getUserMapping(onSuccess: onSuccess)
                    break
                case .failure:
                    print("Sign in fail!")
                    if let onFailure = onFailure { onFailure() }
                    break
                }
                if let completion = completion { completion() }
            }
    }
    static func signUp(_ user: User, _ completion: (() -> ())? = nil) {
        guard let query = queries.queryInfomation(.signUp) else { return }
        var parameters: Parameters = [:]
        parameters["id"] = user.id
        parameters["name"] = user.name
        parameters["username"] = user.username
        if let email = user.email { parameters["email"] = email }
        if let join = user.join { parameters["join"] = join }
        if let phone = user.phone { parameters["phone"] = phone }
        if let birth = user.birth { parameters["birth"] = birth }
        if let avatar = user.avatar { parameters["avatar"] = avatar }
        if let password = user.password { parameters["password"] = password }
        if let country = user.country { parameters["country"] = country }
        if let gender = user.gender { parameters["gender"] = gender }
        AF.request(query.genUrl(), method: query.httpMethod, parameters: parameters)
            .responseDecodable(of: User.self) { response in
                switch response.result {
                case .success(let user):
                    print(user)
                    let _ = UserData.store(userInformation: user)
                    if let completion = completion { completion() }
                    break
                case .failure:
                    print("Sign up fail!")
                    break
                }
            }
    }
    static func getUserMapping(completion: (() -> ())? = nil,
                               onSuccess: (() -> ())? = nil,
                               onFailure: (() -> ())? = nil) {
        guard let query = queries.queryInfomation(.getUserMapping) else { return }
        AF.request(query.genUrl(), method: query.httpMethod)
            .responseDecodable(of: [ResolveMapping].self) { response in
                switch response.result {
                case .success(let resolvedMapping):
                    print(resolvedMapping)
                    guard var userData = UserData.retrieve() else { break }
                    if resolvedMapping.count > 0 {
                        userData.mappingId = resolvedMapping[0].id
                        let _ = userData.store()
                    }
                    if let onSuccess = onSuccess { onSuccess() }
                    break
                case .failure:
                    print("getUserMapping() fail!")
                    if let onFailure = onFailure { onFailure() }
                    break
                }
                if let completion = completion { completion() }
            }
    }
}
