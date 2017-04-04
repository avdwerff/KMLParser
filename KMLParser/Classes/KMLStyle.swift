//
//  KMLStyle.swift
//  KMLParser
//
//  Created by Alexander van der Werff on 18/03/2017.
//  Copyright © 2017 AvdWerff. All rights reserved.
//

import Foundation
import UIKit

protocol KMLStyleable {
    var styles: [KMLStyle] { get set }
}

enum KMLStyle {
    case
        line(color: UIColor, width: CGFloat),
        poly(color: UIColor, fill: Bool, outline: Bool),
        balloon(bgColor: UIColor, textColor: UIColor),
        icon(urlString: String)
}
