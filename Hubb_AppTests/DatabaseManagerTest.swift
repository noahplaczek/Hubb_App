//
//  DatabaseManagerTest.swift
//  Hubb_AppTests
//
//  Created by Noah Placzek 2 on 10/20/20.
//  Copyright © 2020 Hubb. All rights reserved.
//

@testable import Hubb_App
import XCTest

class DatabaseManagerTest: XCTestCase {

    var validation: DatabaseManager!
    
    override func setUp() {
        super.setUp()
        validation = DatabaseManager()
    }
    
    override func tearDown() {
        super.tearDown()
        validation = nil 
    }
    
    func test_safe_email() {
        let safeEmail = DatabaseManager.safeEmail(emailAddress: "noah@depaul.edu")
        XCTAssertEqual("noah-depaul-edu", safeEmail)
    }
    
    func test_get_data_for_user() {
        
        validation.getDataForUser(uid: "6HtKplC9iSXHyyuhkYEwkfSe04y2", completion: { result in
            XCTAssertNoThrow(result)
        })
        
    }
    
    func test_insert_new_user_successfully() {
        let expectation = XCTestExpectation(description: "Finished inserting user")
    
        let chatUser = ChatAppUser(firstName: "firstName", lastName: "lastName", emailAddress: "noah-depaul-edu", uid: "uid")
        
        validation.insertUser(with: chatUser, completion: { result in
            
            XCTAssertNoThrow(result)
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 10)
    }
    
    func test_create_new_conversation() {
        
        let expectation = XCTestExpectation(description: "Finished creating conversation")
        let date = Date()
        let format = DateFormatter()
        format.dateFormat = "MM-dd-yyyy"
        let formattedDate = format.string(from: date)
        
        let newGroup = Group(id: nil, name: "groupName", date: formattedDate, creator: "6HtKplC9iSXHyyuhkYEwkfSe04y2", joined: true, members: 1, latestMessage: nil)
        
        validation.createNewConversation(group: newGroup, completion: { result in
            
            XCTAssertNoThrow(result)
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 10)
        
    }
    
    func test_successfully_pull_conversation_messages() {
        let expectation = XCTestExpectation(description: "Finished creating conversation")
        let groupId = "-MJoKd4YcRBbdLfh7_J5"
        
        validation.getAllMessagesForConversation(with: groupId, completion: { result in
            XCTAssertNoThrow(result)
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 10)
    }

}
