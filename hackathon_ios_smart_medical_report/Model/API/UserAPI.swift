//
//  UserAPI.swift
//  VoxBible
//
//  Created by Mohamad on 25/09/25.
//

import Foundation
import UIKit
import Alamofire
import SwiftUI

class UserAPI {
    
    // MARK: - Supabase Config
    private static var authBaseURL: String { API.host }
    
    private static func defaultHeaders(includeAuth: Bool = false) -> HTTPHeaders {
        var headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        if includeAuth {
            let token = LoggedUser.sharedInstance.token
            if !token.isEmpty {
                headers.add(name: "Authorization", value: "Bearer \(token)")
            }
        }
        return headers
    }
    
    fileprivate init () {
        
    }
    
    static func decode(jwtToken jwt: String) -> [String: Any] {
      let segments = jwt.components(separatedBy: ".")
      return UserAPI.decodeJWTPart(segments[1]) ?? [:]
    }

    static func base64UrlDecode(_ value: String) -> Data? {
      var base64 = value
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")

      let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
      let requiredLength = 4 * ceil(length / 4.0)
      let paddingLength = requiredLength - length
      if paddingLength > 0 {
        let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
        base64 = base64 + padding
      }
      return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
    }
    
    static func decodeJWTPart(_ value: String) -> [String: Any]? {
      guard let bodyData = base64UrlDecode(value),
        let json = try? JSONSerialization.jsonObject(with: bodyData, options: []), let payload = json as? [String: Any] else {
          return nil
      }

      return payload
    }
    
    /* *********************************************************************************
     **
     **  MARK: Sign In
     **
     ***********************************************************************************/
    
