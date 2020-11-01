//
//  ValidationServiceTests.swift
//  Hubb_AppTests
//
//  Created by Noah Placzek 2 on 10/18/20.
//  Copyright © 2020 Hubb. All rights reserved.
//
@testable import Hubb_App
import XCTest

class ValidationTests: XCTestCase {
    
    var validation: Validation!
    
    override func setUp() {
        super.setUp()
        validation = Validation()
    }
    
    override func tearDown() {
        super.tearDown()
        validation = nil
    }
    
    func test_is_valid_field() throws {
        XCTAssertThrowsError(try validation.validateLoginField(""))
        XCTAssertThrowsError(try validation.validateLoginField(" "))
        XCTAssertNoThrow(try validation.validateLoginField(" s"))
    }
    
    func test_is_valid_email() throws {
        XCTAssertThrowsError(try validation.validateEmail(""))
        XCTAssertThrowsError(try validation.validateEmail(" "))
        XCTAssertThrowsError(try validation.validateEmail(" s"))
        XCTAssertThrowsError(try validation.validateEmail("@depaul.edu"))
        XCTAssertThrowsError(try validation.validateEmail("noah@depaul.eduu"))
        XCTAssertNoThrow(try validation.validateEmail("noah@depaul.edu"))
    }
    func test_is_valid_password() throws {
        XCTAssertThrowsError(try validation.validatePassword(""))
        XCTAssertThrowsError(try validation.validatePassword(" "))
        XCTAssertThrowsError(try validation.validatePassword("sssss"))
        XCTAssertNoThrow(try validation.validatePassword("ssssss"))
    }
    
    func test_is_valid_input_field() throws {
        XCTAssertThrowsError(try validation.validateInputField("60 Characters Max"))
        XCTAssertThrowsError(try validation.validateInputField("Description of inappropriate content..."))
        XCTAssertNoThrow(try validation.validateInputField("This is new context"))
    }
}
