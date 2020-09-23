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
    
    
    // EDIT - probably don't need image for convo
//    private let userImageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.contentMode = .scaleAspectFill
//        imageView.layer.cornerRadius = 50
//        imageView.layer.masksToBounds = true
//        return imageView
//    }()
    
    private let groupNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        label.numberOfLines = 2
 //       label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    private let groupDescriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = ConversationsViewController.myColor
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        contentView.addSubview(userImageView)
        contentView.addSubview(groupNameLabel)
        contentView.addSubview(groupDescriptionLabel)
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
        
        groupNameLabel.frame = CGRect(x: //userImageView.right+
                                        20,
                                     y: 10,
                                     width: contentView.width - 20,//(- userImageView.width) // buffer of 20
                                     height: (contentView.height)/2)
        
        groupDescriptionLabel.frame = CGRect(x: //userImageView.right+
                                            20,
                                        y: groupNameLabel.bottom + 10,
                                        width: contentView.width - 20,// - userImageView.width,
                                        height: (contentView.height - 20)/2)

    }
    
    public func configure(with model: Group) {
        groupDescriptionLabel.text = model.latestMessage?.text
        groupNameLabel.text = model.name
    }
  
}
