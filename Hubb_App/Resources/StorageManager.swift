//
//  StorageManager.swift
//  Hubb_App
//
//  Created by Noah Placzek 2 on 9/12/20.
//  Copyright © 2020 Hubb. All rights reserved.
//

import Foundation
import FirebaseStorage

final class StorageManager {

    static let shared = StorageManager()

    private init() {}

    private let storage = Storage.storage().reference()
    
    public typealias uploadPictureCompletion = (Result<String, Error>) -> Void
    
    public func uploadMessagePhoto(with data: Data, fileName: String, completion: @escaping uploadPictureCompletion) {
        storage.child("message_images/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else {
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self?.storage.child("message_images/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
}

public enum StorageErrors: Error {
    case failedToUpload
    case failedToGetDownloadUrl
}
