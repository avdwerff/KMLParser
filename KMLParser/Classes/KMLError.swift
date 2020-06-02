//
//  KMLError.swift
//  KMLParser
//
//  Created by Alexander van der Werff on 12/03/2017.
//  Copyright © 2017 AvdWerff. All rights reserved.
//

import Foundation

extension XMLParser {
    public enum SemanticError: Error {
        case polygonError(String)
    }
}


public extension KMLParser {
    
    /// Error
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        if let completion = completion {
            completion(ResultType.failure(reason: Reason.parseError(parseError)))
        }
    }
    
}
