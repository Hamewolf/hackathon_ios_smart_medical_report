//
//  Report.swift
//  hackathon_ios_smart_medical_report
//
//  Created by Mohamad on 25/10/25.
//

import Foundation

//MARK: - ReportImage -
class ReportImage {
    var url: String = ""
    var description: String = ""
}

//MARK: - Report -
class Report: Identifiable {
    var identificationm : Int = 0
    var id: String = ""
    var patient_id: String = ""
    var doctor_id: String = ""
    var exam_type: String = ""
    var procedures: [String] = []
    var results: String = ""
    var conclusions: String = ""
    var images: [ReportImage] = []
    var observations: String = ""
    var based_on: String = ""
    var comparisons: String = ""
    var status: String = ""
    var report_date: String = ""
    var created_at: String = ""
    var updated_at: String = ""
}
