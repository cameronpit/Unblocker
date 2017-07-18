//
//  Scanner.swift
//
//  Unblocker
//  Swift 3.1
//
//  Copyright © 2017 Cameron C. Pitcairn.
//  See the file license.txt in the Unblocker project.
//

import UIKit

// Image repesentation adapted from https://github.com/Swiftor/ImageProcessing

// MARK: Structs defining representation of pixels and images

// A pixel is a 32-bit value which is the concatenation of four 8-bit values
// representing RGB plus Alpha
private struct Pixel {
   var value: UInt32
   var red: UInt8 {
      get { return UInt8(value & 0xFF) }
      set { value = UInt32(newValue) | (value & 0xFFFFFF00) }
   }
   var green: UInt8 {
      get { return UInt8((value >> 8) & 0xFF) }
      set { value = (UInt32(newValue) << 8) | (value & 0xFFFF00FF) }
   }
   var blue: UInt8 {
      get { return UInt8((value >> 16) & 0xFF) }
      set { value = (UInt32(newValue) << 16) | (value & 0xFF00FFFF) }
   }
   var alpha: UInt8 {
      get { return UInt8((value >> 24) & 0xFF) }
      set { value = (UInt32(newValue) << 24) | (value & 0x00FFFFFF) }
   }
}

// Pixels is effectively a 2-dimensional array, each element of which is a
// pixel, representing a UIImage image which is passed in the initializer.
private struct Pixels {
   var data: UnsafeMutablePointer<Pixel>
   var imgWidth: Int
   var imgHeight: Int
   // (boardOriginX, boardOriginY) will be upper left corner of
   // playing board image.
   var boardOriginX: Int
   var boardOriginY: Int
   init?(image: UIImage) {
      guard let cgImage = image.cgImage else { return nil }
      imgWidth = Int(image.size.width)
      imgHeight = Int(image.size.height)
      boardOriginX = 0
      boardOriginY = 0
      let bitsPerComponent = 8
      let bytesPerPixel = 4
      let bytesPerRow = imgWidth * bytesPerPixel
      data = UnsafeMutablePointer<Pixel>.allocate(capacity: imgWidth * imgHeight)
      let colorSpace = CGColorSpaceCreateDeviceRGB()
      var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Big.rawValue
      bitmapInfo |= CGImageAlphaInfo.premultipliedLast.rawValue &
         CGBitmapInfo.alphaInfoMask.rawValue
      guard let imageContext = CGContext(
         data: data,
         width: imgWidth,
         height: imgHeight,
         bitsPerComponent: bitsPerComponent,
         bytesPerRow: bytesPerRow,
         space: colorSpace,
         bitmapInfo: bitmapInfo)
         else { return nil }
      imageContext.draw(cgImage, in: CGRect(
         origin: CGPoint.zero,
         size: image.size
         )
      )
   }
   // pixels[0,0] is upper left corner of playing board image.
   subscript(x: Int, y:Int) -> Pixel {
      get {return data[boardOriginX + x + (boardOriginY + y) * imgWidth]}
      set {data[boardOriginX + x + (boardOriginY + y) * imgWidth] = newValue}
   }
}

// MARK: -
// The Scanner class is for scanning the image produced by the Unblock Me app,
// and generating the representation of the puzzle which is used by the Solver
// class.
//
class Scanner {
   let testRow = 2
   let testSide = Side.right

   private var tileSize = 0

   // struct Matrix defined in Extensions & generics.swift
   private var wasVisited = Matrix<Bool>(cols: Const.cols, rows: Const.rows, defaultElement: false)

   //***************************************************************************
   // MARK: -

   func generatePuzzle(fromImage image:UIImage) -> Puzzle? {
      guard var pixels = getBoardImage(fromImage: image) else {return nil}
      var board = Board()
      wasVisited.reset()
      Block.nextId = 0

      // MARK: Main loop for func generatePuzzle
      for row in 0..<Const.rows {
         for col in 0..<Const.cols {

            // If tile is empty, mark as visited
            if pixels[convertTile(col),convertTile(row)].red < Const.emptyRedHiThreshold {
               wasVisited[col, row] = true
            }

            // If tile was previously visited, skip to next col.
            if wasVisited[col,row] {continue}

            // Note that findBlockWidth() and findBlockHeight() both set
            // wasVisited[]
            let blockWidth = findBlockWidth(col: col, row: row, pixels: pixels)
            let blockHeight = findBlockHeight(col: col, row: row, pixels: pixels)
            guard blockWidth==1 || blockHeight==1 else {return nil}
            let block = Block(
               col: col,
               row: row,
               length: max(blockWidth, blockHeight),
               isHorizontal: blockWidth > 1,
               isPrisoner: pixels[convertTile(col),convertTile(row)].green <
                  Const.redBlockGreenHiThreshold,
               isFixed: blockWidth == 1 && blockHeight == 1
            )
            board.insert(block)
         }
      }

      // There must be exactly 1 prisoner, and it must be a horizontal block of 
      // length 2 in row 2 (the third row).
      // Otherwise return nil.
      let prisoners = board.filter({$0.isPrisoner})
      if prisoners.count == 1 {
         let prisoner = prisoners.first!
         if prisoner.isHorizontal && prisoner.length == 2 && prisoner.row == testRow {
            return Puzzle(initialBoard: board, escapeSide: testSide, escapeRow: testRow)
         }
      }
      return nil
   }

