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
        usersRoute.get(use: getAllHandler)
        usersRoute.get(":userID", use: getHandler)
        usersRoute.get(":userID", "mappings", use: getMappingsHandler)
        usersRoute.post("siwa", use: signInWithApple)
        let basicAuthMiddleware = User.authenticator()
        let basicAuthGroup = usersRoute.grouped(basicAuthMiddleware)
        basicAuthGroup.post("login", use: loginHandler)
        
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = usersRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.post(use: createHandler)
        tokenAuthGroup.put(":userID", use: updateHandler)
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<User.Public> {
        let user = try req.content.decode(User.self)
        user.password = try Bcrypt.hash(user.password)
        let mapping = try Mapping(userID: user.requireID())
        return mapping.save(on: req.db).flatMap {
            user.save(on: req.db).map { user.convertToPublic() }
        }
    }
    
    func getAllHandler(_ req: Request) -> EventLoopFuture<[User.Public]> {
        User.query(on: req.db).all().convertToPublic()
    }
    
    func getHandler(_ req: Request) -> EventLoopFuture<User.Public> {
        User.find(req.parameters.get("userID"), on: req.db).unwrap(or: Abort(.notFound)).convertToPublic()
    }
    
    func getMappingsHandler(_ req: Request) -> EventLoopFuture<[Mapping]> {
        User.find(req.parameters.get("userID"), on: req.db).unwrap(or: Abort(.notFound)).flatMap { user in
            user.$mappings.get(on: req.db)
        }
    }
    
    func loginHandler(_ req: Request) throws -> EventLoopFuture<Token> {
        let user = try req.auth.require(User.self)
        let token = try Token.generate(for: user)
        return token.save(on: req.db).map { token }
    }
    
    func updateHandler(_ req: Request) throws -> EventLoopFuture<User.Public> {
        let updateUserData = try req.content.decode(User.self)
        return User.find(updateUserData.id, on: req.db)
            .unwrap(or: Abort(.notFound)).flatMap { user in
                user.name = updateUserData.name
                user.username = updateUserData.username
                user.password = updateUserData.password
                user.email = updateUserData.email
                user.phone = updateUserData.phone
                user.avatar = updateUserData.avatar
                user.gender = updateUserData.gender
                user.birth = updateUserData.birth
                user.country = updateUserData.country
                user.join = updateUserData.join
                user.siwaIdentifier = updateUserData.siwaIdentifier
                return user.save(on: req.db).map {
                    user.convertToPublic()
                }
            }
    }
    
    func signInWithApple(_ req: Request) throws -> EventLoopFuture<Token> {
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
}

struct SignInWithAppleToken: Content {
    let token: String
    let name: String?
}
