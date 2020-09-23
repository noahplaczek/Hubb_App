//
//  NewConversationViewController.swift
//  Hubb_App
//
//  Created by Noah Placzek 2 on 9/12/20.
//  Copyright © 2020 Hubb. All rights reserved.
//

import UIKit

class NewConversationViewController: UIViewController {
    
    public var completion: ((Group) -> (Void))?

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let groupNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .default
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Group Name..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let groupDescriptionField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .default
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Group Description (100 Characters)..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(dismissSelf))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(createGroup))
        
        groupNameField.delegate = self
        groupDescriptionField.delegate = self
     
        view.addSubview(scrollView)
        scrollView.addSubview(groupNameField)
        scrollView.addSubview(groupDescriptionField)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width / 3
        
        groupNameField.frame = CGRect(x: 30,
                                  y: (scrollView.width - size) / 2,
                                  width: scrollView.width-60,
                                  height: 52) // generally accepted standard
        
        groupDescriptionField.frame = CGRect(x: 30,
                                  y: groupNameField.bottom+10,
                                  width: scrollView.width-60,
                                  height: 52)
    }
    
    @objc private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func createGroup() {
        
        groupNameField.resignFirstResponder()
        groupDescriptionField.resignFirstResponder()

        guard
            let groupName = groupNameField.text,
            let groupDescription = groupDescriptionField.text,
            !groupName.isEmpty, !groupDescription.isEmpty else {
                groupCreationError(message: "Please enter both Group Name and Group Description")
                return
        }
        guard let groupCreatorUid = UserDefaults.standard.value(forKey: "uid") as? String else {
            return
        }

        let newGroup = Group(id: nil, name: groupName, description: groupDescription, creator: groupCreatorUid, latestMessage: nil)

        DatabaseManager.shared.createNewConversation(group: newGroup, completion: { [weak self]  result in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(let group):
                strongSelf.dismiss(animated: true, completion: {
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.completion?(group)
                })
            case .failure(let error):
                print("Failed to create conversation: \(error)")
            }

        })
    }
    
    func groupCreationError(message: String) {
        let alert = UIAlertController(title: "Whoops!", message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style:  .cancel, handler: nil))
        
        present(alert, animated: true)
    }

}

extension NewConversationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        if textField == groupNameField {
            groupDescriptionField.becomeFirstResponder()
        }
        else if textField == groupDescriptionField {
            createGroup()
        }

        return true
    }
}



