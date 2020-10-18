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
import SDWebImage

class ChatViewController: MessagesViewController, MessageCellDelegate {
    
    private let groupName: String
    private var groupId: String?
    private var joined: Bool
    private var firstChatLoad = true
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
//        self.groupDescription = group.description
        self.groupId = group.id
        self.joined = group.joined
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let multilineNavBar: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.numberOfLines = 2
        label.font = UIFont.boldSystemFont(ofSize: 16.0)
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let id = groupId else{
            return
        }
        listenForMessages(id: id)
        view.backgroundColor = .white
        messagesCollectionView.backgroundColor = .white
        messageInputBar.backgroundView.backgroundColor = .white
        
        messageInputBar.inputTextView.textColor = .black
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        button.addTarget(self, action: #selector(didTapActionButton), for: .touchUpInside)
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = barButton
        
        self.navigationItem.titleView = multilineNavBar
        multilineNavBar.text = self.groupName
        
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(back))
        self.navigationItem.leftBarButtonItem = newBackButton
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        
        setupInputButton()
        
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.textMessageSizeCalculator.incomingAvatarSize = .zero
            layout.photoMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.photoMessageSizeCalculator.incomingAvatarSize = .zero
            layout.emojiMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.emojiMessageSizeCalculator.incomingAvatarSize = .zero
            layout.textMessageSizeCalculator.incomingMessageTopLabelAlignment.textInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)
            layout.textMessageSizeCalculator.outgoingMessageTopLabelAlignment.textInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12)
            layout.photoMessageSizeCalculator.incomingMessageTopLabelAlignment.textInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)
            layout.photoMessageSizeCalculator.outgoingMessageTopLabelAlignment.textInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12)
        }
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let _ = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        messagesCollectionView.scrollToLastItem(at: .bottom, animated: false)
    }
    
    @objc func back(sender: UIBarButtonItem) {
        guard let groupId = groupId else {
            return
        }
        DatabaseManager.shared.removeMessagesObserver(groupId: groupId)
        messages.removeAll()
        self.navigationController?.popViewController(animated: true)
    }
    
    private func setupInputButton() {
            let button = InputBarButtonItem()
            button.setSize(CGSize(width: 35, height: 35), animated: false)
            button.setImage(UIImage(systemName: "paperclip"), for: .normal)
            button.onTouchUpInside { [weak self] _ in
                self?.presentInputActionSheet()
            }
            messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
            messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
        }
    
    private func presentInputActionSheet() {
            let actionSheet = UIAlertController(title: nil,
                                                message: nil,
                                                preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in

                let picker = UIImagePickerController()
                picker.sourceType = .camera
                picker.delegate = self
                picker.allowsEditing = true
                self?.present(picker, animated: true)

            }))
            actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in

                let picker = UIImagePickerController()
                picker.sourceType = .photoLibrary
                picker.delegate = self
                picker.allowsEditing = true
                self?.present(picker, animated: true)

            }))
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            present(actionSheet, animated: true)
        }
    
    @objc func didTapActionButton() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Report Group", style: .destructive, handler: { [weak self] _ in
            guard let groupId = self?.groupId else {
                return
            }
            let vc = ReportContentViewController(groupID: groupId, userID: "")
                        
            vc.completion = { [weak self] bool in
                guard let strongSelf = self else {
                    return 
                }
                print(bool)
                if bool == true {
                    strongSelf.navigationController?.popViewController(animated: true)
                }
            }
            
            let navVC = UINavigationController(rootViewController: vc)
            self?.present(navVC, animated: true)
        
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(actionSheet, animated: true)
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        messageInputBar.inputTextView.becomeFirstResponder()
        
    }
    
    private func listenForMessages(id: String) {
        
        DatabaseManager.shared.getAllMessagesForConversation(with: id, completion: { [weak self] result in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty
                      else {
                    return
                }
                
                self?.messages = messages
                DispatchQueue.main.async {

                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    
                    guard let currentMessages = self?.messagesCollectionView.indexPathsForVisibleItems,
                          let lastMessage = self?.messagesCollectionView.indexPathForLastItem,
                          let firstChatLoad = self?.firstChatLoad else {
                        return
                    }
                    
                    if(firstChatLoad) {
                        self?.messagesCollectionView.scrollToLastItem(at: .bottom, animated: false)
                        self?.firstChatLoad = false
                    }
        
                    if currentMessages.contains(lastMessage) {self?.messagesCollectionView.scrollToLastItem(at: .bottom, animated: false)}
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
        
        let message = Message(sender: selfSender,
                              messageId: "placeholder",
                              sentDate: Date(),
                              kind: .text(text))
        
        DatabaseManager.shared.sendMessage(to: groupId, newMessage: message, sender: selfSender, joined: joined, completion: { [weak self] success in
            guard let strongSelf = self else {
                return
            }
            if success {
                print("message sent")
                strongSelf.joined = true
                strongSelf.messageInputBar.inputTextView.text = nil
                strongSelf.messagesCollectionView.scrollToBottom()
            } else {
                print("failed to send")
            }
        })
    }
    
}

extension ChatViewController: MessagesDataSource, MessagesDisplayDelegate, MessagesLayoutDelegate {

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
        return .gray
    }
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        .white
    }
    
    func didTapMessageTopLabel(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
              let currentUserId = UserDefaults.standard.value(forKey: "uid") as? String else {
            return
        }
        let message = messages[indexPath.section]
        let senderId = message.sender.senderId
        
        if senderId != currentUserId {
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Report User", style: .destructive, handler: { [weak self] _ in

            let vc = ReportContentViewController(groupID: "", userID: senderId)
            let navVC = UINavigationController(rootViewController: vc)
            self?.present(navVC, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(actionSheet, animated: true)
        }
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
            guard let message = message as? Message else {
                return
            }

            switch message.kind {
            case .photo(let media):
                guard let imageUrl = media.url else {
                    return
                }
                imageView.sd_setImage(with: imageUrl, completed: nil)
            default:
                break
            }
        }
    
}


extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage,
            let imageData =  image.pngData(),
            let userEmail = UserDefaults.standard.value(forKey: "email") as? String,
            let groupId = groupId,
            let selfSender = selfSender else {
                return
        }

        let safeUserEmail = DatabaseManager.safeEmail(emailAddress: userEmail)
        let dateString = ChatViewController.dateFormatter.string(from: Date())
        
        let fileName = "photo_message_" + safeUserEmail + dateString + ".png"

        // Upload image
        StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName, completion: { [weak self] result in
            
            guard let strongSelf = self else{
                return
            }

            switch result {
            case .success(let urlString):
                // Ready to send message
                print("Uploaded Message Photo: \(urlString)")

                guard let url = URL(string: urlString),
                    let placeholder = UIImage(systemName: "plus") else {
                        return
                }

                let media = Media(url: url,
                                  image: nil,
                                  placeholderImage: placeholder,
                                  size: .zero)

                let message = Message(sender: selfSender,
                                       messageId: "placeholder",
                                       sentDate: Date(),
                                       kind: .photo(media))

                DatabaseManager.shared.sendMessage(to: groupId, newMessage: message, sender: selfSender, joined: strongSelf.joined, completion: { success in

                    if success {
                        print("sent photo message")
                        strongSelf.joined = true
                    }
                    else {
                        print("failed to send photo message")
                    }

                })

            case .failure(let error):
                print("message photo upload error: \(error)")
            }
        })
    }

}

