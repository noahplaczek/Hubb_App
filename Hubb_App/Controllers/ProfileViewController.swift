//
//  ProfileViewController.swift
//  Hubb_App
//
//  Created by Noah Placzek 2 on 9/12/20.
//  Copyright © 2020 Hubb. All rights reserved.
//

import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController {
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(ProfileTableViewCell.self,
                       forCellReuseIdentifier: ProfileTableViewCell.identifier) // registers a cell
        
        return table
    }()
    
    var data = [ProfileViewModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        view.backgroundColor = .white
        
        navigationController?.navigationBar.barTintColor = ConversationsViewController.myColor
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.tintColor = UIColor.white
        
        tableView.delegate = self
        tableView.dataSource = self
        
        data.append(ProfileViewModel(viewModelType: .info,
                                     title: "Name: \(UserDefaults.standard.value(forKey: "first_name") as? String ?? "No") \(UserDefaults.standard.value(forKey: "last_name") as? String ?? "Name")",
                                     handler: nil))
        data.append(ProfileViewModel(viewModelType: .info,
                                     title: "Email: \(UserDefaults.standard.value(forKey: "email") as? String ?? "No Name")",
                                    handler: nil))
        data.append(ProfileViewModel(viewModelType: .logout, title: "Log Out", handler: { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            let actionSheet = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
            
            actionSheet.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { [weak self] _ in
                
                guard let strongSelf = self else {
                    return
                }
                
                UserDefaults.standard.setValue(nil, forKey: "last_name")
                UserDefaults.standard.setValue(nil, forKey: "first_name")
                UserDefaults.standard.setValue(nil, forKey: "name")
                
                do {
                    try FirebaseAuth.Auth.auth().signOut()
                    // if log out successful, go back to login screen
                    let vc = LoginViewController()
                    let nav = UINavigationController(rootViewController: vc)
                    nav.modalPresentationStyle = .fullScreen
                    strongSelf.present(nav, animated: false)
                }
                catch {
                    print("Failed to log out")
                }
            }))
            
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            strongSelf.present(actionSheet, animated: true)
        }))
        


    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier, for: indexPath) as! ProfileTableViewCell
        cell.setUp(with: viewModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        data[indexPath.row].handler?()
    }
}

class ProfileTableViewCell: UITableViewCell {
    
    static let identifier = "ProfileTableViewCell"
    
    public func setUp(with viewModel: ProfileViewModel) {
        self.textLabel?.text = viewModel.title
        switch viewModel.viewModelType {
        case .info:
            textLabel?.textAlignment = .left
            selectionStyle = .none
        case .logout:
            textLabel?.textColor = .red
            textLabel?.textAlignment = .center
        }
    }
    
}
