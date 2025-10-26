//
//  DAOPatient.swift
//  hackathon_ios_smart_medical_report
//
//  Created by Mohamad on 25/10/25.
//

import Foundation
import CoreData
import UIKit

//MARK: - DAOPatient -
class DAOPatient {
    
    fileprivate init() {
        
    }
    
    static func transformJSONInArrayPatient(_ JSON: AnyObject) -> [Patient] {
        var array: [Patient] = []
        guard let data = JSON as? NSArray else { return array }
        for item in data {
            array.append(transformJSONInPatient(item as AnyObject))
        }
        return array
    }
    
    static func transformJSONInPatient(_ JSON: AnyObject) -> Patient {
        let item = Patient()
        
        if let info = JSON["id"] as? String { item.id = info }
        if let info = JSON["full_name"] as? String { item.full_name = info }
        if let info = JSON["tax_id"] as? String { item.tax_id = info }
        if let info = JSON["birth_date"] as? String { item.birth_date = info }
        if let info = JSON["gender"] as? String { item.gender = info }
        if let info = JSON["address"] as? String { item.address = info }
        if let info = JSON["registration_date"] as? String { item.registration_date = info }
        if let info = JSON["created_at"] as? String { item.created_at = info }
        if let info = JSON["updated_at"] as? String { item.updated_at = info }
        
        if let contact = JSON["contact"] as? [String: Any] {
            if let email = contact["email"] as? String { item.email = email }
            if let phone = contact["phone"] as? String { item.phone = phone }
        }
        
        return item
    }
}
