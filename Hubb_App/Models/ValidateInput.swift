//
//  ValidateInput.swift
//  Hubb_App
//
//  Created by Noah Placzek 2 on 10/21/20.
//  Copyright © 2020 Hubb. All rights reserved.
//

import Foundation
import UIKit

struct Validation {
    func validateLoginField(_ text: String?) throws -> String {
        guard let text = text else { throw LoginError.emptyField }
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty else { throw LoginError.emptyField }
        return text
    }
    
    func validateEmail(_ text: String?) throws -> String {
        guard let text = text else { throw LoginError.emptyField }
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty else { throw LoginError.emptyField }
        guard text.hasSuffix("@depaul.edu") || text.hasSuffix("@uic.edu") else { throw LoginError.notCollegeEmail }
        guard text != "@depaul.edu" else { throw LoginError.notCollegeEmail }
        guard text != "@uic.edu" else { throw LoginError.notCollegeEmail }
        return text
    }
    
    func validatePassword(_ text: String?) throws -> String {
        guard let text = text else { throw LoginError.emptyField }
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty else { throw LoginError.emptyField }
        guard text.count >= 6 else { throw LoginError.passwordLength }
        return text
    }
    
    func validateInputField(_ text: String?) throws -> String {
        guard let text = text else { throw InputError.emptyField }
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty else { throw InputError.emptyField }
        guard !text.replacingOccurrences(of: "\n", with: "").isEmpty else { throw InputError.emptyField }
        guard text != "60 Characters Max" else { throw InputError.emptyField }
        guard text != "Description of inappropriate content..." else { throw InputError.emptyField }
        return text
    }
    
}
