//
//  DatabaseManager.swift
//  Hubb_App
//
//  Created by Noah Placzek 2 on 9/12/20.
//  Copyright © 2020 Hubb. All rights reserved.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    /// Takes an email and returns the email in the firebase format
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    public enum DatabaseError: Error {
        case failedToFetch, failedToCreateGroup
    }
    
}

// MARK: - Account Mgmt
extension DatabaseManager {
    
    /// Checks if user exists for given email
    /// Parameters
    /// - `email`:              Target email to be checked
    /// - `completion`:   Async closure to return with result
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        database.child("users").observeSingleEvent(of: .value, with: {snapshot in
            guard let users = snapshot.value as? [String: Any] else {
                completion(false)
                return
            }
            
            if users.contains(where: {
                guard let user = $0.value as? [String: String] else {
                    return false
                }
                return safeEmail == user["email"]
            }) {
                completion(true)
                return
            }
            
            completion(false)
        })
        
    }
    
    
    /// Insert new user to database
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void){

        let newElement: [String : Any] = [
            "email": DatabaseManager.safeEmail(emailAddress: user.emailAddress),
            "first_name": user.firstName,
            "last_name": user.lastName,
            "uid": user.uid,
        ]
        
        database.child("users").child("\(user.uid)").setValue(newElement, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
        
    }
    
    /// Returns dictionary node at child path
    public func getDataForUser(uid: String, completion: @escaping (Result<ChatAppUser, Error>) -> Void) {
        database.child("users").child(uid).observeSingleEvent(of: .value, with: { snapshot in
            guard let userInfo = snapshot.value as? [String: String],
                let firstName: String = userInfo["first_name"],
                let lastName: String = userInfo["last_name"],
                let email: String = userInfo["email"],
                let uid: String = userInfo["uid"] else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
            }
            
            let userData = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email, uid: uid)
            
            completion(.success(userData))
        })
    }

}

// MARK: - Creating Conversations

extension DatabaseManager {
    
    public func createNewConversation(group: Group, completion: @escaping (Result<Group, Error>) -> Void) {
        let newGroupReference = database.child("group_detail").childByAutoId()

        guard let groupId = newGroupReference.key else {
            completion(.failure(DatabaseError.failedToCreateGroup))
            return
        }
        let dateString = ChatViewController.dateFormatter.string(from: Date())

        let newGroup: [String: Any] = [
            "group_id": groupId,
            "name": group.name,
            "description": group.description,
            "creator_email": group.creator,
            "members": [
                group.creator
            ],
            "last_message": [
                "date": dateString,
                "text": group.description,
                "is_read": false
            ]
        ]
        
        // Update Group Details with new group info
        newGroupReference.setValue(newGroup, withCompletionBlock: { [weak self] error, _ in
        guard error == nil,
            let senderName = UserDefaults.standard.value(forKey: "first_name") as? String,
            let strongSelf = self else {
            completion(.failure(DatabaseError.failedToCreateGroup))
            return
        }
            print("succesfully added to Group Details")

            let firstMessageReference = strongSelf.database.child("group_messages").child(groupId).childByAutoId()

            guard let messageId = firstMessageReference.key else {
                completion(.failure(DatabaseError.failedToCreateGroup))
                return
            }

            let firstMessage: [String: Any] = [
                "content": group.description,
                // EDIT: will not just be text when photos are introduced
                "type": "text",
                "sender_email": group.creator,
                "sender_name": senderName,
                "group_id": groupId as Any,
                "date": dateString,
                "is_read": false,
                "message_id": messageId
            ]

            // Update Group Messages using group description as first message text
            firstMessageReference.setValue(firstMessage, withCompletionBlock: { error, _ in
                guard error == nil else {
                    completion(.failure(DatabaseError.failedToCreateGroup))
                    return
                }
                    print("succesfully added first group message")
                })
            
            guard let uid = UserDefaults.standard.value(forKey: "uid") else {
                return
            }
            
            // Update User to include Group ID in their groups
            strongSelf.database.child("users").child("\(uid)").observeSingleEvent(of: .value, with: { snapshot in
                guard let userInfo = snapshot.value as? [String: Any]
                else {
                    return
                }

                var newUserGroups: [String]

                // If user has already joined groups, append this group.
                if var currentUserGroups = userInfo["groups"] as? [String] {
                    currentUserGroups.append(groupId)
                    newUserGroups = currentUserGroups
                }
                // Otherwise, create groups for user
                else {
                    newUserGroups = [groupId]
                }

                strongSelf.database.child("users").child("\(uid)").child("groups").setValue(newUserGroups, withCompletionBlock: { error, _ in
                    guard error == nil else {
                        completion(.failure(DatabaseError.failedToCreateGroup))
                        return
                    }
                    
                    let latestMessage = LatestMessage(date: dateString, text: group.description, isRead: false)
                    
                    let newGroupInfo = Group(id: groupId, name: group.name, description: group.description, creator: group.creator, latestMessage: latestMessage)
                    
                    completion(.success(newGroupInfo))
                })
            })
        })
    }
    
} 

