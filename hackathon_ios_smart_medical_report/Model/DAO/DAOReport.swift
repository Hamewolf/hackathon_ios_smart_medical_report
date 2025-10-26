//
//  DAOReport.swift
//  hackathon_ios_smart_medical_report
//
//  Created by Mohamad on 25/10/25.
//

import Foundation
import CoreData
import UIKit

//MARK: - DAOReport -
class DAOReport {
    
    fileprivate init() { }
    
    static func transformJSONInArrayReport(_ JSON: AnyObject) -> [Report] {
        var array: [Report] = []
        guard let data = JSON as? NSArray else { return array }
        for item in data {
            array.append(transformJSONInReport(item as AnyObject))
        }
        return array
    }
    
    static func transformJSONInReport(_ JSON: AnyObject) -> Report {
        let item = Report()
        
        if let info = JSON["id"] as? String { item.id = info }
        if let info = JSON["patient_id"] as? String { item.patient_id = info }
        if let info = JSON["doctor_id"] as? String { item.doctor_id = info }
        if let info = JSON["exam_type"] as? String { item.exam_type = info }
        if let arr = JSON["procedures"] as? [String] { item.procedures = arr }
        if let info = JSON["results"] as? String { item.results = info }
        if let info = JSON["conclusions"] as? String { item.conclusions = info }
        if let info = JSON["observations"] as? String { item.observations = info }
        if let info = JSON["based_on"] as? String { item.based_on = info }
        if let info = JSON["comparisons"] as? String { item.comparisons = info }
        if let info = JSON["status"] as? String { item.status = info }
        if let info = JSON["report_date"] as? String { item.report_date = info }
        if let info = JSON["created_at"] as? String { item.created_at = info }
        if let info = JSON["updated_at"] as? String { item.updated_at = info }
        
        if let imgs = JSON["images"] as? [[String: Any]] {
            var result: [ReportImage] = []
            for img in imgs {
                let rimg = ReportImage()
                if let url = img["url"] as? String { rimg.url = url }
                if let desc = img["description"] as? String { rimg.description = desc }
                result.append(rimg)
            }
            item.images = result
        }
        
        return item
    }
}
