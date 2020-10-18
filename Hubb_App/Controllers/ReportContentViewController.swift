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
        field.autocapitalizationType = .sentences
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
    
    private let countingLabel: UILabel = {
       let label = UILabel()
        label.text = "400/400"
        label.textColor = UIColor.lightGray
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let reportButton: UIButton = {
        let button = UIButton()
        button.setTitle("Report", for: .normal)
        button.backgroundColor = ConversationsViewController.myColor
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if scrollView.height < 650 {
            self.scrollView.frame.origin.y = -70
        }
        else if scrollView.height < 700 {
            self.scrollView.frame.origin.y = -30
        }
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
    
    func textViewDidChange(_ textView: UITextView) {
        countingLabel.text = "\(400 - textView.text.count)/400"
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    return textView.text.count + (text.count - range.length) <= 400
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        navigationController?.navigationBar.barTintColor = ConversationsViewController.myColor
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.tintColor = UIColor.white
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(dismissSelf))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(reportContent))
        reportButton.addTarget(self, action: #selector(reportContent),
                              for: .touchUpInside)
        reportContentField.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(ReportContentViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard(_:)))
        self.scrollView.addGestureRecognizer(tapGesture)
     
        view.addSubview(scrollView)
        scrollView.addSubview(reportContentLabel)
        scrollView.addSubview(reportContentField)
        scrollView.addSubview(countingLabel)
        scrollView.addSubview(reportButton)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        reportContentLabel.frame = CGRect(x: 35,
                                  y: (scrollView.height / 4),
                                  width: scrollView.width-60,
                                  height: 20)
        reportContentField.frame = CGRect(x: 30,
                                  y: reportContentLabel.bottom+10,
                                  width: scrollView.width-60,
                                  height: 70)
        countingLabel.frame = CGRect(x: scrollView.width-100,
                                  y: reportContentField.bottom+5,
                                  width: 80,
                                  height: 15)
        reportButton.frame = CGRect(x: 30,
                                  y: reportContentField.bottom+40,
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
    
    @objc private func reportContent() {
        
        reportContentField.resignFirstResponder()

        guard
            let reportReason = reportContentField.text,
            reportReason != "Description of inappropriate content...",
            !reportReason.replacingOccurrences(of: " ", with: "").isEmpty,
            !reportReason.replacingOccurrences(of: "\n", with: "").isEmpty
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
        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style:  .cancel, handler: nil))
        
        present(alert, animated: true)
    }

}
