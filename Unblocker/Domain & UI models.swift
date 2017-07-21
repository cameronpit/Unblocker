//
//  Domain & UI models.swift
//
//  Unblocker
//  Swift 3.1
//
//  Copyright © 2017 Cameron C. Pitcairn.
//  See the file license.txt in the Unblocker project.
//

import UIKit

/*******************************************************************************
 This program is designed to produce solutions to the puzzles in the Unblock Me
 app, which is available in Apple's App Store.

 The game consists of a 6 x 6 playing board on which are a number of blocks,
 with one block designated as "prisoner."  The prisoner is horizontal and in
 row 2 (where rows and columns are numbered from 0 to 5.)  On the right end
 of row 2 there is an exit from the board (the "escape chute"). The object of
 the game is to release the prisoner  by moving the blocks so that the prisoner
 has a clear path to the escape chute. Horizontal blocks can only move
 horizontally, and vertical blocks can only move vertically.

 In this program, every instance of the Block struct has a fixed, unique ID.
 The properties length, isHorizontal, and isPrisoner are also fixed for a given
 instance.  In addition, there are three variable properties:  col, row, and
 hashValue.

 The column and row define the position of the block in the board, which is
 represented by the position of the block's topmost or leftmost end.

 The hashValue uniquely identifies a particular block at a particular position
 on the board.  Thus the hashValue not only satisfies the definition of "hash
 value" (if two blocks-with-position are equal then their hash values are
 equal), but also can be used to define equality (if two blocks-with-position
 have the same hashValue then they are equal).
 ******************************************************************************/

/*******************************************************************************
 The following declarations are adapted from the UnblockMeSolver program
 by Thanassis Tsiodras.

 Program:  https://github.com/ttsiodras/UnblockMeSolver
 Explanation:  https://www.thanassis.space/unblock.html
 Video:  http://www.youtube.com/watch?v=6hfF_6KlAQk
 *******************************************************************************/

struct Block: Hashable {
   static var nextId = 0
   static func ==(lhs: Block, rhs: Block) -> Bool {
      return lhs.hashValue == rhs.hashValue
   }
   let id: Int
   let length: Int
   let isHorizontal: Bool
   let isPrisoner: Bool
   let isFixed: Bool
   var col: Int
   var row: Int
   var hashValue: Int {
      return id << 10 | col << 5 | row
   }
   init(col: Int, row: Int, length: Int, isHorizontal: Bool,
        isPrisoner: Bool, isFixed: Bool) {
      id = Block.nextId
      Block.nextId += 1
      self.col = col
      self.row = row
      self.length = length
      self.isHorizontal = isHorizontal
      self.isPrisoner = isPrisoner
      self.isFixed = isFixed
   }
}

//******************************************************************************
// BlockView is a UIView which represents the corresponding block on the screen.

class BlockView: UIView {
   let id: Int   // This is the ID of the corresponding Block
   let color: UIColor
   let width: Int
   let height: Int
   let isFixed: Bool
   var col: Int
   var row: Int

   // On the iPad, tileSize can change if the device is rotated.
   // In that case, boardView will set the tile size of blockView,
   // and blockView will redraw itself at the correct size and position
   // relative to its superview, which is boardView.

   var tileSize: CGFloat {
      didSet {
         layout()
      }
   }

   func layout() {
      let origin = CGPoint(x: CGFloat(col)*tileSize, y: CGFloat(row)*tileSize)
      let size = CGSize(width: CGFloat(width)*tileSize, height: CGFloat(height)*tileSize)
      frame = CGRect(origin: origin, size: size)
   }

   // A blockView has a transparent background. On it is drawn an opaque
   // rounded rectangle which is slightly smaller than the bounds of the
   // view. The background of boardView shows through the transparent
   // edges of the blockView outside of the rounded rectangle. This creates
   // a visual border separating adjacent blocks.

