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
    
    /// Returns dictionary node at child path
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        database.child("\(path)").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        })
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
            guard let users = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            
            if users.contains(where: {
                safeEmail == $0["email"] as? String
            }) {
                completion(true)
                return
            }
            
            completion(false)
        })
        
    }
    
    
    /// Insert new user to database
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void){
                // Get reference to existing user array, if exists. otherwise, create new
        database.child("users").observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard let strongSelf = self else {
                return
            }
            
            if var usersCollection = snapshot.value as? [[String: Any]] {
                // append to user dictionary
                let newElement = [
                    "email": DatabaseManager.safeEmail(emailAddress: user.emailAddress),
                    "first_name": user.firstName,
                    "last_name": user.lastName
                ]
                usersCollection.append(newElement)
                
                strongSelf.database.child("users").setValue(usersCollection, withCompletionBlock: {
                    error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    completion(true)
                })
                
            } else {
                // create the user array
                let newCollection: [[String: Any]] = [
                    [
                        "email": DatabaseManager.safeEmail(emailAddress: user.emailAddress),
                        "first_name": user.firstName,
                        "last_name": user.lastName
                    ]
                ]
                
                strongSelf.database.child("users").setValue(newCollection, withCompletionBlock: {
                    error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    completion(true)
                })
            }
        })
    }

}

// MARK: - Creating Conversations

extension DatabaseManager {
    
    public func createNewConversation(group: Group, completion: @escaping (Result<Group, Error>) -> Void) {
        let newGroupReference = database.child("group_detail").childByAutoId()
        
        let groupId = newGroupReference.key
        let dateString = ChatViewController.dateFormatter.string(from: Date())
//        let firstMessage = LatestMessage(date: dateString,
//                                         text: group.description,
//                                         isRead: false)
        
        let newGroup: [String : Any] = [
            "id": groupId as Any,
            "name": group.name,
            "description": group.description,
            "date_created": dateString,
            "members": [
                group.creator
            ],
            "last_message": [
                "date": dateString,
                "text": group.description,
                "isRead": false
            ]
        ]
        
        let newGroupInfo = Group(id: groupId, name: group.name, description: group.description, creator: group.creator)
        
        newGroupReference.setValue(newGroup, withCompletionBlock: { error, _ in
        guard error == nil else {
            completion(.failure(DatabaseError.failedToCreateGroup))
            return
        }
            completion(.success(newGroupInfo))
        })
    
    }

}
 
