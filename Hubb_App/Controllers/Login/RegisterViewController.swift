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
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    // Will instead use this in Profile Screen
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
    
    private let firstNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "First name..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let lastNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Last name..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "School Email..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "New Account"
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Login", style: .done, target: self, action: #selector(didTapLogin))
        
        registerButton.addTarget(self, action: #selector(registerButtonTapped),
                              for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        
        
        // Add Subviews
        view.addSubview(scrollView)
//        scrollView.addSubview(imageView)
        scrollView.addSubview(firstNameField)
        scrollView.addSubview(lastNameField)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(registerButton)
        
//        imageView.isUserInteractionEnabled = true
//        scrollView.isUserInteractionEnabled = true
//
//        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapChangeProfilePic))
//
//        imageView.addGestureRecognizer(gesture)
    }
//    @objc private func didTapChangeProfilePic() {
//        presentPhotoActionSheet()
//    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width / 3
//        imageView.frame = CGRect(x: (scrollView.width - size) / 2,
//                                 y: 20,
//                                 width: size,
//                                 height: size)
//      imageView.layer.cornerRadius = imageView.width / 2.0
        
        firstNameField.frame = CGRect(x: 30,
                                  y: (scrollView.width - size) / 2,
                                  width: scrollView.width-60,
                                  height: 52) // generally accepted standard
        lastNameField.frame = CGRect(x: 30,
                                  y: firstNameField.bottom+10,
                                  width: scrollView.width-60,
                                  height: 52) // generally accepted standard
        emailField.frame = CGRect(x: 30,
                                  y: lastNameField.bottom+10,
                                  width: scrollView.width-60,
                                  height: 52) // generally accepted standard
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom+10,
                                     width: scrollView.width-60,
                                     height: 52)
        registerButton.frame = CGRect(x: 30,
                                   y: passwordField.bottom+10,
                                   width: scrollView.width-60,
                                   height: 52)
        
    }
    
    @objc private func didTapLogin() {
        let vc = LoginViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func registerButtonTapped() {
        
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
        if email.hasSuffix("@gmail.com") {
            
//            spinner.show(in: view)
            
            // Firebase Register
            
            DatabaseManager.shared.userExists(with: email, completion: {[weak self] exists in
                guard let strongSelf = self else {
                    return
                }
                
//                DispatchQueue.main.async {
//                    strongSelf.spinner.dismiss()
//                }
                
                guard !exists else {
                    // user already exists
                    self?.alertUserLoginError(is: LoginError.userExists)
                    return
                }
                
                FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password, completion: {authResult, error in
                    guard authResult != nil, error == nil,
                    let user = FirebaseAuth.Auth.auth().currentUser else {
                        print("Error creating user")
                        return
                    }
                    
                    let uid = user.uid
                    
                    // Cache user information
                    UserDefaults.standard.setValue("\(lastName)", forKey: "last_name")
                    UserDefaults.standard.setValue("\(firstName)", forKey: "first_name")
                    UserDefaults.standard.setValue(email, forKey: "email")
                    UserDefaults.standard.setValue(uid, forKey: "uid")
                    
                    // Add user to DB
                    
                    let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email, uid: uid)
                    DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                        if success {
                            print("User successfully added to database")
                        }
                        else {
                            self?.alertUserLoginError(is: LoginError.notCollegeEmail)
                        }
                    })
                    strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                })
            })
        }
    }
        
        func alertUserLoginError(is error: LoginError) {
            let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)
            switch error {
            case .emptyField:
                alert.title = "Whoops!"
                alert.message = "Please enter all information"
            case .notCollegeEmail:
                alert.title = "Whoops!"
                alert.message = "Please enter a valid college email"
            case .userExists:
                alert.message = "Looks like a user account for that email address already exists"
            }
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
            
            present(alert, animated: true)
        }
    
}

extension RegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            registerButtonTapped()
        }
        
        return true
    }
}

//extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate { // allows us to get results of user taking a picture or selecting photo from camera roll
//    
//    func presentPhotoActionSheet(){
//        let actionSheet = UIAlertController(title: "Profile Picture", message: "How would you like to select a picture", preferredStyle: .actionSheet)
//        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
//        actionSheet.addAction(UIAlertAction(title: "Take Photo",
//                                            style: .default,
//                                            handler: {[weak self] _ in
//                                                self?.presentCamera()
//        }))
//        actionSheet.addAction(UIAlertAction(title: "Choose Photo",
//                                            style: .default,
//                                            handler: {[weak self] _ in
//                                                self?.presentPhotoPicker()
//        }))
//        
//        present(actionSheet, animated: true)
//    }
//    
//    func presentCamera() {
//        let vc = UIImagePickerController()
//        vc.sourceType = .camera
//        vc.delegate = self
//        vc.allowsEditing = true
//        present(vc, animated: true)
//    }
//    
//    func presentPhotoPicker() {
//        let vc = UIImagePickerController()
//        vc.sourceType = .photoLibrary
//        vc.delegate = self
//        vc.allowsEditing = true
//        present(vc, animated: true)
//    }
//    
//    // called when user takes or selects a photo
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//        print(info)
//        picker.dismiss(animated: true, completion: nil)
//        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
//            return
//        }
//        self.imageView.image = selectedImage
//    }
//    
//    // called when user cancels selection / photo
//    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//        picker.dismiss(animated: true, completion: nil)
//    }
//    
//}
