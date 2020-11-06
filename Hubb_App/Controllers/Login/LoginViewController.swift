//
//  LoginViewController.swift
//  Hubb_App
//
//  Created by Noah Placzek 2 on 9/12/20.
//  Copyright © 2020 Hubb. All rights reserved.
//

import UIKit
import FirebaseAuth 

class LoginViewController: UIViewController {
    
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
        
        print(view.height)
        print(view.width)
        
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
        
        let validate = Validation()
    
        do {
            let email = try validate.validateLoginField(emailField.text)
            let password = try validate.validateLoginField(passwordField.text)
        
        // Firebase Log In
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: {[weak self] authResult, error in
            guard let strongSelf = self,
                  let currentUser = FirebaseAuth.Auth.auth().currentUser,
                  let result = authResult,
                  error == nil else {
                self?.showAlert(alertText: "Invalid Credentials", alertMessage: "Please enter a valid email and password")
                return
            }
            
            let uid = currentUser.uid
            
            UserDefaults.standard.set(uid, forKey: "uid")
            UserDefaults.standard.set(email, forKey: "email")
            
            if email.hasSuffix("depaul.edu") {
                UserDefaults.standard.setValue("depaul", forKey: "school")
                
            }
            else if email.hasSuffix("uic.edu") {
                UserDefaults.standard.setValue("uic", forKey: "school")
            }
            
            print(uid)
            
            let user = result.user
            
            DatabaseManager.shared.getDataForUser(uid: uid, completion: { result in
                switch result {
                case .success(let userData):
                    UserDefaults.standard.set("\(userData.lastName)", forKey: "last_name")
                    UserDefaults.standard.set("\(userData.firstName)", forKey: "first_name")
                    NotificationCenter.default.post(name: .didLogInNotification, object: nil)
                case .failure(let error):
                    self?.showAlert(alertText: "Uh oh", alertMessage: "There appears to have been an issue. Please try again")
                    print("Failed to read data with error: \(error)")
                }
                
            })
            print("Logged in user: \(user)")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })
        }
        catch LoginError.emptyField {
            showAlert(alertText: "Missing Fields", alertMessage: "Please enter all information")
        }
        catch {
            showAlert(alertText: "Uh oh", alertMessage: "There appears to have been an issue. Please try again")
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width/3
        let fieldHeight = scrollView.height / 17
        
        var smallerSize = false
        if scrollView.width < 330 {
            smallerSize = true
        }

        
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
        if smallerSize {
            loginButton.frame = CGRect(x: 30,
                                      y: passwordField.bottom + 20,
                                      width: scrollView.width - 60,
                                     height: 40)
        }
        else {
        loginButton.frame = CGRect(x: 30,
                                  y: passwordField.bottom + 20,
                                  width: scrollView.width - 60,
                                 height: 52)
        }
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
