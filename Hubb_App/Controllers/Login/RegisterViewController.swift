//
//  RegisterViewController.swift
//  Hubb_App
//
//  Created by Noah Placzek 2 on 9/12/20.
//  Copyright © 2020 Hubb. All rights reserved.
//

import UIKit
import FirebaseAuth
//import JGProgressHUD

class RegisterViewController: UIViewController {
    
//    private let spinner = JGProgressHUD(style: .dark)
    
    private var listeningForConversations = false
    private var activeTextField : UITextField? = nil
    private var isChecked = false
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    // Profile Picture
//    private let imageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.image = UIImage(systemName: "person.circle")
//        imageView.tintColor = .gray
//        imageView.contentMode = .scaleAspectFit
//        imageView.layer.masksToBounds = true
//        imageView.layer.borderWidth = 2
//        imageView.layer.borderColor = UIColor.lightGray.cgColor
//        return imageView
//    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let sloganLabel: UILabel = {
        let label = UILabel()
        label.text = "Where your university comes alive"
        label.font = .italicSystemFont(ofSize: 20)
//            .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = ConversationsViewController.myColor
        return label
    }()
    
    private let firstNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .words
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.textColor = UIColor.gray
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.attributedPlaceholder = NSAttributedString(string: "First Name...", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()
    
    private let lastNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .words
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.textColor = UIColor.gray
        field.attributedPlaceholder = NSAttributedString(string: "Last Name...", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.textColor = UIColor.gray
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.attributedPlaceholder = NSAttributedString(string: "School Email...", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.textColor = UIColor.gray
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.attributedPlaceholder = NSAttributedString(string: "Password...", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        field.isSecureTextEntry = true
        return field
    }()
    
    private let registerButton: UIButton = {
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = ConversationsViewController.myColor
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private let privacyPolicyLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.gray
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 2
        label.text = "By checking this you agree to Hubb's"
        return label
    }()
    
    private let privacyPolicyButton: UIButton = {
        let button = UIButton()
        button.setTitle("Privacy Policy", for: .normal)
        button.backgroundColor = .white
        button.setTitleColor(.blue, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        return button
    }()
    
    private let termsButton: UIButton = {
        let button = UIButton()
        button.setTitle(" and Terms", for: .normal)
        button.backgroundColor = .white
        button.setTitleColor(.blue, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        return button
    }()
    
    private let checkMark: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "square")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "New Account"
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Login", style: .done, target: self, action: #selector(didTapLogin))
        
        registerButton.addTarget(self, action: #selector(registerButtonTapped),
                              for: .touchUpInside)
        privacyPolicyButton.addTarget(self, action: #selector(didTapPrivacyPolicy),
                              for: .touchUpInside)
        termsButton.addTarget(self, action: #selector(didTapTerms),
                              for: .touchUpInside)
        let gesture = UITapGestureRecognizer(target: self,
                                             action: #selector(checkboxTapped))
        checkMark.addGestureRecognizer(gesture)
        checkMark.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(RegisterViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(RegisterViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard(_:)))
        self.scrollView.addGestureRecognizer(tapGesture)
        
        firstNameField.delegate = self
        lastNameField.delegate = self
        emailField.delegate = self
        passwordField.delegate = self
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(sloganLabel)
        scrollView.addSubview(firstNameField)
        scrollView.addSubview(lastNameField)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(registerButton)
        scrollView.addSubview(checkMark)
        scrollView.addSubview(privacyPolicyLabel)
        scrollView.addSubview(privacyPolicyButton)
        scrollView.addSubview(termsButton)
        // 896 / XX = 52
        // 40
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        var offset: CGFloat
        
        if let activeTextField = activeTextField {
            if activeTextField == lastNameField {
                offset = keyboardSize.height - (scrollView.height / 17)
            }
            else if activeTextField == emailField {
                offset = keyboardSize.height - (scrollView.height / 7)
            }
            else if activeTextField == passwordField {
                offset = 20
            }
            else {
                offset = keyboardSize.height
            }
            
            self.scrollView.frame.origin.y = offset - keyboardSize.height
        }
    }
    
    @objc func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        self.scrollView.endEditing(true)
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
      self.scrollView.frame.origin.y = 0
    }
    
    @objc private func didTapPrivacyPolicy() {
        UIApplication.shared.open(NSURL(string:"https://joinhubb.com/privacy-policy/")! as URL)
    }
    @objc private func didTapTerms() {
        UIApplication.shared.open(NSURL(string:"https://joinhubb.com/terms-of-service//")! as URL)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width / 3
        let fieldHeight = scrollView.height / 17
        
        imageView.frame = CGRect(x: (scrollView.width-size)/2,
                                 y: scrollView.height/9,
                                 width: size,
                                 height: size)
        sloganLabel.frame = CGRect(x: (scrollView.width-301)/2,
                                   y: imageView.bottom,
                                   width: 301,
                                   height: 52)
        firstNameField.frame = CGRect(x: 30,
                                  y: sloganLabel.bottom+10,
                                  width: scrollView.width-60,
                                  height: fieldHeight) // generally accepted standard
        lastNameField.frame = CGRect(x: 30,
                                  y: firstNameField.bottom+10,
                                  width: scrollView.width-60,
                                  height: fieldHeight) // generally accepted standard
        emailField.frame = CGRect(x: 30,
                                  y: lastNameField.bottom+10,
                                  width: scrollView.width-60,
                                  height: fieldHeight) // generally accepted standard
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom+10,
                                     width: scrollView.width-60,
                                     height: fieldHeight)
        privacyPolicyLabel.frame = CGRect(x: 30,
                                   y: passwordField.bottom+10,
                                   width: 240,
                                   height: 50)
        privacyPolicyButton.frame = CGRect(x: 102,
                                           y: passwordField.bottom+34.5,
                                   width: 94.75,
                                   height: 22)
        termsButton.frame = CGRect(x: 196.75,
                                   y: passwordField.bottom+34.5,
                                   width: 80,
                           height: 22)
        checkMark.frame = CGRect(x: scrollView.width-60,
                                   y: passwordField.bottom+20,
                                   width: 30,
                                   height: 30)
        registerButton.frame = CGRect(x: 30,
                                   y: privacyPolicyLabel.bottom+20,
                                   width: scrollView.width-60,
                                   height: 52)
    }
    
    @objc private func didTapLogin() {
        let vc = LoginViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func registerButtonTapped() {
        
        firstNameField.resignFirstResponder()
        lastNameField.resignFirstResponder()
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard
            let email = emailField.text,
            let password = passwordField.text,
            let firstName = firstNameField.text,
            let lastName = lastNameField.text,
            !email.isEmpty,
            !password.isEmpty,
            !firstName.isEmpty,
            !lastName.isEmpty
            // password.count >= 6
            else {
                alertUserLoginError(is: LoginError.emptyField)
                return
        }
        if !email.hasSuffix("@depaul.edu") {
            alertUserLoginError(is: LoginError.notCollegeEmail)
        }
        if email == "@depaul.edu" {
            alertUserLoginError(is: LoginError.notCollegeEmail)
        }
        
        if isChecked {
            
//            spinner.show(in: view)
            
            // Firebase Register
            
//            DatabaseManager.shared.userExists(with: email, completion: {[weak self] exists in
//                guard let strongSelf = self else {
//                    return
//                }
//
////                DispatchQueue.main.async {
////                    strongSelf.spinner.dismiss()
////                }
//
//                guard !exists else {
//                    self?.alertUserLoginError(is: LoginError.userExists)
//                    return
//                }
                
                FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password, completion: { [weak self] authResult, error in
                    guard authResult != nil, error == nil,
                    let user = FirebaseAuth.Auth.auth().currentUser else {
                        self?.alertUserLoginError(is: .userExists)
                        return
                    }
                    
                    let uid = user.uid
                    
                    UserDefaults.standard.setValue("\(lastName)", forKey: "last_name")
                    UserDefaults.standard.setValue("\(firstName)", forKey: "first_name")
                    UserDefaults.standard.setValue(email, forKey: "email")
                    UserDefaults.standard.setValue(uid, forKey: "uid")
                    
                    let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email, uid: uid)
                    DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                        if success {
                            print("User successfully added to database")
                            NotificationCenter.default.post(name: .didLogInNotification, object: nil)
                        }
                        else {
                            print("Error adding user to database")
                        }
                    })
                    self?.navigationController?.dismiss(animated: true, completion: nil)
                })
        }
        
        else {
            alertUserLoginError(is: .termsNotChecked)
        }
    }
    
    @objc func checkboxTapped() {
        if isChecked == false {
            checkMark.image = UIImage(systemName: "checkmark.square")
            isChecked = true
        }
        else {
            checkMark.image = UIImage(systemName: "square")
            isChecked = false
        }
    }
        
        func alertUserLoginError(is error: LoginError) {
            let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)
            switch error {
            case .emptyField:
                alert.title = "Missing Data"
                alert.message = "Please enter all information"
            case .notCollegeEmail:
                alert.title = "Invalid Email"
                alert.message = "Please enter a valid college email"
            case .userExists:
                alert.message = "Looks like a user account for that email address already exists"
            case .termsNotChecked:
                alert.title = "Please review and accept the Terms and Privacy Policy"
            case .loginFailure:
                break
            }
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
            
            present(alert, animated: true)
        }
    
}

extension RegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == firstNameField {
            lastNameField.becomeFirstResponder()
        }
        else if textField == lastNameField {
            emailField.becomeFirstResponder()
        }
        else if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            registerButtonTapped()
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // set the activeTextField to the selected textfield
        self.activeTextField = textField
      }
        
      // when user click 'done' or dismiss the keyboard
      func textFieldDidEndEditing(_ textField: UITextField) {
        self.activeTextField = nil
      }
}
