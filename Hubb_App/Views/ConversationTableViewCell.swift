//
//  ConversationTableViewCell.swift
//  Hubb_App
//
//  Created by Noah Placzek 2 on 9/12/20.
//  Copyright © 2020 Hubb. All rights reserved.
//

import UIKit

class ConversationTableViewCell: UITableViewCell {
    
    // Static property to register cell to table view
    static let identifier = "ConversationTableViewCell"
    
    
    // EDIT - Will add user images based on feedback
//    private let userImageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.contentMode = .scaleAspectFill
//        imageView.layer.cornerRadius = 50
//        imageView.layer.masksToBounds = true
//        return imageView
//    }()
    
    private let groupNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.numberOfLines = 2
 //       label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    private let latestMessageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = ConversationsViewController.myColor
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.textColor = .lightGray
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        contentView.addSubview(userImageView)
        contentView.addSubview(groupNameLabel)
        contentView.addSubview(latestMessageLabel)
        contentView.addSubview(dateLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // give frame to each of the subviews
//        userImageView.frame = CGRect(x: 10,
//                                     y: 10,
//                                     width: 100,
//                                     height: 100)
        
        groupNameLabel.frame = CGRect(x: 20,
                                     y: 5,
                                     width: contentView.width - 120,
                                     height: (contentView.height)/2)
        
        latestMessageLabel.frame = CGRect(x: 20,
                                        y: groupNameLabel.bottom + 10,
                                        width: contentView.width - 120,
                                        height: (contentView.height - 20)/2)
        
        dateLabel.frame = CGRect(x: contentView.width - 85,
                                        y: 15,
                                        width: 90,
                                        height: 20)
        
    }
    
    public func configure(with model: Group) {
        groupNameLabel.text = model.name
        dateLabel.text = model.date
        
        guard let latestMessage = model.latestMessage else {
            return
        }
        
        if latestMessage.text == "New Group" {
            latestMessageLabel.text = "New Group"
        }
        else {
            latestMessageLabel.text = latestMessage.senderName + ": " + latestMessage.text
        }

        
    }
  
}
