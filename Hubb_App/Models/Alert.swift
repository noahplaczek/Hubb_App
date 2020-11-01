//
//  AlertPresentable.swift
//  Hubb_App
//
//  Created by Noah Placzek 2 on 10/21/20.
//  Copyright © 2020 Hubb. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    func showAlert(alertText: String, alertMessage: String) {
        let alert = UIAlertController(title: alertText, message: alertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