   override func draw(_ rect: CGRect) {
      let gap = tileSize * Const.gapRatio
      let insetRect = rect.insetBy(dx: gap, dy: gap)
      let path = UIBezierPath(roundedRect: insetRect, cornerRadius: 2*gap)
      color.set()
      path.fill()

      func rivet(x: CGFloat, y: CGFloat, radius: CGFloat) {
         // Draws a "rivet head" (filled circle with color Const.rivetColor) 
         // with the point (x, y) as center and with the given radius.
         // The origin is the upper left corner of the visible block, i.e.,
         // of the rectangle insetRect.
         let center = CGPoint(x: insetRect.origin.x+x , y: insetRect.origin.y+y)
         let path = UIBezierPath(arcCenter: center,
                                 radius: radius,
                                 startAngle: 0.0,
                                 endAngle: 2*CGFloat.pi,
                                 clockwise: false)
         Const.rivetColor.set()
         path.fill()
      }

      if isFixed {  // Place rivets near the corners of the block
         let width = insetRect.width
         let height = insetRect.height
         let offset = 2*gap
         rivet(x: offset, y: offset, radius: gap)
         rivet(x: width - offset, y: offset, radius: gap)
         rivet(x: width - offset, y: height - offset, radius: gap)
         rivet(x: offset, y: height - offset, radius: gap)
      }
   }



   init(id: Int, color: UIColor, width: Int, height: Int, col: Int,
        row: Int, tileSize: CGFloat, isFixed: Bool)
   {
      self.id = id
      self.color = color
      self.col = col
      self.row = row
      self.width = width
      self.height = height
      self.isFixed = isFixed
      self.tileSize = tileSize
      super.init(frame: CGRect.zero)
      layout()
      contentMode = .redraw
      isOpaque = false
      backgroundColor = UIColor.clear
   }

   // The following init must be provided by a subclass of UIView
   required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }
}

//******************************************************************************
// Elements of a Set must be Hashable (hence also Equatable, by definition of
// Hashable).
//
// Note that Block satisfies this requirement, so we can define a Board to
// be a Set of Block elements.

// MARK: Board (typealias)
typealias Board = Set<Block>

//******************************************************************************
// BoardView is a UIView which represents the playing board on the screen
// as a square region.  The blockViews are all subviews of the boardView.

class BoardView: UIView {
   var puzzle: Puzzle? {
      didSet {
         setNeedsDisplay()
      }
   }

   override func layoutSubviews() {
      let tileSize = bounds.size.width / CGFloat(Const.cols)
      let blockViews = subviews as! [BlockView]
      for blockView in blockViews {
         blockView.tileSize = tileSize
      }
   }
   override func draw(_ rect: CGRect) {
      guard puzzle != nil else {return}
      let tileSize = frame.width / CGFloat(Const.cols)
      let escapeRow = puzzle!.escapeSite.row
      let escapeOriginX: CGFloat
      let escapeWidth: CGFloat

      // Draw escape chute
      switch puzzle!.escapeSite.side {
      case .right:
         escapeOriginX = frame.width - 1
         escapeWidth = -Const.gapRatio * tileSize

      case .left:
         escapeOriginX = 0
         escapeWidth = Const.gapRatio * tileSize

      }
      let path = UIBezierPath(rect: CGRect(x: escapeOriginX,
                                           y: CGFloat(escapeRow) * tileSize,
                                           width: escapeWidth,
                                           height: tileSize
         )
      )
      Const.escapeColor.set()
      path.fill()
   }
}

enum Side {
   case left
   case right
}

struct Location {
   let side: Side
   let row: Int
}

struct Puzzle {
   let initialBoard: Board
   let escapeSite: Location
}

//******************************************************************************
// In the Solver class, the dictionary lookupMoveForBoard is of type
// [Board:Move]. For a given board, the dictionary lookupMoveForBoard returns 
// the move which was applied to the previous board to arrive at the given 
// board. The move identifies the block which was moved and the position
// of the block in the previous board.


struct Move {
   let blockID: Int
   let col: Int
   let row: Int
}

//******************************************************************************
// Once a solution has been found, the Solver class will construct an array
// of type [SolutionMove] which records the sequence of moves from initialBoard 
// to winningBoard. The UnblockerViewController class will use the array
// to animate moves in both the forward and backward directions.  

struct SolutionMove {
   let blockID: Int
   let colFwd: Int
   let rowFwd: Int
   let colBack: Int
   let rowBack: Int
}

