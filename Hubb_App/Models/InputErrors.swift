//
//  ValidateUser.swift
//  Hubb_App
//
//  Created by Noah Placzek 2 on 10/18/20.
//  Copyright © 2020 Hubb. All rights reserved.
//

import Foundation

enum LoginError: Error  {
    case notCollegeEmail
    case emptyField
    case userExists
    case termsNotChecked
    case passwordLength
}

enum InputError: Error  {
    case emptyField
    case connectivity
    case systemError
}
