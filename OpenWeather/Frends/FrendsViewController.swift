//
//  CityViewController.swift
//  OpenWeather
//
//  Created by Андрей Щекатунов on 13.07.2020.
//  Copyright © 2020 Andrey Shchekatunov. All rights reserved.
//

import UIKit
import RealmSwift
import FirebaseDatabase
import FirebaseFirestore

class FrendsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    
    private let realmManager = RealmManager.shared
    private let networkManager = NetworkService.shared
    private var tokenTry: String {
        Session.instanse.token
    }
    private var userIdTry: Int {
        Session.instanse.userId
    }
    
    private var filteredUsersNotificationToken: NotificationToken?
    
    var friends = [FirebaseFriend]()
    //    var filteredFriends = [FirebaseFriend]()
    var friendRef = Database.database().reference(withPath: "friends")
    var friendsCollection = Firestore.firestore().collection("Friends")
    var listener: ListenerRegistration?
    
    private let searchController = UISearchController(searchResultsController: nil)
    private var searchBarIsEmpty: Bool {
        guard let text = searchController.searchBar.text else { return false }
        return text.isEmpty
    }
    private var isFiltering: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }
    
    private var searchText: String {
        searchController.searchBar.text ?? ""
    }
    private var filteredFriends: [FirebaseFriend]  {
        guard !searchText.isEmpty else { return friends }
        return friends.filter({ (friend: FirebaseFriend) -> Bool in
            friend.firstName.lowercased().contains(searchText.lowercased())
        })
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch Config.databaseType {
        case .database:
            friendRef.observe(.value) { [weak self] snapshot in
                self?.friends.removeAll()
                guard !snapshot.children.allObjects.isEmpty else {
                    self?.loadData()
                    return
                }
                
                for child in snapshot.children {
                    guard let child = child as? DataSnapshot,
                        let friend = FirebaseFriend(snaphot: child) else { continue }
                    self?.friends.append(friend)
                }
                self?.tableView.reloadData()
            }
            
        case .firestore:
            listener = friendsCollection.addSnapshotListener { [weak self] snapshot, error in
                self?.friends.removeAll()
                guard let snapshot = snapshot else { return }
                
                guard !snapshot.documents.isEmpty else {
                    self?.loadData()
                    return
                }
                
                for document in snapshot.documents {
                    if let friend = FirebaseFriend(dict: document.data()) {
                        self?.friends.append(friend)
                    }
                }
                self?.tableView.reloadData()
            }
        case .realm:
            break
        }
        
        tableView.dataSource = self
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Поиск"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    deinit {
        switch Config.databaseType {
        case .database:
            friendRef.removeAllObservers()
            
        case .firestore:
            listener?.remove()
        case .realm:
            break
        }
    }
    
    private func loadData(completion: (() -> Void)? = nil) {
        networkManager.loadFriends(userId: userIdTry, token: tokenTry) { [weak self] result in
            switch result {
            case let .success(friends):
                DispatchQueue.main.async {
                    let firebaseFriends = friends.map { FirebaseFriend(from: $0) }
                    for friend in firebaseFriends {
                        
                        switch Config.databaseType {
                        case .database:
                            self?.friendRef.child("\(friend.id)").setValue(friend.toAnyObject())
                            
                        case .firestore:
                            self?.friendsCollection.document("\(friend.id)").setData(friend.toAnyObject())
                        case .realm:
                            break
                        }
                    }
                    self?.tableView.reloadData()
                    completion?()
                }
            case let .failure(error):
                print(error)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "frendSegue",
            let frend = sender as? Frends,
            let destination = segue.destination as? frendCardViewController {
            destination.frendName = frend.titleLable.text
            for i in 0...filteredFriends.count {
                if frend.titleLable.text == filteredFriends[i].firstName && frend.friendsModel?.lastName == filteredFriends[i].lastName {
                    destination.friendlastName = String(filteredFriends[i].lastName)
                    destination.frendAvatar = String(filteredFriends[i].avatarFriend)
                    break
                }
            }
        }
    }
}
extension FrendsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredFriends.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let friend = tableView.dequeueReusableCell(withIdentifier: "Frends") as? Frends else { fatalError() }
        
        let friendModel = filteredFriends[indexPath.item]
        friend.friendsModel = friendModel
        return friend
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let friend = filteredFriends[indexPath.item]
            
            switch Config.databaseType {
            case .database:
                friend.ref?.removeValue { [weak self] error, _ in
                    if let error = error {
                        print(error.localizedDescription)
                    } else {
                        self?.tableView.reloadData()
                    }
                }
                
            case .firestore:
                friendsCollection.document("\(friend.id)").delete { [weak self] error in
                    if let error = error {
                        print(error.localizedDescription)
                    } else {
                        self?.tableView.reloadData()
                    }
                }
            case .realm:
                break
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
extension FrendsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    private func filterContentForSearchText(_ searchText: String) {
        var filteredFriends: [FirebaseFriend]  {
            guard !searchText.isEmpty else { return friends }
            return friends.filter({ (friend: FirebaseFriend) -> Bool in
                friend.firstName.lowercased().contains(searchText.lowercased())
            })
        }
        tableView.reloadData()
    }
}

