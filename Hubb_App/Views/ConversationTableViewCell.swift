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
    
    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        return label
    }()
    
    private let userMessageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .regular)
        label.numberOfLines = 0 // allow to line wrap
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
        contentView.addSubview(userMessageLabel)
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
        
        userNameLabel.frame = CGRect(x: //userImageView.right+
                                        10,
                                     y: 10,
                                     width: contentView.width - 20,//(- userImageView.width) // buffer of 20
                                     height: (contentView.height - 20)/2)
        
        userMessageLabel.frame = CGRect(x: //userImageView.right+
                                            10,
                                        y: userNameLabel.bottom + 10,
                                        width: contentView.width - 20,// - userImageView.width,
                                        height: (contentView.height - 20)/2)
        
    }
    
//    public func configure(with model: Group) {
//        userMessageLabel.text = model.latestMessage.text
//        userNameLabel.text = model.name
//
//        let path = "images/\(model.otherUserEmail)_profile_picture.png"
//        StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
//            switch result {
//            case .success(let url):
//                DispatchQueue.main.async {
//                    // SDWebImage - downloads image and assigns to image view
//                    self?.userImageView.sd_setImage(with: url, completed: nil)
//                }
//            case .failure(let error):
//                print("failed to get image url: \(error)")
//            }
//        })
//    }

    
    
}
