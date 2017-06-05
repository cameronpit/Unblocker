//
//  Protocols.swift
//
//  Unblocker
//  Swift 3.1
//
//  Copyright © 2017 Cameron C. Pitcairn.
//  See the file license.txt in the Unblocker project.
//

import UIKit

protocol TextProviderDelegate: class {
   var textToShow: String? {get}
}

protocol ImageProviderDelegate: class {
   var imageToShow: UIImage? {get}
}

