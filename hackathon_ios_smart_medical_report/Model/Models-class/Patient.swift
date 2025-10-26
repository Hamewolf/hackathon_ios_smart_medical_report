//
//  Patient.swift
//  hackathon_ios_smart_medical_report
//
//  Created by Mohamad on 25/10/25.
//

import Foundation

//MARK: - Patient -
class Patient : Identifiable{
    var id: String = ""
    var full_name: String = ""
    var tax_id: String = ""
    var birth_date: String = ""
    var gender: String = ""
    var email: String = ""
    var phone: String = ""
    var address: String = ""
    var registration_date: String = ""
    var created_at: String = ""
    var updated_at: String = ""
}
