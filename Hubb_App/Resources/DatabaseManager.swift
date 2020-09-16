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
                "date": group.latestMessage?.date as Any,
                "isRead": false,
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

//                let updatedUserInfo: [String : Any] = [
//                    "email": safeEmail,
//                    "first_name": firstName,
//                    "last_name": lastName,
//                    "uid": uid,
//                    "groups": newUserGroups
//                ]

                strongSelf.database.child("users").child("\(uid)").child("groups").setValue(newUserGroups, withCompletionBlock: { error, _ in
                    guard error == nil else {
                        completion(.failure(DatabaseError.failedToCreateGroup))
                        return
                    }
                    completion(.success(group))
                })
            })
        })
    }

} 
 
// MARK: - Sending messages / conversations
extension DatabaseManager {
    
    /// Retrieves all messages for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {

        database.child("group_messages/\(id)").observe(.value, with: {snapshot in
            guard let value = snapshot.value as? [String: Any] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            // convert dictionaries into our model. first need to validate all keys are present
            let messages: [Message] = value.compactMap({ dictionary in
                guard
                    let message = dictionary.value as? [String: Any],
                    let senderName = message["sender_name"] as? String,
                    let senderEmail = message["sender_email"] as? String,
                    let content = message["content"] as? String,
                    let dateString = message["date"] as? String,
                    let messageId = message["message_id"] as? String,
                    let _ = message["type"] as? String,
                    let _ = message["group_id"] as? String,
                    let _ = message["isRead"] as? Bool,
                    let date = ChatViewController.dateFormatter.date(from: dateString) else {
                        return nil
                }
                
                let sender = Sender(photoURL: "",
                                    senderId: senderEmail,
                                    displayName: senderName)

                return Message(sender: sender,
                               messageId: messageId,
                               sentDate: date,
                               kind: .text(content))
            })
            completion(.success(messages))
        })
    }
    
    /// Fetches and returns all conversations for the user with passed in email
//    public func getAllConversations(for email: String, completion: @escaping (Result<[Group], Error>) -> Void) {
//        database.child("\(email)/conversations").observe(.value, with: {snapshot in
//            guard let value = snapshot.value as? [[String: Any]] else {
//                completion(.failure(DatabaseError.failedToFetch))
//                return
//            }
//            // convert dictionaries into our model. first need to validate all keys are present
//            let conversations: [Conversation] = value.compactMap({ dictionary in
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
