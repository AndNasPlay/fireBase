//
//  Config.swift
//  OpenWeather
//
//  Created by Андрей Щекатунов on 20.09.2020.
//  Copyright © 2020 Andrey Shchekatunov. All rights reserved.
//

import Foundation

enum DatabaseType {
    case database
    case firestore
    case realm
}

enum Config {
    static let databaseType: DatabaseType = .database
}
