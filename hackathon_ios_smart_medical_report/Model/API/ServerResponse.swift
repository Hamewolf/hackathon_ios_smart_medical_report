//
//  ServerResponse.swift
//  VoxBible
//
//  Created by Mohamad on 25/09/25.
//

import Foundation
import UIKit

class ServerResponse {
    
    var user: User?
    var patients: [Patient] = []
    var patient: Patient?
    var reports: [Report] = []
    var erroMessage : String = ""
    var successMessage : String = ""
    var elevenLabsToken : String = ""
    var statusCode : Int = 0
    var success : Bool = false
    
    init() {
        
    }
    
}

