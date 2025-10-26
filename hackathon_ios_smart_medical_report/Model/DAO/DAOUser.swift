//
//  DAOUser.swift
//  hackathon_ios_smart_medical_report
//
//  Created by Mohamad on 25/10/25.
//

import Foundation
import CoreData
import UIKit

//MARK: - DAOUser -
class DAOUser {
    
    fileprivate init() {
        
    }
    
    static func transformJSONInArrayUser(_ JSON : AnyObject) -> [User] {
        
        var array : [User] = []
        
        guard let data = JSON as? NSArray else {
            return array
        }
        
        for item in data {
            
            array.append(transformJSONInUser(item as AnyObject))
            
        }
        
        return array
        
    }
    
    static func transformJSONInUser(_ JSON : AnyObject) -> User {
        
        let item = User()
        
      
        if let info = JSON["access_level"] as? String {
            item.access_level = info
        }
        
        if let info = JSON["created_at"] as? String {
            item.created_at = info
        }
        
        if let info = JSON["id"] as? String {
            item.id = info
        }
        
        if let info = JSON["login"] as? String {
            item.login = info
        }
        
        if let info = JSON["name"] as? String {
            item.name = info
        }
        
        if let info = JSON["professional_registration"] as? String {
            item.professional_registration = info
        }
        
        if let info = JSON["specialty"] as? String {
            item.specialty = info
        }
        
        if let info = JSON["updated_at"] as? String {
            item.updated_at = info
        }
        
        return item
        
    }
    
}
