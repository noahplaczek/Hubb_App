//
//  ChatViewController.swift
//  Hubb_App
//
//  Created by Noah Placzek 2 on 9/12/20.
//  Copyright © 2020 Hubb. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView

class ChatViewController: MessagesViewController {
    
    private let groupName: String
    private let groupDescription: String
    private var groupId: String?
    
    private var joinedGroup = false
    
    private var messages = [Message]()
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    private var selfSender: Sender? {
        guard let uid = UserDefaults.standard.value(forKey: "uid") as? String,
        let displayName = UserDefaults.standard.value(forKey: "first_name") as? String else {
            return nil
        }
        return Sender(photoURL: "",
               senderId: uid,
               displayName: displayName)
    }
    

    
    init(group: Group) {
        self.groupName = group.name
        self.groupDescription = group.description
        self.groupId = group.id
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
//        messagesCollectionView.messageCellDelegate = self // ImageViewer
        messageInputBar.delegate = self
    }
    
//    private func notFavorited() {
//        //create a new button
//        let button = UIButton(type: .custom)
//        //set image for button
//        button.setImage(UIImage(systemName: "star"), for: .normal)
//        //add function for button
//        button.addTarget(self, action: #selector(didTapFavorites), for: .touchUpInside)
//        //set frame
//        button.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
//
//        let barButton = UIBarButtonItem(customView: button)
//        //assign button to navigationbar
//        self.navigationItem.rightBarButtonItem = barButton
//
//
//    }
    
//    private func favorited() {
//        //create a new button
//        let button = UIButton(type: .custom)
//        //set image for button
//        button.setImage(UIImage(systemName: "star.filled"), for: .normal)
//        //add function for button
//        button.addTarget(self, action: #selector(didTapFavorites), for: .touchUpInside)
//        //set frame
//        button.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
//
//        let barButton = UIBarButtonItem(customView: button)
//        //assign button to navigationbar
//        self.navigationItem.rightBarButtonItem = barButton
//    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        guard let id = groupId else{
            return
        }
        listenForMessages(id: id)
    }
    
    private func listenForMessages(id: String) {
        
        var shouldScrollToBottom = true
        
        DatabaseManager.shared.getAllMessagesForConversation(with: id, completion: { [weak self] result in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    return
                }
                self?.messages = messages
                DispatchQueue.main.async {
                // if user has scrolled to the top and a new message comes in, this wont scroll to bottom
                        self?.messagesCollectionView.reloadDataAndKeepOffset()
                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToLastItem()
                        shouldScrollToBottom = false
                    }
                }
            case .failure(let error):
                print("failed to get messages: \(error)")
            }
        })
    }
    
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
            let selfSender = self.selfSender,
            let groupId = self.groupId else {
                print("not sending")
                return
        }
        
        // append to existing conversation data
        DatabaseManager.shared.sendMessage(to: groupId, messageText: text, sender: selfSender, completion: { [weak self] success in
            if success {
                print("message sent")
                self?.messageInputBar.inputTextView.text = nil
                self?.messagesCollectionView.scrollToBottom()
            } else {
                print("failed to send")
            }
        })
    }
    
}

extension ChatViewController: MessagesDataSource, MessagesDisplayDelegate, MessagesLayoutDelegate {

    // how it is determined if the message appears on right (you) or left
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("Self Sender is nil, email should be cached")
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        return NSAttributedString(string: message.sender.displayName, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        
    }

    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 15
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        // messagekit framework uses sections to separate messages
        // single section per message
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId {
            // our message
            return .link
        }
        return .secondarySystemBackground
    }
    
}
