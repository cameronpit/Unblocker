//
//  Program constants.swift
//
//  Unblocker
//  Swift 3.1
//
//  Copyright © 2017 Cameron C. Pitcairn.
//  See the file license.txt in the Unblocker project.
//

import UIKit

/*******************************************************************************
 Const is a globally-available struct which defines various constants used
 by the program.
 ******************************************************************************/

struct Const {
   static let rows = 6, cols = 6 // Board is always 6 x 6
   static let gapRatio = CGFloat(1.0/20) // Ratio of gap between blocks to tile size
   static let imageTruncation = 10 // rows to ignore at top & bottom of origina image

   // Colors for displaying board
   static let prisonerBlockColor = UIColor.red
   static let normalBlockColor = UIColor(red: 239/255, green: 195/255, blue: 132/255, alpha: 1)
   static let rivetColor = UIColor.gray
   static let boardBackgroundColor = UIColor(red: 106/255, green: 73/255, blue: 30/255, alpha: 1)
   static let emptyBackgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
   static let escapeColor = UIColor.red
   static let normalMessageLabelColor = UIColor.black
   static let urgentMessageLabelColor = UIColor.red

   // Color thresholds for scanning image (determined empirically)
   static let startEscapeRedHiThreshold:UInt8 = 120 // is > red component of escape chute
   static let endEscapeRedLoThreshold:UInt8 = 130 // is < red component of frame
   static let startBlackLineRedHiThreshold:UInt8 = 50 // is > red component of horizonal black line
   static let endBlackLineRedLoThreshold:UInt8 = 70 // is < red component of not-a-black-line
   static let edgeRedHiThreshold:UInt8 = 125  // is > red component of edge color
   static let emptyRedHiThreshold:UInt8 = 125 // is > red component of empty color
   static let redBlockGreenHiThreshold:UInt8 = 100 // is > green component of red block color

   // Animation timings (in seconds)
   static let blockViewAnimationDuration = 0.5
   static let blockViewAnimationDelay = 0.5
   static let boardViewResetAnimationDuration = 0.3
}

