//
//  Routing.swift
//  Message App
//
//  Created by Dat Vu on 04/12/2022.
//

import Foundation

var baseURL: String {
    "\(REQUEST_PROTOCOL)://\(domain!)/api"
}
func baseURL(_ groupRoute: RouteGroup = .users) -> String {
    "\(baseURL)/\(groupRoute.rawValue)"
}
enum RouteGroup: String {
    case users, messages, chatBoxes, mappings
}
