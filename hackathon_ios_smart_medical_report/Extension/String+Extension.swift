//
//  String+Extension.swift
//  PapoReto
//
//  Created by Pedro Warol on 03/06/25.
//

import Foundation

extension String {
    
    /* *********************************************************************************
     **
     **  MARK: Format Mask
     **
     ***********************************************************************************/
    
    func formatMask(maskStr : String) -> String {
        let cleanNumber = components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        let mask = maskStr
        
        var result = ""
        var startIndex = cleanNumber.startIndex
        let endIndex = cleanNumber.endIndex
        
        for char in mask where startIndex < endIndex {
            if char == "X" {
                result.append(cleanNumber[startIndex])
                startIndex = cleanNumber.index(after: startIndex)
            } else {
                result.append(char)
            }
        }
        
        return result
    }
    
    /* *********************************************************************************
     **
     **  MARK: Formatted Date -> "dd/MM/yyyy, HH:mm"
     **
     ***********************************************************************************/
    
    func formattedDate() -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd/MM/yyyy, HH:mm"
        outputFormatter.locale = Locale(identifier: "pt_BR")
        
        if let date = inputFormatter.date(from: self) {
            return outputFormatter.string(from: date)
        } else {
            return self 
        }
    }
    
    /* *********************************************************************************
     **
     **  MARK: Formatted Date -> "dd/MM/yyyy"
     **
     ***********************************************************************************/
    
    func formatDateToddMMyyyy() -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd/MM/yyyy"
        outputFormatter.locale = Locale(identifier: "pt_BR")
        
        if let date = inputFormatter.date(from: self) {
            return outputFormatter.string(from: date)
        } else {
            return self
        }
    }
    
    var digitsOnly: String {
        String(unicodeScalars.filter { CharacterSet.decimalDigits.contains($0) })
    }
}
