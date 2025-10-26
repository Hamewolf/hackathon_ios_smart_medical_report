//
//  LoggedUser.swift
//  VoxBible
//
//  Created by Mohamad on 25/09/25.
//

import Foundation
import UIKit
import SwiftUI
import SwiftData
import Combine

class LoggedUser: ObservableObject {
    
    static let sharedInstance = LoggedUser()
    
    // MARK: - Persistence Keys
    private static let tokenKey = "LoggedUser.token"
    private static let userId = "LoggedUser.refresh"
    private static let authJSONKey = "LoggedUser.authJSON"
    
    private var suppressPersistence = false
    
    @Published var token: String = "" { didSet { if !suppressPersistence { UserDefaults.standard.set(token, forKey: LoggedUser.tokenKey) } } }
    @Published var userId: String = "" { didSet { if !suppressPersistence { UserDefaults.standard.set(userId, forKey: LoggedUser.userId) } } }
    
    @Published var user : User?
    
    var defaultFunction: (() -> Void)?
    
    fileprivate init() {
        // Load persisted values
        let defaults = UserDefaults.standard
        if let savedToken = defaults.string(forKey: LoggedUser.tokenKey) {
            self.token = savedToken
        }
        if let savedRefresh = defaults.string(forKey: LoggedUser.userId) {
            self.userId = savedRefresh
        }
        if let data = defaults.data(forKey: LoggedUser.authJSONKey),
           let obj = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            // Rebuild UserResponse from the last successful auth payload
            let user = DAOUser.transformJSONInUser(obj as AnyObject)
            self.user = user
        }
    }
    
    // MARK: - Persist last auth JSON (contains `user`)
    func storeAuthJSON(_ dict: [String: Any]) {
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: []) {
            UserDefaults.standard.set(data, forKey: LoggedUser.authJSONKey)
        }
    }
    
    static func clear() {
        // Prevent didSet from re-persisting empty values while clearing
        let instance = LoggedUser.sharedInstance
        instance.suppressPersistence = true
        
        // Clear in-memory values
        instance.token = ""
        instance.userId = ""
        //        instance.user = nil
        instance.defaultFunction = nil
        
        // Clear persisted values
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: LoggedUser.tokenKey)
        defaults.removeObject(forKey: LoggedUser.userId)
        defaults.removeObject(forKey: LoggedUser.authJSONKey)
        
        instance.suppressPersistence = false
    }
}
