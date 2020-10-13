//
//  ReportContentViewController.swift
//  Hubb_App
//
//  Created by Noah Placzek 2 on 10/12/20.
//  Copyright © 2020 Hubb. All rights reserved.
//

import UIKit

class ReportContentViewController: UIViewController, UITextViewDelegate {

    public var completion: ((Bool) -> (Void))?
     
    private let groupId: String
    private let userId: String

    init(groupID: String, userID: String) {
        self.groupId = groupID
        self.userId = userID
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let reportContentLabel: UILabel = {
       let label = UILabel()
        label.text = "Report Content"
        label.textColor = .black
        label.font = .systemFont(ofSize: 24, weight: .bold)
        return label
    }()
    
    private let reportContentField: UITextView = {
        let field = UITextView()
        field.autocapitalizationType = .none
        field.autocorrectionType = .default
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.text = "Description of inappropriate content..."
        field.font = .systemFont(ofSize: 20)
        field.textColor = UIColor.lightGray
        field.backgroundColor = .white
        return field
    }()
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .lightGray {
            textView.text = nil
            textView.textColor = .black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Description of inappropriate content..."
            textView.textColor = UIColor.lightGray
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        navigationController?.navigationBar.barTintColor = ConversationsViewController.myColor
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.tintColor = UIColor.white
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(dismissSelf))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(reportContent))
        
        reportContentField.delegate = self
//        groupDescriptionField.delegate = self
     
        view.addSubview(scrollView)
        scrollView.addSubview(reportContentLabel)
        scrollView.addSubview(reportContentField)
//        scrollView.addSubview(countingLabel)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width / 3
        
        reportContentLabel.frame = CGRect(x: 35,
                                  y: (scrollView.width - size) / 2,
                                  width: scrollView.width-60,
                                  height: 25)
        
        reportContentField.frame = CGRect(x: 30,
                                  y: reportContentLabel.bottom+10,
                                  width: scrollView.width-60,
                                  height: 65)
        
    }
    
    @objc private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func reportContent() {
        
        reportContentField.resignFirstResponder()

        guard
            let reportReason = reportContentField.text,
            !reportReason.isEmpty
        else {
                groupCreationError(message: "Please enter a reason for reporting content")
                return
        }

        if groupId != "" {
            DatabaseManager.shared.reportGroup(groupId: groupId, reason: reportReason, completion: { [weak self]  success in
                guard let strongSelf = self else {
                    return
                }
                if success {
                    strongSelf.completion?(true)
                    strongSelf.dismiss(animated: true, completion: nil)
                }
                else {
                    print("Failed to report conversation")
                }
                
            })
        }
        else {
            DatabaseManager.shared.reportUser(userId: userId, reason: reportReason, completion: { [weak self]  success in
                guard let strongSelf = self else {
                    return
                }
                if success {
                    strongSelf.dismiss(animated: true, completion: nil)
                }
                else {
                    print("Failed to report user")
                }
                
            })
        }
        
        
    }
    
    func groupCreationError(message: String) {
        let alert = UIAlertController(title: "Whoops!", message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style:  .cancel, handler: nil))
        
        present(alert, animated: true)
    }

}

extension ReportContentViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        if textField == reportContentField {
            reportContent()
        }
        return true
    }
}
