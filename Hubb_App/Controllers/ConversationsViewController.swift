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
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        scrollView.isHidden = true
        return scrollView
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
        
        validateAuth()
        view.addSubview(tableView)
        view.backgroundColor = .white
        navigationController?.navigationBar.barTintColor = ConversationsViewController.myColor
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.topItem?.titleView = searchBar
        searchBar.delegate = self
        
        let tapGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.dismissKeyboard(_:)))
        self.tableView.addGestureRecognizer(tapGesture)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeButton))
        
        view.addSubview(scrollView)
        scrollView.addSubview(noResultsLabel)
        scrollView.addSubview(noResultsSearchTerm)
        scrollView.addSubview(noResultsCreateChat)
        scrollView.addSubview(createChatButton)
        
        createChatButton.addTarget(self, action: #selector(didTapComposeButton),
                              for: .touchUpInside)
        
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
        scrollView.frame = view.bounds
        let centered = scrollView.width / 3
        let middle = scrollView.height / 3
        
        noResultsLabel.frame = CGRect(x: (scrollView.width - centered) / 2,
                                  y: (scrollView.height - middle) / 2,
                                  width: 138,
                                  height: 50)
        noResultsSearchTerm.frame = CGRect(x: (scrollView.width - centered) / 2,
                                  y: noResultsLabel.bottom+10,
                                  width: 138,
                                  height: 50)
        noResultsCreateChat.frame = CGRect(x: (scrollView.width - centered) / 2,
                                  y: noResultsSearchTerm.bottom+10,
                                  width: 135,
                                  height: 50)
        createChatButton.frame = CGRect(x: 30,
                                  y: noResultsCreateChat.bottom+20,
                                  width: scrollView.width-60,
                                  height: 52)
        
        print("No Results for:".stringWidth)
        print("Create a Chat!".stringWidth)
    }
    
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = RegisterViewController()
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
                guard !allGroups.isEmpty else {
                    return
                }
//                self?.tableView.isHidden = false
//                self?.scrollView.isHidden = true
                
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
                print("failed to get convos: \(error)")
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
//
//            strongSelf.tableView.reloadData()
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
        if numberOfLines(name: groups[indexPath.row].name) == 2 {return 120}
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
//        let zone = CGSize(width: scrollView.width - 120, height: CGFloat(MAXFLOAT))
//        let fittingHeight = Float(label.sizeThatFits(zone).height)
//        return lroundf(fittingHeight / Float(label.font.lineHeight))
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
            tableView.isHidden = false
            tableView.reloadData()
        }
    }
    
}

extension String {
    var stringWidth: CGFloat {
        let constraintRect = CGSize(width: UIScreen.main.bounds.width, height: .greatestFiniteMagnitude)
        let boundingBox = self.trimmingCharacters(in: .whitespacesAndNewlines).boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .bold)], context: nil)
        return boundingBox.width
    }
}
