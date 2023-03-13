/// Copyright (c) 2021 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Vapor
import JWT
import Fluent

struct UsersController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let usersRoute = routes.grouped("api", "users")
        
//        usersRoute.get(use: getAllHandler)
//        usersRoute.get(":userId", use: getHandler)
//        usersRoute.get(":userId", "mapping", use: getMappingsHandler)
//        usersRoute.get("lastestUpdate", use: lastestUpdateTime)
//        usersRoute.get("from", ":time", use: getUsersFromTime)
        usersRoute.post("siwa", use: signInWithApple)
        usersRoute.post(use: createHandler)
        
        /// Basic Auth
        let basicAuthMiddleware = User.authenticator()
        let basicAuthGroup = usersRoute.grouped(basicAuthMiddleware)
        basicAuthGroup.post("login", use: loginHandler)
        
        /// Auth
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = usersRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.put(use: updateHandler)
        tokenAuthGroup.get(use: getAllHandler)
        tokenAuthGroup.get(":userId", use: getHandler)
//        tokenAuthGroup.get(":userId", "mapping", use: getMappingsHandler) // Deprecated
        tokenAuthGroup.get("lastestUpdate", use: lastestUpdateTime)
        tokenAuthGroup.get("from", ":time", use: getUsersFromTime)
        
        
        tokenAuthGroup.get(":userId", "chatBoxes", use: getchatBoxesHandler)
        tokenAuthGroup.post("chatBox", "create", use: addchatBoxesHandler)
    }
    
    
    // MARK: - Create
    func createHandler(_ req: Request) async throws -> User.Public {
        let newUser = try req.content.decode(User.self)
        newUser.password = try Bcrypt.hash(newUser.password)
        newUser.join = Date().milliStampString
        try await newUser.save(on: req.db)
        let otherUsers = try await User.query(on: req.db).all().filter { try $0.id != newUser.requireID() }
        let userIds = otherUsers.map { $0.id }
        webSocketManager.send(to: userIds, package: WebSocketPackage(type: .user, message: WebSocketPackageMessage(id: nil, createdAt: newUser.join, sender: nil, chatBoxId: nil, mediaType: nil, content: nil)))
        return newUser.convertToPublic()
    }
    
    
    // MARK: - Get
    func getAllHandler(_ req: Request) async throws -> [User.Public] {
        let users = try await User.query(on: req.db).all()
        return users.convertToPublic()
    }
    func getHandler(_ req: Request) async throws -> User.Public {
        guard let user = try await User.find(req.parameters.get("userId"), on: req.db) else {
           throw Abort(.notFound)
        }
        return user.convertToPublic()
    }
    
    func lastestUpdateTime(req: Request) async throws -> String {
        guard let lastestUpdateTime = try await User.query(on: req.db).max(\.$join) else {
            throw Abort(.notFound)
        }
        return lastestUpdateTime
    }
    func getUsersFromTime(req: Request) async throws -> [User.Public] {
        guard let timestamp = req.parameters.get("time") else {
            throw Abort(.badRequest)
        }
        let users = try await User.query(on: req.db).filter(\.$join > timestamp).all()
        return users.convertToPublic()
    }
    
    /// Rewrite
    func getchatBoxesHandler(_ req: Request) async throws -> [Chatbox] {
        let user = try req.auth.require(User.self)
        return try await user.$chatboxes.query(on: req.db).all()
    }
    
    
    // MARK: - Post
    func loginHandler(_ req: Request) async throws -> User.Public {
        let user = try req.auth.require(User.self)
        let token = try Token.generate(for: user)
        try await token.save(on: req.db)
        user.token = token
        return user.convertToPublic()
    }
    func signInWithApple(_ req: Request) throws -> EventLoopFuture<Token> {
        struct SignInWithAppleToken: Content {
            let token: String
            let name: String?
        }
        let data = try req.content.decode(SignInWithAppleToken.self)
        guard let appIdentifier = Environment.get("IOS_APPLICATION_IDENTIFIER") else {
            throw Abort(.internalServerError)
        }
        return req.jwt.apple.verify(data.token, applicationIdentifier: appIdentifier).flatMap { siwaToken -> EventLoopFuture<Token> in
            User.query(on: req.db).filter(\.$siwaIdentifier == siwaToken.subject.value).first().flatMap { user in
                let userFuture: EventLoopFuture<User>
                if let user = user {
                    userFuture = req.eventLoop.future(user)
                } else {
                    guard let email = siwaToken.email, let name = data.name else {
                        return req.eventLoop.future(error: Abort(.badRequest))
                    }
                    let user = User(name: name, username: email, password: UUID().uuidString, siwaIdentifier: siwaToken.subject.value)
                    userFuture = user.save(on: req.db).map { user }
                }
                return userFuture.flatMap { user in
                    let token: Token
                    do {
                        token = try Token.generate(for: user)
                    } catch {
                        return req.eventLoop.future(error: error)
                    }
                    return token.save(on: req.db).map { token }
                }
            }
        }
    }
    
    /// Rewrite
    func addchatBoxesHandler(_ req: Request) async throws -> HTTPStatus {
        struct ResolveCreateMappingChatBox: Codable {
            let mappingIds: [UUID]
        }
        let user = try req.auth.require(User.self)
        let resolvedModel = try req.content.decode(ResolveCreateMappingChatBox.self)
        let chatbox = Chatbox(name: "New group!")
        try await chatbox.save(on: req.db)
        let message = Message(sender: user.id, mediaType: MediaType.notify.rawValue, content: "👋 Hi! I just create this chat box, I'm @\(user.username)!", chatBoxId: chatbox.id!)
        try await message.save(on: req.db)
        
        for userId in resolvedModel.mappingIds {
            guard let user = try await User.find(userId, on: req.db) else {
                throw Abort(.notFound)
            }
            try await user.$chatboxes.attach(chatbox, on: req.db)
        }
        let package = WebSocketPackage(type: .chatBox, message: WebSocketPackageMessage(id: nil, createdAt: message.createdAt, sender: user.id, chatBoxId: chatbox.id, mediaType: .text, content: message.content))
        webSocketManager.send(to: resolvedModel.mappingIds, package: package)
        return .created
    }
    
    
    // MARK: - Update
    func updateHandler(_ req: Request) async throws -> User.Public {
        print("handler 😀😀😀: \(#function), line: \(#line)")
        let user = try req.auth.require(User.self)
        let updateUserData = try req.content.decode(User.ResolveUpdateModel.self)
        guard let user = try await User.find(user.id, on: req.db) else {
            throw Abort(.notFound)
        }
        user.name = updateUserData.name
        user.username = updateUserData.username
        if let email = updateUserData.email { user.email = email }
        if let phone = updateUserData.phone { user.phone = phone }
        if let avatar = updateUserData.avatar { user.avatar = avatar }
        if let gender = updateUserData.gender { user.gender = gender }
        if let birth = updateUserData.birth { user.birth = birth }
        if let country = updateUserData.country { user.country = country }
        if let join = updateUserData.join { user.join = join }
        if let bio = updateUserData.bio { user.bio = bio }
        print("handler 😀😀😀: \(#function), line: \(#line), \(String(describing: user.country))")
        try await user.save(on: req.db)
        return user.convertToPublic()
    }
    
}
