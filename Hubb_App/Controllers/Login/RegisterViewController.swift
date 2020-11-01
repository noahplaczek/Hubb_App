//
//  RegisterViewController.swift
//  Hubb_App
//
//  Created by Noah Placzek 2 on 9/12/20.
//  Copyright © 2020 Hubb. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseAnalytics

class RegisterViewController: UIViewController {
    
    private var activeTextField : UITextField? = nil
    private var isChecked = false
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
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
        var smallerSize = false
        if scrollView.width < 330 {
            smallerSize = true
            privacyPolicyLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
            privacyPolicyButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .caption1)
            termsButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .caption1)
        }
        
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
                                  height: fieldHeight)
        lastNameField.frame = CGRect(x: 30,
                                  y: firstNameField.bottom+10,
                                  width: scrollView.width-60,
                                  height: fieldHeight)
        emailField.frame = CGRect(x: 30,
                                  y: lastNameField.bottom+10,
                                  width: scrollView.width-60,
                                  height: fieldHeight)
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom+10,
                                     width: scrollView.width-60,
                                     height: fieldHeight)
        if smallerSize {
            privacyPolicyLabel.frame = CGRect(x: 32,
                                              y: passwordField.bottom+5,
                                              width: 220,
                                              height: 15)
            privacyPolicyButton.frame = CGRect(x: 30,
                                               y: passwordField.bottom+20,
                                               width: 85,
                                               height: 15)
            termsButton.frame = CGRect(x: 110,
                                       y: passwordField.bottom+20,
                                       width: 70,
                                       height: 15)
            checkMark.frame = CGRect(x: scrollView.width-60,
                                     y: passwordField.bottom+10,
                                     width: 30,
                                     height: 30)
            registerButton.frame = CGRect(x: 30,
                                          y: privacyPolicyLabel.bottom+25,
                                          width: scrollView.width-60,
                                          height: 40)
        }
        else {
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
    }
    
    @objc private func didTapLogin() {
        let vc = LoginViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func registerButtonTapped() {
        
        firstNameField.resignFirstResponder()
        lastNameField.resignFirstResponder()
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        let validate = Validation()
        
        do {
            let firstName = try validate.validateLoginField(firstNameField.text)
            let lastName = try validate.validateLoginField(lastNameField.text)
            let email = try validate.validateEmail(emailField.text)
            let password = try validate.validatePassword(passwordField.text)
 

            guard isChecked  else {
                throw LoginError.termsNotChecked
            }
            
            // Firebase Register
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password, completion: { [weak self] authResult, error in
                guard authResult != nil, error == nil,
                      let user = FirebaseAuth.Auth.auth().currentUser else {
                    self?.showAlert(alertText: "Account Exists", alertMessage: "Looks like a user account for that email address already exists")
                    return
                }
                
                let uid = user.uid
                
                UserDefaults.standard.setValue("\(lastName)", forKey: "last_name")
                UserDefaults.standard.setValue("\(firstName)", forKey: "first_name")
                UserDefaults.standard.setValue("\(email)", forKey: "email")
                UserDefaults.standard.setValue("\(uid)", forKey: "uid")
                                
                let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email, uid: uid)
                DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                    if success {
                        print("User successfully added to database")
                        
                        if email.hasSuffix("depaul.edu") {
                            Analytics.setUserProperty("depaul", forName: "school")
                        }
                        else if email.hasSuffix("uic.edu") {
                            Analytics.setUserProperty("uic", forName: "school")
                        }
                        
                        NotificationCenter.default.post(name: .didLogInNotification, object: nil)
                    }
                    else {
                        self?.showAlert(alertText: "Uh oh", alertMessage: "There appears to have been an issue. Please try again")
                        print("Error adding user to database")
                    }
                })
                self?.navigationController?.dismiss(animated: true, completion: nil)
            })
        }
        catch LoginError.emptyField {
            showAlert(alertText: "Missing Fields", alertMessage: "Please enter all information")
        }
        catch LoginError.notCollegeEmail {
            showAlert(alertText: "Invalid Email", alertMessage: "Please enter a valid college email")
        }
        catch LoginError.userExists {
            showAlert(alertText: "Account Exists", alertMessage: "Looks like a user account for that email address already exists")
        }
        catch LoginError.termsNotChecked {
            showAlert(alertText: "Accept Terms", alertMessage: "Please review and accept the Terms and Privacy Policy")
        }
        catch LoginError.passwordLength {
            showAlert(alertText: "Password Min Length", alertMessage: "Please enter a password that is at least 6 characters")
        }
        catch {
            showAlert(alertText: "Uh oh", alertMessage: "There appears to have been an issue. Please try again")
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
        self.activeTextField = textField
      }
        
      func textFieldDidEndEditing(_ textField: UITextField) {
        self.activeTextField = nil
      }
}

