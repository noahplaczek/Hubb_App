//
//  LoginViewController.swift
//  Hubb_App
//
//  Created by Noah Placzek 2 on 9/12/20.
//  Copyright © 2020 Hubb. All rights reserved.
//

import UIKit
import FirebaseAuth 
//import JGProgressHUD

class LoginViewController: UIViewController {

    //    private let spinner = JGProgressHUD(style: .dark)
    var activeTextField : UITextField? = nil
    
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
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.returnKeyType = .continue
        field.textColor = UIColor.gray
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.attributedPlaceholder = NSAttributedString(string: "School Email...", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        field.backgroundColor = .white
        
        // Buffer so text is not flush against the left of the text field
        field.leftView = UIView(frame: CGRect(x: 0, y: 0 , width: 5, height: 0))
        field.leftViewMode = .always
        
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.textColor = UIColor.gray
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.attributedPlaceholder = NSAttributedString(string: "Password...", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        field.backgroundColor = .white
        field.leftView = UIView(frame: CGRect(x: 0, y: 0 , width: 5, height: 0))
        field.leftViewMode = .always
        field.isSecureTextEntry = true
        
        return field
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log in", for: .normal)
        button.backgroundColor = ConversationsViewController.myColor
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        
        return button
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Log In"
        view.backgroundColor = .white
        
        loginButton.addTarget(self, action: #selector(loginButtonTapped),
                              for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard(_:)))
        self.scrollView.addGestureRecognizer(tapGesture)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func loginButtonTapped() {
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
    
        guard let email = emailField.text, let password = passwordField.text,
            !email.isEmpty, !password.isEmpty else {
                alertUserLoginError(is: LoginError.emptyField)
                return
        }
        
//        spinner.show(in: view)
        
        // Firebase Log In
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: {[weak self] authResult, error in
            guard let strongSelf = self,
            let currentUser = FirebaseAuth.Auth.auth().currentUser,
                let result = authResult,
                error == nil else {
                self?.alertUserLoginError(is: LoginError.loginFailure)
                    return
            }
        
            let uid = currentUser.uid
            
            UserDefaults.standard.set(uid, forKey: "uid")
            UserDefaults.standard.set(email, forKey: "email")
            
            print(uid)
//            DispatchQueue.main.async {
//                strongSelf.spinner.dismiss()
//            }
            
            let user = result.user
            
            DatabaseManager.shared.getDataForUser(uid: uid, completion: { result in
                switch result {
                case .success(let userData):
                    UserDefaults.standard.set("\(userData.lastName)", forKey: "last_name")
                    UserDefaults.standard.set("\(userData.firstName)", forKey: "first_name")
                    NotificationCenter.default.post(name: .didLogInNotification, object: nil) 
                case .failure(let error):
                    print("Failed to read data with error: \(error)")
                }
                
            })
            print("Logged in user: \(user)")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })
        
    }
    
    func alertUserLoginError(is error: LoginError) {
        let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)
        switch error {
        case .notCollegeEmail:
            break
        case .emptyField:
            alert.title = "Empty Field"
            alert.message = "Please enter a valid email and password"
        case .userExists:
            break
        case .termsNotChecked:
            break
        case .loginFailure:
            alert.title = "Invalid Credentials"
            alert.message = "Please enter a valid email and password"
        }
        
        alert.addAction(UIAlertAction(title: "Dismiss", style:  .cancel, handler: nil))
        
        present(alert, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width/3
        let fieldHeight = scrollView.height / 17
        imageView.frame = CGRect(x: (scrollView.width-size)/2,
                                 y: scrollView.height/5,
                                 width: size,
                                 height: size)
        emailField.frame = CGRect(x: 30,
                                  y: imageView.bottom + 20,
                                  width: scrollView.width - 60,
                                 height: fieldHeight)
        passwordField.frame = CGRect(x: 30,
                                  y: emailField.bottom + 10,
                                  width: scrollView.width - 60,
                                 height: fieldHeight)
        loginButton.frame = CGRect(x: 30,
                                  y: passwordField.bottom + 20,
                                  width: scrollView.width - 60,
                                 height: 52)
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        var offset: CGFloat
        
        if let activeTextField = activeTextField {
            if activeTextField == passwordField {
                offset = 150
            }
            else {
                offset = 200
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
    
}

enum LoginError {
    case notCollegeEmail, emptyField, userExists, termsNotChecked, loginFailure
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            loginButtonTapped()
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
