//
//  WebSocket+Extensions.swift
//  App
//
//  Created by Vu Quy Dat on 15/12/2020.
//

import Vapor
import Foundation

extension WebSocket {
    func send(_ content: WSEncodeMessage) {
        let promise = eventLoop.makePromise(of: Void.self)
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(content) else { return }
        send(raw: data, opcode: .text, promise: promise)
        promise.futureResult.whenComplete { result in
            // Succeeded or failed to send.
            print(result)
        }
    }
}
