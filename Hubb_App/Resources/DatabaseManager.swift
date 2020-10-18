//
//  DatabaseManager.swift
//  Hubb_App
//
//  Created by Noah Placzek 2 on 9/12/20.
//  Copyright © 2020 Hubb. All rights reserved.
//

import Foundation
import FirebaseDatabase
import MessageKit

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
            guard let userInfo = snapshot.value as? [String: Any],
                let firstName: String = userInfo["first_name"] as? String,
                let lastName: String = userInfo["last_name"] as? String,
                let email: String = userInfo["email"] as? String,
                let uid: String = userInfo["uid"] as? String else {
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

        guard let groupId = newGroupReference.key,
              let senderName = UserDefaults.standard.value(forKey: "first_name") as? String else {
            completion(.failure(DatabaseError.failedToCreateGroup))
            return
        }
        let dateString = ChatViewController.dateFormatter.string(from: Date())
        
        let newGroup: [String: Any] = [
            "group_id": groupId,
            "name": group.name,
            "date": group.date,
            "creator_uid": group.creator,
            "flagged_info": [
                "total_flagged": 0
            ],
            "members": [
                group.creator
            ],
            "last_message": [
                "date": dateString,
                "text": "New Group",
                "is_read": false,
                "sender_name": senderName
            ]
        ]
        
        // Update Group Details with new group info
        newGroupReference.setValue(newGroup, withCompletionBlock: { [weak self] error, _ in
            guard error == nil,
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
                "content": group.name,
                // EDIT: will not just be text when photos are introduced
                "type": "text",
                "sender_uid": group.creator,
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
                // Update User to include Group ID in their groups
                strongSelf.database.child("users").child("\(group.creator)").observeSingleEvent(of: .value, with: { snapshot in
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
                    
                    strongSelf.database.child("users").child("\(group.creator)").child("groups").setValue(newUserGroups, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(.failure(DatabaseError.failedToCreateGroup))
                            return
                        }
                        
                        let latestMessage = LatestMessage(date: dateString, text: group.name, senderName: senderName, isRead: false)
                        
                        let newGroupInfo = Group(id: groupId, name: group.name, date: group.date, creator: group.creator, joined: true, members: 1, latestMessage: latestMessage)
                        
                        completion(.success(newGroupInfo))
                    })
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
                guard let currentMessageInfo = children.value as? [String: Any],
                    let senderName = currentMessageInfo["sender_name"] as? String,
                    let senderUid = currentMessageInfo["sender_uid"] as? String,
                    let content = currentMessageInfo["content"] as? String,
                    let messageId = currentMessageInfo["message_id"] as? String,
                    let dateString = currentMessageInfo["date"] as? String,
                    let type = currentMessageInfo["type"] as? String,
                    let _ = currentMessageInfo["group_id"] as? String,
                    let _ = currentMessageInfo["is_read"] as? Bool,
                    let date = ChatViewController.dateFormatter.date(from: dateString) else {
                        return
                }
                
                var kind: MessageKind?
                if type == "photo" {
                    guard let imageUrl = URL(string: content),
                          let placeHolder = UIImage(systemName: "person") else {
                        return
                    }
                    let media = Media(url: imageUrl,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                }
                else {
                    kind = .text(content)
                }
                
                guard let finalKind = kind else {
                    return
                }
                
                let sender = Sender(photoURL: "",
                                    senderId: senderUid,
                                    displayName: senderName)
                
                let currentMessage = Message(sender: sender,
                                         messageId: messageId,
                                         sentDate: date,
                                         kind: finalKind)
                
                messages.append(currentMessage)
            }
            completion(.success(messages))
        })
    }
        
    /// Fetches all existing conversations
    public func getAllConversations(completion: @escaping (Result<[Group], Error>) -> Void) {
        database.child("group_detail").observe(.value, with: {snapshot in
            guard let _ = snapshot.value as? [String: Any],
                  let uid = UserDefaults.standard.value(forKey: "uid") as? String else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            var groups = [Group]()
                        
            for children in snapshot.children.allObjects as! [DataSnapshot] {
                
                guard let currentGroupInfo = children.value as? [String: Any],
                    let groupId = currentGroupInfo["group_id"] as? String,
                    let name = currentGroupInfo["name"] as? String,
                    let creatorUid = currentGroupInfo["creator_uid"] as? String,
                    let creationDate = currentGroupInfo["date"] as? String,
                    let flaggedInfo = currentGroupInfo["flagged_info"] as? [String: Any],
                    let members = currentGroupInfo["members"] as? [String],
                    let totalFlagged = flaggedInfo["total_flagged"] as? Int,
                    let latestMessage = currentGroupInfo["last_message"] as? [String: Any],
                    let date = latestMessage["date"] as? String,
                    let message = latestMessage["text"] as? String,
                    let senderName = latestMessage["sender_name"] as? String,
                    let isRead = latestMessage["is_read"] as? Bool else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                
                if totalFlagged > 1 {
                    continue
                }
                
                var joined = false
                if members.contains(uid) {
                    joined = true
                }
                else {
                    joined = false
                }
                
                let totalMembers = members.count
                
                let latestMessageObject = LatestMessage(date: date, text: message, senderName: senderName, isRead: isRead)
                let currentGroup = Group(id: groupId, name: name, date: creationDate, creator: creatorUid, joined: joined, members: totalMembers, latestMessage: latestMessageObject)
                
                groups.insert(currentGroup, at: 0)
            }
            completion(.success(groups))
        })
        
    }
    
    public func getMyGroups(completion: @escaping (Result<[String], Error>) -> Void) {
        guard let uid = UserDefaults.standard.value(forKey: "uid") else {
            completion(.failure(DatabaseError.failedToFetch))
            return
        }
        database.child("users/\(uid)/groups").observe(.value, with: {snapshot in
        guard let groups = snapshot.value as? [String] else {
            completion(.failure(DatabaseError.failedToFetch))
            return
        }
            completion(.success(groups))
        })
    }
    
    // Sends a message with target conversation and message
    public func sendMessage(to groupId: String, newMessage: Message, sender: Sender, joined: Bool, completion: @escaping (Bool) -> Void) {

        let newMessageReference = database.child("group_messages").child(groupId).childByAutoId()

        guard let messageId = newMessageReference.key else {
            completion(false)
            return
        }
        
        let dateString = ChatViewController.dateFormatter.string(from: Date())
    
        var message = ""
        var type = ""
        switch newMessage.kind {
        case .text(let messageText):
            message = messageText
            type = "text"
        case .attributedText(_):
            break
        case .photo(let mediaItem):
            if let targetUrlString = mediaItem.url?.absoluteString {
                message = targetUrlString
                type = "photo"
            }
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .custom(_):
            break
        case .linkPreview(_):
            break
        }
        
        let newMessage: [String: Any] = [
            "content": message,
            "type": type,
            "sender_uid": sender.senderId,
            "sender_name": sender.displayName,
            "group_id": groupId as Any,
            "date": dateString,
            "is_read": false,
            "message_id": messageId
        ]
        
        newMessageReference.setValue(newMessage, withCompletionBlock: { [weak self] error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            
            var lastMessage: [String: Any] = [
                "date": dateString,
                "is_read": false,
                "text": message,
                "sender_name": sender.displayName
            ]

            if type == "photo" {
                lastMessage["text"] = "Sent a photo"
            }
            
            if joined == false {
                self?.database.child("group_detail/\(groupId)/members").observeSingleEvent(of: .value, with: { snapshot in
                    guard var members = snapshot.value as? [String],
                          let uid = UserDefaults.standard.value(forKey: "uid") as? String else {
                        return
                    }
                    
                    members.append(uid)
                    self?.database.child("group_detail/\(groupId)/members").setValue(members, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        print("successfully updated group members")
                        
                        self?.database.child("users/\(uid)/groups").observeSingleEvent(of: .value, with: { snapshot in
                            var newGroups: [String]
                            if let myGroups = snapshot.value as? [String] {
                                newGroups = myGroups
                                newGroups.append(groupId)
                            }
                            else {
                                newGroups = [groupId]
                            }
                            
                            self?.database.child("users/\(uid)/groups").setValue(newGroups, withCompletionBlock: { error, _ in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }
                                print("successfully updated last message")
                                
                                completion(true)
                            })
                            
                            
                        })
                        
                    })
                    
                    
                })
                    
                }
            if joined == true {
                completion(true)
            }
            })
            
