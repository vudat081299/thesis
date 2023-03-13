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

import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "users"
    
    var token: Token?
    
    @ID
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "password")
    var password: String
    
    @Field(key: "email")
    var email: String?
    
    @Field(key: "phone")
    var phone: String?
    
    @Field(key: "avatar")
    var avatar: String?
    
    @Field(key: "gender")
    var gender: Gender?
    
    @Field(key: "birth")
    var birth: String?
    
    @Field(key: "country")
    var country: String?
    
    @Field(key: "join")
    var join: String?
    
    @Field(key: "bio")
    var bio: String?
    
    @Siblings(through: ChatboxMembers.self, from: \.$user, to: \.$chatbox)
    var chatboxes: [Chatbox]
    
    @OptionalField(key: "siwaIdentifier")
    var siwaIdentifier: String?
    
    init() {}
    
    init(id: UUID? = nil, name: String, username: String, password: String, email: String? = nil, phone: String? = nil, avatar: String? = nil, gender: Gender? = nil, birth: String? = nil, country: String? = nil, join: String? = nil, bio: String? = nil, siwaIdentifier: String? = nil) {
//        self.id = id
        self.name = name
        self.username = username
        self.password = password
        self.email = email
        self.phone = phone
        self.avatar = avatar
        self.gender = gender
        self.birth = birth
        self.country = country
        self.join = join
        self.bio = bio
        self.siwaIdentifier = siwaIdentifier
    }
    
    final class ResolveUpdateModel: Content {
        var id: UUID?
        var name: String
        var username: String
        
        var email: String?
        var phone: String?
        var avatar: String?
        var gender: Gender?
        var birth: String?
        var country: String?
        var join: String?
        var bio: String?
        
        init(id: UUID? = nil, name: String, username: String, email: String? = nil, phone: String? = nil, avatar: String? = nil, gender: Gender? = nil, birth: String? = nil, country: String? = nil, join: String? = nil, bio: String? = nil) {
            self.id = id
            self.name = name
            self.username = username
            self.email = email
            self.phone = phone
            self.avatar = avatar
            self.gender = gender
            self.birth = birth
            self.country = country
            self.join = join
            self.bio = bio
        }
    }
    
    final class Public: Content {
        var id: UUID?
        var token: Token?
        var name: String
        var username: String
        
        var email: String?
        var phone: String?
        var avatar: String?
        var gender: Gender?
        var birth: String?
        var country: String?
        var join: String?
        var bio: String?
        
        init(id: UUID?, token: Token? = nil, name: String, username: String, email: String?, phone: String?, avatar: String? = nil, gender: Gender? = nil, birth: String? = nil, country: String? = nil, join: String? = nil, bio: String? = nil) {
            self.id = id
            self.token = token
            self.name = name
            self.username = username
            
            self.email = email
            self.phone = phone
            self.avatar = avatar
            self.gender = gender
            self.birth = birth
            self.country = country
            self.join = join
            self.bio = bio
        }
    }
}

extension User {
    func convertToPublic() -> User.Public {
        return User.Public(id: id, token: token, name: name, username: username, email: email, phone: phone, avatar: avatar, gender: gender, birth: birth, country: country, join: join, bio: bio)
    }
}

extension EventLoopFuture where Value: User {
    func convertToPublic() -> EventLoopFuture<User.Public> {
        return self.map { user in
            return user.convertToPublic()
        }
    }
}

extension Collection where Element: User {
    func convertToPublic() -> [User.Public] {
        return self.map { $0.convertToPublic() }
    }
}

extension EventLoopFuture where Value == Array<User> {
    func convertToPublic() -> EventLoopFuture<[User.Public]> {
        return self.map { $0.convertToPublic() }
    }
}

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$username
    static let passwordHashKey = \User.$password
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}

extension User: ModelSessionAuthenticatable {}
extension User: ModelCredentialsAuthenticatable {}

enum Gender: Int, Content {
    case male, female, other
}
