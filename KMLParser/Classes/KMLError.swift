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
