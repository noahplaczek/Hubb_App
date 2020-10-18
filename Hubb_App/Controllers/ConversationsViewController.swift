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
    
    private var myGroups = [String]()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = false
        table.register(ConversationTableViewCell.self,
                       forCellReuseIdentifier: ConversationTableViewCell.identifier)
        table.keyboardDismissMode = .onDrag
        return table
    }()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        scrollView.isHidden = true
        return scrollView
    }()
    
    private let noConversationsLabel: UILabel = {
        let label = UILabel()
        label.text = "Oops, something went wrong.\n\nCheck your internet connection"
        label.textAlignment = .center
        label.textColor = .black
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.isHidden = true
        label.numberOfLines = 0
        return label
    }()
    
    private let noResultsLabel: UILabel = {
        let label = UILabel()
        label.isHidden = false
        label.text = "No Results for:"
        label.textAlignment = .center
        label.textColor = .black
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.numberOfLines = 1
        return label
    }()
    
    private let noResultsSearchTerm: UILabel = {
        let label = UILabel()
        label.isHidden = false
        label.text = "Search Term"
        label.textAlignment = .center
        label.textColor = .black
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.numberOfLines = 1
        return label
    }()
    
    private let noResultsCreateChat: UILabel = {
        let label = UILabel()
        label.isHidden = false
        label.text = "Create a Chat!"
        label.textAlignment = .center
        label.textColor = .black
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.numberOfLines = 1
        return label
    }()
    
    private let createChatButton: UIButton = {
        let button = UIButton()
        button.setTitle("Create Chat", for: .normal)
        button.backgroundColor = ConversationsViewController.myColor
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search for Chats..."
        return searchBar
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        tableView.backgroundColor = .white
        
        print("how many times")
        
        validateAuth()
        view.addSubview(tableView)
        tableView.tableFooterView = UIView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(signedIn), name: .didLogInNotification, object: nil)

        
        navigationController?.navigationBar.barTintColor = ConversationsViewController.myColor
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.topItem?.titleView = searchBar
        searchBar.delegate = self
        
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.dismissKeyboard(_:)))
        self.tableView.addGestureRecognizer(swipeGesture)
        
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        button.addTarget(self, action: #selector(didTapActionButton), for: .touchUpInside)
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.leftBarButtonItem = barButton
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeButton))
        
        view.addSubview(scrollView)
        scrollView.addSubview(noResultsLabel)
        scrollView.addSubview(noResultsSearchTerm)
        scrollView.addSubview(noResultsCreateChat)
        scrollView.addSubview(createChatButton)
        view.addSubview(noConversationsLabel)
        
        createChatButton.addTarget(self, action: #selector(didTapComposeButton),
                              for: .touchUpInside)
        
        setupTableView()
    }
    
    @objc func signedIn() {
        listenForMyConversations()
        startListeningForConversations()
    }

    @objc func didTapActionButton() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { [weak self] _ in
            
            guard let strongSelf = self else {
                return
            }
            
            UserDefaults.standard.setValue(nil, forKey: "last_name")
            UserDefaults.standard.setValue(nil, forKey: "first_name")
            UserDefaults.standard.setValue(nil, forKey: "name")
            
            do {
                try FirebaseAuth.Auth.auth().signOut()
                strongSelf.myGroups.removeAll()
                strongSelf.groups.removeAll()
                strongSelf.allGroups.removeAll()
                DatabaseManager.shared.removeGroupObservers(completion: {success in
                    if success {
                        print("removed all observers")
                    }
                    else {
                        print("error in removing observers")
                    }
                })
                let vc = RegisterViewController()
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                strongSelf.present(nav, animated: false)
            }
            catch {
                print("Failed to log out")
            }
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
        
    }
    
    
    @objc func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .didLogInNotification, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        scrollView.frame = view.bounds
        
        noResultsLabel.frame = CGRect(x: (scrollView.width - 138) / 2,
                                  y: (scrollView.height - (scrollView.height / 3)) / 2,
                                  width: 138,
                                  height: 50)
        noResultsSearchTerm.frame = CGRect(x: (scrollView.width - 138) / 2,
                                  y: noResultsLabel.bottom+10,
                                  width: 138,
                                  height: 50)
        noResultsCreateChat.frame = CGRect(x: (scrollView.width - 135) / 2,
                                  y: noResultsSearchTerm.bottom+10,
                                  width: 135,
                                  height: 50)
        createChatButton.frame = CGRect(x: 30,
                                  y: noResultsCreateChat.bottom+20,
                                  width: scrollView.width-60,
                                  height: 52)
        noConversationsLabel.frame = CGRect(x: (scrollView.width - 294) / 2,
                                  y: (scrollView.height - 100) / 2,
                                  width: 294,
                                  height: 100)
    }
    
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = RegisterViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
        else {
            listenForMyConversations()
            startListeningForConversations()
        }
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func startListeningForConversations() {

        print("starting conversation fetch...")

        DatabaseManager.shared.getAllConversations(completion: { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            
            switch result {
            case .success(let allGroups):
                guard !allGroups.isEmpty else {
                    return
                }
                if !strongSelf.noConversationsLabel.isHidden {
                    self?.tableView.isHidden = false
                    self?.noConversationsLabel.isHidden = true
                }
                
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
                self?.tableView.isHidden = true
                self?.noConversationsLabel.isHidden = false
                print("failed to get all convos: \(error)")
            }
        })
    }
    
    private func listenForMyConversations() {
                
        print("we listening now boi")
        
        DatabaseManager.shared.getMyGroups(completion: { [weak self] result in
            switch result {
            case .success(let myGroups):
                guard !myGroups.isEmpty else {
                    return
                }
                self?.myGroups = myGroups
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
                
            case .failure(let error):
                print("failed to get my convos: \(error)")
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }
        })
    }
    
    @objc func didTapComposeButton() {
        
//        scrollView.isHidden = true
//        tableView.isHidden = false
        
        let vc = NewConversationViewController()
        
        vc.completion = { [weak self] group in
            guard let strongSelf = self else {
                return
            }
            let vc = ChatViewController(group: group)
            vc.navigationItem.largeTitleDisplayMode = .never
            strongSelf.navigationController?.pushViewController(vc, animated: true)
        }
        
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) 
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
        if numberOfLines(name: groups[indexPath.row].name) == 2 {return 110}
        else {return 90}
    }
    
    func numberOfLines(name: String) -> Int {
        let groupNameLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.preferredFont(forTextStyle: .headline)
            label.text = name
            label.numberOfLines = 2
            label.lineBreakMode = .byWordWrapping
            return label
        }()
        return lines(label: groupNameLabel)
    }
    func lines(label: UILabel) -> Int {
        let textSize = CGSize(width: view.width - 120, height: CGFloat(Float.infinity))
        let rHeight = lroundf(Float(label.sizeThatFits(textSize).height))
        let charSize = lroundf(Float(label.font.lineHeight))
        let lineCount = rHeight/charSize
        return lineCount
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
        updateUI(searchTerm: term)
    }
    
    func updateUI(searchTerm: String) {
        if groups.isEmpty {
            var labelWidth = "'\(searchTerm)'".stringWidth
            labelWidth.round(.up)
            noResultsSearchTerm.frame = CGRect(x: (scrollView.width - labelWidth) / 2,
                                      y: noResultsLabel.bottom+10,
                                      width: labelWidth,
                                      height: 50)
            noResultsSearchTerm.text = "'\(searchTerm)'"
            scrollView.isHidden = false
            tableView.isHidden = true
        } else {
            scrollView.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            print("UISearchBar.text cleared!")
            groups = allGroups
            scrollView.isHidden = true
            if !noConversationsLabel.isHidden {
                tableView.isHidden = true
            }
            else {
                tableView.isHidden = false
                tableView.reloadData()
            }
        }
    }
    
}

extension String {
    var stringWidth: CGFloat {
        let constraintRect = CGSize(width: UIScreen.main.bounds.width, height: .greatestFiniteMagnitude)
        let boundingBox = self.trimmingCharacters(in: .whitespacesAndNewlines).boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 21, weight: .medium)], context: nil)
        return boundingBox.width
    }
    var stringWidthTwo: CGFloat {
        let constraintRect = CGSize(width: UIScreen.main.bounds.width, height: .greatestFiniteMagnitude)
        let boundingBox = self.trimmingCharacters(in: .whitespacesAndNewlines).boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .subheadline)], context: nil)
        return boundingBox.width
    }
    
}