// MARK: - Sending messages / conversations
extension DatabaseManager {
    
    /// Retrieves all messages for a given group
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        
        database.child("group_messages/\(id)").observe(.value, with: {snapshot in
            guard let _ = snapshot.value else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            var messages = [Message]()
            
            for children in snapshot.children.allObjects as! [DataSnapshot] {
                guard let currentMessage = children.value as? [String: Any],
                    let senderName = currentMessage["sender_name"] as? String,
                    let senderEmail = currentMessage["sender_email"] as? String,
                    let content = currentMessage["content"] as? String,
                    let messageId = currentMessage["message_id"] as? String,
                    let dateString = currentMessage["date"] as? String,
                    let _ = currentMessage["type"] as? String,
                    let _ = currentMessage["group_id"] as? String,
                    let _ = currentMessage["is_read"] as? Bool,
                    let date = ChatViewController.dateFormatter.date(from: dateString) else {
                        return
                }
                
                let sender = Sender(photoURL: "",
                                    senderId: senderEmail,
                                    displayName: senderName)
                
                let newMessage = Message(sender: sender,
                                         messageId: messageId,
                                         sentDate: date,
                                         kind: .text(content))
                
                messages.append(newMessage)
            }
            completion(.success(messages))
        })
    }
        
    /// Fetches all existing conversations
    public func getAllConversations(completion: @escaping (Result<[Group], Error>) -> Void) {
        database.child("group_detail").observe(.value, with: { snapshot in
            guard let groupData = snapshot.value as? [String: Any] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            // convert dictionaries into our model. first need to validate all keys are present
            let allGroups: [Group] = groupData.compactMap({ dictionary in
                guard
                    let groupInfo = dictionary.value as? [String: Any],
                    let groupId = groupInfo["group_id"] as? String,
                    let name = groupInfo["name"] as? String,
                    let creatorName = groupInfo["creator_email"] as? String,
                    let description = groupInfo["description"] as? String,
                    let latestMessage = groupInfo["last_message"] as? [String: Any],
                    let date = latestMessage["date"] as? String,
                    let message = latestMessage["text"] as? String,
                    let isRead = latestMessage["is_read"] as? Bool
                    else{
                        return nil
                }
                // create and return model
                let latestMessageObject = LatestMessage(date: date, text: message, isRead: isRead)
                return Group(id: groupId, name: name, description: description, creator: creatorName, latestMessage: latestMessageObject)
            })
            completion(.success(allGroups))
        
            
        })
        
    }
    
    //     Sends a message with target conversation and message
    public func sendMessage(to groupId: String, messageText: String, sender: Sender, completion: @escaping (Bool) -> Void) {

        let newMessageReference = database.child("group_messages").child(groupId).childByAutoId()

        guard let messageId = newMessageReference.key,
            let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeSenderEmail = DatabaseManager.safeEmail(emailAddress: senderEmail)
        let dateString = ChatViewController.dateFormatter.string(from: Date())
        
        let newMessage: [String: Any] = [
            "content": messageText,
            // EDIT: will not just be text when photos are introduced
            "type": "text",
            "sender_email": safeSenderEmail,
            "sender_name": sender.displayName,
            "group_id": groupId as Any,
            "date": dateString,
            "is_read": false,
            "message_id": messageId
        ]

        // Update Group Messages using group description as first message text
        newMessageReference.setValue(newMessage, withCompletionBlock: { error, _ in
            guard error == nil else {
                return
            }
//                print("succesfully added group message")
            })
        
//        let message = Message(sender: sender,
//                              messageId: messageId,
//                              sentDate: Date(),
//                              kind: .text(messageText))
//
//        // add new message to messages
//        database.child("\(conversation)/messages").observeSingleEvent(of: .value, with: { [weak self] snapshot in
//            guard let strongSelf = self else {
//                return
//            }
//            guard var currentMessage = snapshot.value as? [[String: Any]] else {
//                completion(false)
//                return
//            }
//            let messageDate = newMessage.sentDate
//            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
//            var message = ""
//
//            // text, photo, video
//            switch newMessage.kind {
//            case .text(let messageText):
//                message = messageText
//            case .attributedText(_):
//                break
//            case .photo(let mediaItem):
//                if let targetUrlString = mediaItem.url?.absoluteString {
//                    message = targetUrlString
//                }
//            case .video(_):
//                break
//            case .location(_):
//                break
//            case .emoji(_):
//                break
//            case .audio(_):
//                break
//            case .contact(_):
//                break
//            case .linkPreview(_):
//                break
//            case .custom(_):
//                break
//            }
//
//            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
//                completion(false)
//                return
//            }
//            let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
//
//            let newMessageEntry: [String: Any] = [
//                "id": newMessage.messageId,
//                "type": newMessage.kind.messageKindString,
//                "content": message,
//                "date": dateString,
//                "sender_email": currentUserEmail,
//                "isRead": false,
//                "name": name
//            ]
//
//            currentMessage.append(newMessageEntry)
//
//            strongSelf.database.child("\(conversation)/messages").setValue(currentMessage) { (error, _) in
//                guard error == nil else {
//                    completion(false)
//                    return
//                }
//
//                // Update latest message for both users
//                strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
//                    var databaseEntryConversations = [[String: Any]]()
//                    let updatedValue: [String: Any] = [
//                        "date": dateString,
//                        "is_read": false,
//                        "message": message
//                    ]
//
//                    if var currentUserConversations = snapshot.value as? [[String: Any]] {
//                        // Find where conversation ID is current conversation ID
//                        var position: Int = 0
//                        for var conversationDictionary in currentUserConversations {
//                            if let currentId = conversationDictionary["id"] as? String,
//                                currentId == conversation {
//
//                                conversationDictionary["latest_message"] = updatedValue
//                                currentUserConversations[position] = conversationDictionary
//                                databaseEntryConversations = currentUserConversations
//                                break
//                            }
//                            position += 1
//                        }
//
//                        if currentUserConversations.count == position {
//
//                            let newConversationData: [String: Any] = [
//                                "id": conversation,
//                                "other_user_email": DatabaseManager.safeEmail(emailAddress: otherUserEmail),
//                                "name": name,
//                                "latest_message": updatedValue
//                            ]
//
//                            currentUserConversations.append(newConversationData)
//                            databaseEntryConversations = currentUserConversations
//                        }
//
//                    }
//                    else {
//
//                        let newConversationData: [String: Any] = [
//                            "id": conversation,
//                            "other_user_email": DatabaseManager.safeEmail(emailAddress: otherUserEmail),
//                            "name": name,
//                            "latest_message": updatedValue
//                        ]
//
//                        databaseEntryConversations = [
//                            newConversationData
//                        ]
//                    }
//
//                    strongSelf.database.child("\(currentEmail)/conversations").setValue(databaseEntryConversations, withCompletionBlock: { error, _ in
//                        guard error == nil else {
//                            completion(false)
//                            return
//                        }
//                    })
//
//                })
//
//
//                // update latest message for recipient user
//                strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
//                    guard var otherUserConversations = snapshot.value as? [[String: Any]] else {
//                        completion(false)
//                        return
//                    }
//
//                    // Find where conversation ID is current conversation ID
//                    var position: Int = 0
//
//                    for var conversationDictionary in otherUserConversations {
//                        if let currentId = conversationDictionary["id"] as? String,
//                            currentId == conversation {
//                            let updatedValue: [String: Any] = [
//                                "date": dateString,
//                                "is_read": false,
//                                "message": message
//                            ]
//                            conversationDictionary["latest_message"] = updatedValue
//
//                            otherUserConversations[position] = conversationDictionary
//
//                            strongSelf.database.child("\(otherUserEmail)/conversations").setValue(otherUserConversations, withCompletionBlock: { error, _ in
//                                guard error == nil else {
//                                    completion(false)
//                                    return
//                                }
//                            })
//                            break
//                        }
//                        position += 1
//                    }
//                })
//                completion(true)
//            }
//
//
//        })
    }
    
    
    /// Fetches and returns all conversations for the user with passed in uid