   //***************************************************************************
   // MARK: -

   private func getBoardImage(fromImage image: UIImage) -> Pixels? {
      let optPixels = Pixels(image: image)
      guard var pixels = optPixels else {return nil}

      // Scan the right edge of image to find the "escape chute"
      // Just scan the middle third of the edge
      let startRow = pixels.imgHeight / 3
      let endRow = 2 * startRow
      var y = startRow
      var topOfEscape:Int
      var bottomOfEscape:Int
      var red:UInt8

      // Scan till empty color is encountered, set top of escape chute
      repeat {
         let pixel = pixels[pixels.imgWidth-1, y]
         red = pixel.red
         topOfEscape = y
         y += 1
      } while red >= Const.emptyRedHiThreshold && y < endRow

      guard y < endRow - 2 else { return nil }

      // Continue scanning till not empty color, set bottom of escape chute
      repeat {
         let pixel = pixels[pixels.imgWidth-1, y]
         red = pixel.red
         bottomOfEscape = y
         y += 1
      } while red < Const.emptyRedHiThreshold && y < endRow

      guard y < endRow - 1 else { return nil }

      // Set tile size equal to the height of the escape chute.
      // Horizontal center of image is horizontal center of board.
      // Bottom  of escape chute is vertical center of board.
      topOfEscape = 620
      bottomOfEscape = 737
      self.tileSize = bottomOfEscape - topOfEscape
      guard tileSize > 4 else { return nil }
      let centerX = pixels.imgWidth / 2
      let centerY = bottomOfEscape
      // Set origin to upper left corner of board image
      pixels.boardOriginX = centerX - 3 * tileSize
      pixels.boardOriginY = centerY - 3 * tileSize

      // Consistency check
      guard pixels.boardOriginX > 0
         && pixels.boardOriginX < pixels.imgWidth
         && pixels.boardOriginY > 0
         && pixels.boardOriginY < pixels.imgHeight
         else {return nil }

      return pixels
   }

   //***************************************************************************
   // MARK: -
   // Convert row or col to a coordinate of a pixel at (or near) center of tile
   
   private func convertTile(_ coordinate:Int) -> Int {
      return coordinate*tileSize + tileSize/2
   }

   //***************************************************************************
   // MARK: -

   private func findBlockWidth(col:Int, row:Int, pixels: Pixels) -> Int {
      var width = 1
      let y = convertTile(row)
      for c in col..<Const.cols {
         wasVisited[c,row] = true
         // If we are in the last column, stop here
         if c == Const.cols - 1 {
            return width
         }
         // Otherwise keep going:
         // Check if there is an edge between this tile
         // and the next.
         for x in convertTile(c)..<convertTile(c+1) {
            if pixels[x,y].red < Const.edgeRedHiThreshold {
               // Found right edge of block, so return width
               return width
            }
         }
         // Did not find right edge of block, so increment width
         width += 1
      }
      return width
   }

   //***************************************************************************
   // MARK: -

   private func findBlockHeight(col:Int, row:Int, pixels: Pixels) -> Int {
      var height = 1
      let x = convertTile(col)
      for r in row..<Const.rows {
         wasVisited[col,r] = true
         // If we are in the last row, stop here
         if r == Const.rows - 1 {
            return height
         }
         // Otherwise keep going:
         // Check if there is an edge between this tile
         // and the next.
         for y in convertTile(r)..<convertTile(r+1) {
            if pixels[x,y].red < Const.edgeRedHiThreshold {
               // Found bottom edge of block, so return height
               return height
            }
         }
         // Did not find bottom edge of block, so increment height
         height += 1
      }
      return height
   }
}