//            self?.database.child("group_detail/\(groupId)/last_message").setValue(lastMessage, withCompletionBlock: { error, _ in
//                guard error == nil else {
//                    completion(false)
//                    return
//                }
//                print("successfully updated last message")
//                completion(true)
//            })
        }

}

// MARK: - Reporting Content
extension DatabaseManager {
    /// Insert new user to database
    public func reportGroup(groupId: String, reason: String, completion: @escaping (Bool) -> Void){
        
        database.child("group_detail/\(groupId)/flagged_info").observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard let flaggedInfo = snapshot.value as? [String: Any],
                  let totalFlagged = flaggedInfo["total_flagged"] as? Int else {
                completion(false)
                return
            }
            let newTotalFlagged = totalFlagged + 1
            
            var newFlags: [String]
            
            if var currentFlags = flaggedInfo["flagged_reason"] as? [String] {
                currentFlags.append(reason)
                newFlags = currentFlags
            }
                // Otherwise, create groups for user
            else {
                newFlags = [reason]
            }
            
            let newFlaggedInfo: [String: Any] = [
                "total_flagged": newTotalFlagged,
                "flagged_reason": newFlags
            ]
            
            self?.database.child("group_detail/\(groupId)/flagged_info").setValue(newFlaggedInfo, withCompletionBlock: { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                completion(true)
            })
            
        })
        
    }
    
    public func reportUser(userId: String, reason: String, completion: @escaping (Bool) -> Void){
        
        database.child("users/\(userId)").observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard let user = snapshot.value as? [String: Any] else {
                completion(false)
                return
            }
            
            var newFlags: [String]
            
            if var currentFlags = user["flagged_reason"] as? [String] {
                currentFlags.append(reason)
                newFlags = currentFlags
            }
                // Otherwise, create groups for user
            else {
                newFlags = [reason]
            }
            
            let newFlaggedInfo: [String] = newFlags
    
            self?.database.child("users/\(userId)/flagged_reason").setValue(newFlaggedInfo, withCompletionBlock: { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                completion(true)
            })
            
        })
        
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

// MARK: - Removing Observers
extension DatabaseManager {
    
    public func removeGroupObservers(completion: @escaping (Bool) -> Void) {
        guard let uid = UserDefaults.standard.value(forKey: "uid") else {
            completion(false)
            return
        }
        database.child("group_detail").removeAllObservers()
        database.child("users/\(uid)/groups").removeAllObservers()
        completion(true)
        //database.child("group_messages/\(id)").removeAllObservers()
    }
    
    public func removeMessagesObserver(groupId: String) {
        database.child("group_messages/\(groupId)").removeAllObservers()
    }
}
