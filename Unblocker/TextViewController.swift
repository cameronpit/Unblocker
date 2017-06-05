//
//  TextViewController.swift
//
//  Unblocker
//  Swift 3.1
//
//  Copyright © 2017 Cameron C. Pitcairn.
//  See the file license.txt in the Unblocker project.
//

// Shows "Additional stats" tab

import UIKit

class TextViewController: UIViewController {

   override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      textView.font = UIFont(name: "Menlo-Regular", size: 15.0)
      textView.isEditable = false
      textView.isScrollEnabled = true
      textView.text = delegate?.textToShow
   }

   @IBOutlet weak var textView: UITextView!

   weak var delegate: TextProviderDelegate?

}
