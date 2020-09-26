//
//  FirebaseFriends.swift
//  OpenWeather
//
//  Created by Андрей Щекатунов on 20.09.2020.
//  Copyright © 2020 Andrey Shchekatunov. All rights reserved.
//

import Foundation
import FirebaseDatabase

class FirebaseFriend {
    
    let id: Int
    let firstName: String
    let lastName: String
    let avatarFriend: String
    
    let ref: DatabaseReference?
    
    init(id: Int, firstName: String, lastName: String, avatarFriend: String) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.avatarFriend = avatarFriend
        self.ref = nil
    }
    
    convenience init(from friendsModel: FriendsItems) {
        let id = friendsModel.id.hashValue
        let firstName = friendsModel.firstName
        let lastName = friendsModel.lastName
        let avatarFriend = friendsModel.avatarFriend
        self.init(id:id, firstName: firstName, lastName: lastName, avatarFriend: avatarFriend)
    }
    
    init?(snaphot: DataSnapshot) {
        guard let value = snaphot.value as?
            [String: Any] else { return nil }
        guard let id = value["id"] as? Int,
        let firstName = value["firstName"] as? String,
        let lastName = value["lastName"] as? String,
        let avatarFriend = value["avatarFriend"] as? String else { return nil }
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.avatarFriend = avatarFriend
        self.ref = snaphot.ref
        
    }
    
    init?(dict: [String: Any]) {
        guard let id = dict["id"] as? Int,
            let firstName = dict["firstName"] as? String,
            let lastName = dict["lastName"] as? String,
            let avatarFriend = dict["avatarFriend"] as? String else { return nil }
        
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.avatarFriend = avatarFriend
        self.ref = nil
    }
    
    func toAnyObject() -> [String: Any] {
        [
            "id": id,
            "firstName": firstName,
            "lastName": lastName,
            "avatarFriend": avatarFriend
        ]
    }
    
}
