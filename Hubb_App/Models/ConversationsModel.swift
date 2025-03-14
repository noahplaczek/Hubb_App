//
//  ConversationsModel.swift
//  Hubb_App
//
//  Created by Noah Placzek 2 on 9/12/20.
//  Copyright © 2020 Hubb. All rights reserved.
//

import Foundation

struct Group {
    let id: String?
    let name: String
    let date: String
    let creator: String
    var joined: Bool
    var members: Int
    let latestMessage: LatestMessage?
}

struct LatestMessage {
    let date: String
    let text: String
    let senderName: String
    let isRead: Bool
}
