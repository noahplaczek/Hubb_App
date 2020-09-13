//
//  ProfileViewModel.swift
//  Hubb_App
//
//  Created by Noah Placzek 2 on 9/13/20.
//  Copyright © 2020 Hubb. All rights reserved.
//

import Foundation

enum ProfileViewModelType {
    case info, logout
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
    
    //let color: UIColor
    //let alignment
}
