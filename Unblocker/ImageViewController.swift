//
//  ImageViewController.swift
//
//  Unblocker
//  Swift 3.1
//
//  Copyright © 2017 Cameron C. Pitcairn.
//  See the file license.txt in the Unblocker project.
//

// Shows "Original image" tab

import UIKit

class ImageViewController: UIViewController {

   override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      if let passedImage = delegate?.imageToShow{
         // NO ERROR
         imageView.image = passedImage
      } else {
         // IMAGE NOT FOUND ERROR
         imageView.image = nil
      }
   }

   @IBOutlet weak var imageView: UIImageView!

   weak var delegate: ImageProviderDelegate?

}