    static func signIn(params : [String: Any], callback: @escaping (ServerResponse) -> Void) {
        // Supabase password login endpoint
        let newURL = API.host + API.auth
        
        
        // Both headers are required by Supabase GoTrue
        let headers = defaultHeaders(includeAuth: false)
        
        
        print("\n-------------- signIn (Supabase) --------------\n\(newURL)\n\(params)\n\(headers)\n\n")
        
        API.sharedInstance.sessionManager
            .request(newURL,
                     method: .post,
                     parameters: params,
                     encoding: JSONEncoding.default,
                     headers: headers)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                let resposta = ServerResponse()
                
                switch response.result {
                case .success(let value):
                    
                    print(response.result)
                    // Supabase returns keys: access_token, refresh_token, token_type, expires_in, user
                    if let json = value as? [String: Any],
                       let accessToken = json["access_token"] as? String {
                        
                        // Persist tokens and user response
                        
                        let preferences = UserDefaults.standard
                        preferences.setValue(accessToken, forKey: PreferenceKeys.token.rawValue)
                        
                        LoggedUser.sharedInstance.token = accessToken
                        
                        // Decodifica o JWT e extrai o userId (claim 'sub' ou 'user_id' ou 'id')
                        let payload = UserAPI.decode(jwtToken: accessToken)
                        if let userId = payload["sub"] as? String {
                            LoggedUser.sharedInstance.userId = userId
                        } else if let uid = payload["user_id"] as? String {
                            LoggedUser.sharedInstance.userId = uid
                        } else if let id = payload["id"] as? String {
                            LoggedUser.sharedInstance.userId = id
                        } else {
                            LoggedUser.sharedInstance.userId = ""
                            print("JWT não contém 'sub', 'user_id' ou 'id'")
                        }
                        
//                        LoggedUser.sharedInstance.user = DAOUserResponse.transformJSONInUserResponse(json as AnyObject)
                        LoggedUser.sharedInstance.storeAuthJSON(json)
                        
                        resposta.statusCode = response.response?.statusCode ?? 200
                        resposta.success = true
                        callback(resposta)
                        return
                    } else {
                        resposta.statusCode = response.response?.statusCode ?? 0
                        resposta.success = false
                        resposta.erroMessage = "Resposta inválida do servidor"
                        callback(resposta)
                        return
                    }
                    
                case .failure(let error):
                    // Tentar extrair mensagem de erro do payload do Supabase
                    var message = error.localizedDescription
                    if let data = response.data,
                       let errJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        if let msg = errJson["msg"] as? String { message = msg }
                        if let errorDesc = errJson["error_description"] as? String { message = errorDesc }
                        if let description = errJson["description"] as? String { message = description }
                    }
                    print("SignIn error: \(message)\nStatus: \(response.response?.statusCode ?? 0)\n")
                    
                    resposta.statusCode = response.response?.statusCode ?? 0
                    resposta.success = false
                    resposta.erroMessage = message.isEmpty ? "Erro ao conectar no servidor" : message
                    callback(resposta)
                }
            }
    }
    
    /* *********************************************************************************
     **
     **  MARK: getUser
     **
     ***********************************************************************************/
    
    static func getUser(callback: @escaping (ServerResponse) -> Void) {
        // Supabase get user endpoint
        let newURL = API.host + API.getUserById + LoggedUser.sharedInstance.userId
        
        // Both headers are required by Supabase GoTrue
        let headers = defaultHeaders(includeAuth: true)
        
        print("\n-------------- getUser (Supabase) --------------\n\(newURL)\n\(headers)\n\n")
        
        API.sharedInstance.sessionManager.request(newURL,
                                                  method: .get,
                                                  encoding: JSONEncoding.default,
                                                  headers: headers)
        .validate(statusCode: 200..<300)
        .responseJSON { response in
            let resposta = ServerResponse()
            
            switch response.result {
            case .success(let value):
                print(response.result)
                resposta.statusCode = response.response?.statusCode ?? 200
                
                if let obj = value as? [String: Any] {
                    let user = DAOUser.transformJSONInUser(obj as AnyObject)
                    if LoggedUser.sharedInstance.user == nil {
                        LoggedUser.sharedInstance.user = User()
                    }
                    LoggedUser.sharedInstance.user = user
                    LoggedUser.sharedInstance.storeAuthJSON(["user": obj])
                    resposta.success = true
                    callback(resposta)
                    
                } else if let arr = value as? [[String: Any]], let first = arr.first {
                    let user = DAOUser.transformJSONInUser(first as AnyObject)
                    if LoggedUser.sharedInstance.user == nil {
                        LoggedUser.sharedInstance.user = User()
                    }
                    LoggedUser.sharedInstance.user = user
                    LoggedUser.sharedInstance.storeAuthJSON(["user": first])
                    resposta.success = true
                    callback(resposta)
                    
                } else {
                    resposta.success = false
                    resposta.erroMessage = "Formato inesperado de resposta"
                    callback(resposta)
                }
                
            case .failure(let error):
                // Tentar extrair mensagem de erro do payload do Supabase
                var message = error.localizedDescription
                if let data = response.data,
                   let errJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let msg = errJson["msg"] as? String { message = msg }
                    if let errorDesc = errJson["error_description"] as? String { message = errorDesc }
                    if let description = errJson["description"] as? String { message = description }
                }
                print("getUser error: \(message)\nStatus: \(response.response?.statusCode ?? 0)\n")
                
                resposta.statusCode = response.response?.statusCode ?? 0
                resposta.success = false
                resposta.erroMessage = message.isEmpty ? "Erro ao conectar no servidor" : message
                callback(resposta)
            }
        }
    }
    
    /* *********************************************************************************
     **
     **  MARK: listPatient
     **
     ***********************************************************************************/
    
    static func listPatient(callback: @escaping (ServerResponse) -> Void) {
        // Supabase get user endpoint
        let newURL = API.host + API.listPatints
        
        // Both headers are required by Supabase GoTrue
        let headers = defaultHeaders(includeAuth: true)
        
        print("\n-------------- listPatient (Supabase) --------------\n\(newURL)\n\(headers)\n\n")
        
        API.sharedInstance.sessionManager.request(newURL,
                                                  method: .get,
                                                  encoding: JSONEncoding.default,
                                                  headers: headers)
        .validate(statusCode: 200..<300)
        .responseJSON { response in
            let resposta = ServerResponse()
            
            switch response.result {
            case .success(let value):
                print(response.result)
                if let json = value as? [[String: Any]] {
                    
                    resposta.patients = DAOPatient.transformJSONInArrayPatient(json as AnyObject)
                    resposta.statusCode = response.response?.statusCode ?? 200
                    resposta.success = true
                    callback(resposta)
                    return
                    
                } else {
                    resposta.statusCode = response.response?.statusCode ?? 0
                    resposta.success = false
                    resposta.erroMessage = "Resposta inválida do servidor"
                    callback(resposta)
                    return
                }
                
            case .failure(let error):
                // Tentar extrair mensagem de erro do payload do Supabase
                var message = error.localizedDescription
                if let data = response.data,
                   let errJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let msg = errJson["msg"] as? String { message = msg }
                    if let errorDesc = errJson["error_description"] as? String { message = errorDesc }
                    if let description = errJson["description"] as? String { message = description }
                }
                print("listPatient error: \(message)\nStatus: \(response.response?.statusCode ?? 0)\n")
                
                resposta.statusCode = response.response?.statusCode ?? 0
                resposta.success = false
                resposta.erroMessage = message.isEmpty ? "Erro ao conectar no servidor" : message
                callback(resposta)
            }
        }
    }
    
    /* *********************************************************************************
     **
     **  MARK: patientById
     **
     ***********************************************************************************/
    
    static func patientById(patientId: String, callback: @escaping (ServerResponse) -> Void) {
        // Supabase get user endpoint
        let newURL = API.host + API.patientById + patientId
        
        // Both headers are required by Supabase GoTrue
        let headers = defaultHeaders(includeAuth: true)
        
        print("\n-------------- patientById (Supabase) --------------\n\(newURL)\n\(headers)\n\n")
        
        API.sharedInstance.sessionManager.request(newURL,
                                                  method: .get,
                                                  encoding: JSONEncoding.default,
                                                  headers: headers)
        .validate(statusCode: 200..<300)
        .responseJSON { response in
            let resposta = ServerResponse()
            
            switch response.result {
            case .success(let value):
                print(response.result)
                if let json = value as? [String: Any] {
                    
                    resposta.patient = DAOPatient.transformJSONInPatient(json as AnyObject)
                    resposta.statusCode = response.response?.statusCode ?? 200
                    resposta.success = true
                    callback(resposta)
                    return
                    
                } else {
                    resposta.statusCode = response.response?.statusCode ?? 0
                    resposta.success = false
                    resposta.erroMessage = "Resposta inválida do servidor"
                    callback(resposta)
                    return
                }
                
            case .failure(let error):
                // Tentar extrair mensagem de erro do payload do Supabase
                var message = error.localizedDescription
                if let data = response.data,
                   let errJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let msg = errJson["msg"] as? String { message = msg }
                    if let errorDesc = errJson["error_description"] as? String { message = errorDesc }
                    if let description = errJson["description"] as? String { message = description }
                }
                print("patientById error: \(message)\nStatus: \(response.response?.statusCode ?? 0)\n")
                
                resposta.statusCode = response.response?.statusCode ?? 0
                resposta.success = false
                resposta.erroMessage = message.isEmpty ? "Erro ao conectar no servidor" : message
                callback(resposta)
            }
        }
    }
    
    /* *********************************************************************************
     **
     **  MARK: patientById
     **
     ***********************************************************************************/
    
    static func listReports(callback: @escaping (ServerResponse) -> Void) {
        // Supabase get user endpoint
        let newURL = API.host + API.listReports
        
        // Both headers are required by Supabase GoTrue
        let headers = defaultHeaders(includeAuth: true)
        
        print("\n-------------- listReports (Supabase) --------------\n\(newURL)\n\(headers)\n\n")
        
        API.sharedInstance.sessionManager.request(newURL,
                                                  method: .get,
                                                  encoding: JSONEncoding.default,
                                                  headers: headers)
        .validate(statusCode: 200..<300)
        .responseJSON { response in
            let resposta = ServerResponse()
            
            switch response.result {
            case .success(let value):
                print(response.result)
                if let json = value as? [[String: Any]] {
                    
                    resposta.reports = DAOReport.transformJSONInArrayReport(json as AnyObject)
                    resposta.statusCode = response.response?.statusCode ?? 200
                    resposta.success = true
                    callback(resposta)
                    return
                    
                } else {
                    resposta.statusCode = response.response?.statusCode ?? 0
                    resposta.success = false
                    resposta.erroMessage = "Resposta inválida do servidor"
                    callback(resposta)
                    return
                }
                
            case .failure(let error):
                // Tentar extrair mensagem de erro do payload do Supabase
                var message = error.localizedDescription
                if let data = response.data,
                   let errJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let msg = errJson["msg"] as? String { message = msg }
                    if let errorDesc = errJson["error_description"] as? String { message = errorDesc }
                    if let description = errJson["description"] as? String { message = description }
                }
                print("listReports error: \(message)\nStatus: \(response.response?.statusCode ?? 0)\n")
                
                resposta.statusCode = response.response?.statusCode ?? 0
                resposta.success = false
                resposta.erroMessage = message.isEmpty ? "Erro ao conectar no servidor" : message
                callback(resposta)
            }
        }
    }
    
    /* *********************************************************************************
     **
     **  MARK: updateReport
     **
     ***********************************************************************************/
    
    static func updateReport(reportId: String, params : [String : Any], callback: @escaping (ServerResponse) -> Void) {

        let newURL = API.host + API.updateReport + reportId
        
        // Both headers are required by Supabase GoTrue
        let headers = defaultHeaders(includeAuth: true)
        
        print("\n-------------- updateReport (Supabase) --------------\n\(newURL)\n\(params)\n\(headers)\n\n")
        
        API.sharedInstance.sessionManager.request(newURL,
                                                  method: .patch,
                                                  parameters: params,
                                                  encoding: JSONEncoding.default,
                                                  headers: headers)
        .validate(statusCode: 200..<300)
        .responseJSON { response in
            let resposta = ServerResponse()
            
            switch response.result {
            case .success(let value):

                    resposta.statusCode = response.response?.statusCode ?? 200
                    resposta.success = true
                    // resposta.data = json // se seu ServerResponse tiver um campo para dados
                    callback(resposta)
                    return

                
            case .failure(let error):
                // Tentar extrair mensagem de erro do payload do Supabase
                var message = error.localizedDescription
                if let data = response.data,
                   let errJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let msg = errJson["msg"] as? String { message = msg }
                    if let errorDesc = errJson["error_description"] as? String { message = errorDesc }
                    if let description = errJson["description"] as? String { message = description }
                }
                print("updateReport error: \(message)\nStatus: \(response.response?.statusCode ?? 0)\n")
                
                resposta.statusCode = response.response?.statusCode ?? 0
                resposta.success = false
                resposta.erroMessage = message.isEmpty ? "Erro ao conectar no servidor" : message
                callback(resposta)
            }
        }
    }
    
}
