//
//  API.swift
//  VoxBible
//
//  Created by Mohamad on 25/09/25.
//

import Foundation
import Alamofire
import UIKit

class API {

    static let host = "https://api-hackathon-smart-medical-report.vercel.app"
    
    static let auth = "/auth/login"
    
    static let getUserById = "/user/findOne/"
    
    static let listPatints = "/patient/"
    
    static let patientById = "/patient/"
    
    static let listReports = "/report"
    
    static let updateReport = "/report/"

    //------------------------- Singleton -----------------------------

    static let sharedInstance = API()

    var sessionManager: Session!

    /* *********************************************************************************
     **
     **  MARK: Init
     **
     ***********************************************************************************/

    fileprivate init() {

        _ = Locale.preferredLanguages[0] as String

        //---------------------- Default Header ----------------------------

        let headers = HTTPHeaders()

        //----------------------- URLSessionConfiguration ---------------------

        let configuration = URLSessionConfiguration.default

        configuration.headers = headers

        //----------------------- Session Manager -----------------------------

        sessionManager = Alamofire.Session(configuration: configuration)

    }

}
