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
    
    private var allGroups = [Group]()
    
    private var groups = [Group]()
    
    private var searchResults = [Group]()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = false
        table.register(ConversationTableViewCell.self,
                       forCellReuseIdentifier: ConversationTableViewCell.identifier)
        table.keyboardDismissMode = .onDrag
        return table
    }()
    
    private let noResultsLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.text = "No Results"
        label.textAlignment = .center
        label.textColor = .green
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    
    private var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search for Chats..."
        return searchBar
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        validateAuth()
        view.addSubview(tableView)
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.barTintColor = ConversationsViewController.myColor
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.topItem?.titleView = searchBar
        searchBar.delegate = self
        
        let tapGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.dismissKeyboard(_:)))
        self.tableView.addGestureRecognizer(tapGesture)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeButton))
        
        setupTableView()
        startListeningForConversations()
    }
    
    @objc func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
            case .success(let allGroups):
                guard !allGroups.isEmpty else { // if conversation list empty, no need to update table view
//                    self?.noConversationsLabel.isHidden = false
                    self?.tableView.isHidden = true
                    return
                }
                self?.tableView.isHidden = false
 //               self?.noConversationsLabel.isHidden = true
                
                if self?.groups.count == self?.allGroups.count {
                    self?.allGroups = allGroups
                    self?.groups = allGroups
                    
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                }
                else {
                    self?.allGroups = allGroups
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
        return 110
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
}

extension ConversationsViewController: UISearchBarDelegate {
    // USER SEARCH
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        groups.removeAll()
//        spinner.show(in: view)
        
        filterGroups(with: text)
    }
    
    func filterGroups(with term: String) {
        guard !allGroups.isEmpty else {
            return
        }
        
//        self.spinner.dismiss()
                
        let groups: [Group] = allGroups.filter({
            let groupInfo = $0.name.lowercased() + " " + $0.name.lowercased()
            
            return groupInfo.contains(term.lowercased())
        })
        
        self.groups = groups
        updateUI()
    }
    
    func updateUI() {
        if groups.isEmpty {
            noResultsLabel.isHidden = false
            tableView.isHidden = true
        } else {
            noResultsLabel.isHidden = true
            tableView.isHidden = false
            tableView.reloadData() // reloads the tableview to include filtered searches
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            print("UISearchBar.text cleared!")
            groups = allGroups
            noResultsLabel.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()
        }
    }
    
}
