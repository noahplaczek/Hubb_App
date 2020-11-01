//
//  NewConversationViewController.swift
//  Hubb_App
//
//  Created by Noah Placzek 2 on 9/12/20.
//  Copyright © 2020 Hubb. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseAnalytics

class NewConversationViewController: UIViewController, UITextViewDelegate {
    
    public var completion: ((Group) -> (Void))?

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let groupNameLabel: UILabel = {
       let label = UILabel()
        label.text = "Chat Name"
        label.textColor = .black
        label.font = .systemFont(ofSize: 24, weight: .bold)
        return label
    }()
    
    var placeholder = ""
    
    private let groupNameField: UITextView = {
        let field = UITextView()
        field.autocapitalizationType = .sentences
        field.autocorrectionType = .default
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.text = "60 Characters Max"
        field.font = .systemFont(ofSize: 20)
        field.textColor = UIColor.lightGray
        field.backgroundColor = .white
        return field
    }()
    
    private let countingLabel: UILabel = {
       let label = UILabel()
        label.text = "60/60"
        label.textColor = UIColor.lightGray
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let createChatButton: UIButton = {
        let button = UIButton()
        button.setTitle("Create Chat", for: .normal)
        button.backgroundColor = ConversationsViewController.myColor
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if scrollView.height < 700 {
            self.scrollView.frame.origin.y = -60
        }
        if textView.textColor == .lightGray {
            textView.text = nil
            textView.textColor = .black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "60 Characters Max"
            textView.textColor = UIColor.lightGray
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        placeholder = textView.text
        countingLabel.text = "\(60 - textView.text.count)/60"
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
//            createGroup()
            return true
        }
        return textView.text.count + (text.count - range.length) <= 60
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        navigationController?.navigationBar.barTintColor = ConversationsViewController.myColor
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.tintColor = UIColor.white
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(dismissSelf))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(createGroup))
        createChatButton.addTarget(self, action: #selector(createGroup),
                              for: .touchUpInside)
        groupNameField.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(NewConversationViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard(_:)))
        self.scrollView.addGestureRecognizer(tapGesture)
     
        view.addSubview(scrollView)
        scrollView.addSubview(groupNameLabel)
        scrollView.addSubview(groupNameField)
        scrollView.addSubview(countingLabel)
        scrollView.addSubview(createChatButton)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        groupNameLabel.frame = CGRect(x: 35,
                                  y: (scrollView.height / 4),
                                  width: scrollView.width-60,
                                  height: 20) 
        
        groupNameField.frame = CGRect(x: 30,
                                  y: groupNameLabel.bottom+10,
                                  width: scrollView.width-60,
                                  height: 70)
        
        countingLabel.frame = CGRect(x: scrollView.width-80,
                                  y: groupNameField.bottom+5,
                                  width: 60,
                                  height: 15)
        
        createChatButton.frame = CGRect(x: 30,
                                  y: groupNameField.bottom+40,
                                  width: scrollView.width-60,
                                  height: 52)
    }
    
    
    @objc func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        self.scrollView.endEditing(true)
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
      self.scrollView.frame.origin.y = 0
    }
    
    @objc private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func createGroup() throws {
        
        groupNameField.resignFirstResponder()
        
        let validation = Validation()
        
        do {
            let groupName = try validation.validateInputField(groupNameField.text)
            
            guard let groupCreatorUid = UserDefaults.standard.value(forKey: "uid") as? String else {
                throw InputError.systemError
            }
            
            guard groupName != "Welcome to Hubb" else {
                showAlert(alertText: "Invalid Group Name", alertMessage: "Please enter a valid group name")
                return
            }
            
            let date = Date()
            let format = DateFormatter()
            format.dateFormat = "MM-dd-yyyy"
            let formattedDate = format.string(from: date)
            
            let newGroup = Group(id: nil, name: groupName, date: formattedDate, creator: groupCreatorUid, joined: true, members: 1, latestMessage: nil)
            
            DatabaseManager.shared.createNewConversation(group: newGroup, completion: { [weak self]  result in
                guard let strongSelf = self else {
                    self?.showAlert(alertText: "Uh oh", alertMessage: "There appears to have been an issue. Please try again")
                    return
                }
                switch result {
                case .success(let group):
                    strongSelf.dismiss(animated: true, completion: {
                        guard let strongSelf = self,
                              let groupId = group.id else {
                            return
                        }
                        
                        Analytics.logEvent("create_group", parameters: [
                            "new_group": groupId as NSObject,
                            "uid": group.creator as NSObject
                        ])
                        
                        strongSelf.completion?(group)
                    })
                case .failure(let error):
                    self?.showAlert(alertText: "Uh oh", alertMessage: "There appears to have been an issue. Please try again")
                    print("Failed to create conversation: \(error)")
                }
                
            })
        }
        catch InputError.emptyField {
            showAlert(alertText: "Missing Fields", alertMessage: "Please enter all information")
        }
        catch {
            showAlert(alertText: "Uh oh", alertMessage: "There appears to have been an issue. Please try again")
        }

    }

}

class TextFieldWithPadding: UITextField {
    var textPadding = UIEdgeInsets(
        top: 10,
        left: 10,
        bottom: 10,
        right: 10
    )

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.textRect(forBounds: bounds)
        return rect.inset(by: textPadding)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.editingRect(forBounds: bounds)
        return rect.inset(by: textPadding)
    }
}
