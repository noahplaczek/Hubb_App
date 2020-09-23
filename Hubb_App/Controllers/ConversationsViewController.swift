//
//  ViewController.swift
//  Hubb_App
//
//  Created by Noah Placzek 2 on 9/12/20.
//  Copyright © 2020 Hubb. All rights reserved.
//

import UIKit
import FirebaseAuth

class ConversationsViewController: UIViewController {
    
    static public let myColor = UIColor(red: 101.0/255.0, green: 200.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    
    private var groups = [Group]()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = false
        table.register(ConversationTableViewCell.self,
                       forCellReuseIdentifier: ConversationTableViewCell.identifier)
        
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.barTintColor = ConversationsViewController.myColor
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeButton))
        setupTableView()
        startListeningForConversations()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func startListeningForConversations() {

        print("starting conversation fetch...")

        DatabaseManager.shared.getAllConversations(completion: { [weak self] result in
            switch result {
            case .success(let groups):
                guard !groups.isEmpty else { // if conversation list empty, no need to update table view
//                    self?.noConversationsLabel.isHidden = false
                    self?.tableView.isHidden = true
                    return
                }
                self?.tableView.isHidden = false
 //               self?.noConversationsLabel.isHidden = true
                self?.groups = groups
                // call reload data on table view - specificall main thread bc that is where all UI operations should occur
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }

            case .failure(let error):
//                self?.noConversationsLabel.isHidden = false
                self?.tableView.isHidden = true
                print("failed to get convos: \(error)")
            }
        })
    }
    
    @objc func didTapComposeButton() {
        let vc = NewConversationViewController()
        
        vc.completion = { [weak self] group in
            guard let strongSelf = self else {
                return
            }
            let vc = ChatViewController(group: group)
            vc.title = group.name
            vc.navigationItem.largeTitleDisplayMode = .never
            strongSelf.navigationController?.pushViewController(vc, animated: true)
        }
        // EDIT: Presents from the ConversationsView. This is fine unless we create from the Explore View.
        // Need to better understand Navigation Controller / rootViewController
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }

    
}

extension ConversationsViewController: UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = groups[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier,
                                                 for: indexPath) as! ConversationTableViewCell
        cell.configure(with: model)
        
        return cell
    }
    
    // when a user clicks on a cell, want to push onto stack
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) // unhighlights what you selected
        let model = groups[indexPath.row]
        openConversation(model)
    }
    
    func openConversation(_ model: Group) {
        let vc = ChatViewController(group: model)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
}