//    public func getAllConversationsForUser(for uid: String, completion: @escaping (Result<[Group], Error>) -> Void) {
//        database.child("users/\(uid)/groups").observe(.value, with: { [weak self] snapshot in
//            guard let joinedGroups = snapshot.value as? [String],
//                let strongSelf = self else {
//                    completion(.failure(DatabaseError.failedToFetch))
//                    return
//            }
//
//            strongSelf.database.child("group_detail").observeSingleEvent(of: .value, with: { snapshot in
//                guard let currentGroups = snapshot.value as? [String: Any] else {
//                    return
//                }
//
//
//
//            })
//
//            // convert dictionaries into our model. first need to validate all keys are present
//            let groups: [Group] = value.compactMap({ dictionary in
//                print(dictionary)
//                guard let conversationId = dictionary["id"] as? String,
//                    let name = dictionary["name"] as? String,
//                    let otherUserEmail = dictionary["other_user_email"] as? String,
//                    let latestMessage = dictionary["latest_message"] as? [String: Any],
//                    let date = latestMessage["date"] as? String,
//                    let message = latestMessage["message"] as? String,
//                    let isRead = latestMessage["is_read"] as? Bool else{
//                        return nil
//                }
//                // create and return model
//                let latestMessageObject = LatestMessage(date: date, text: message, isRead: isRead)
//                return Conversation(id: conversationId, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObject)
//            })
//            completion(.success(conversations))
//
//        })
//    }
    
}
