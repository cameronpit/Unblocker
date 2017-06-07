# Guide to _Unblocker_

## Contents

Note: These links do not work in the mobile version of the GitHub site.

[Installing the app](#installing-the-app)

[The _Unblock Me_ game](#the-unblock-me-game)

[Using the app](#using-the-app)

[How the program works](#how-the-program-works)

* [Domain & UI models](#domain--ui-models)

* [Scanning the image](#scanning-the-image)

* [Solving the puzzle](#solving-the-puzzle)

* [User interface](#user-interface)

[Observations](#observations)

[Future additions](#future-additions)

## Installing the app 

I wrote _Unblocker_ in order to get some experience in Swift programmming, and also to discover what resources in time and memory are required to solve the _Unblock Me_ puzzle.  I have posted the code on GitHub because I thought other programmers might find it interesting. I have not submitted the app to the App Store.

In order to install the app:

*  On the [Unblocker home page](https://github.com/cameronpit/Unblocker) click _Clone or download_, then _Download ZIP_.
*  Download the file to an empty folder on your Mac and unZIP it.
*  Open the resulting project in Xcode (version 8 or later).
*  Build and run.

[Contents](#contents)

## The _Unblock Me_ game

<img align="right" alt="Puzzle B-7764" src="images/Puzzle-B-7764.png">

[_Unblock Me_](http://itunes.apple.com/us/app/unblock-me/id315021242?mt=8) is a puzzle app by [Kiragames](http://www.kiragames.com/). 
The puzzle consists of a “board” whose size is 6 units by 6 units.  The board can be thought of as being divided into 36 squares or “tiles,” where each tile is 1 unit by 1 unit. On the board are some blocks.  The size of each block, expressed as "width x height",  is either 2x1 or 3x1 or 1x2 or 1x3.  “Horizontal” blocks (2x1 or 3x1) can only move left or right, and “vertical” blocks (1x2 or 1x3) can only move up or down.  A block can never overlap or pass through another block, and must stay completely on the board.

There is one special 2x1 block in the third\* row called the “prisoner” which is colored differently from the other blocks. The object of the puzzle is to move the prisoner to the right end of its row so that it can escape through the “escape chute,” which is an opening in the board adjacent to the right end of the prisoner’s row. 

\* Note: In the _Unblocker_ prgram the third row is row number 2, since rows and columns are numbered starting with 0.

Moving a block constitutes a move.  For example, in the puzzle shown in Figure 1 the 1x3 block in the first column has two possible moves: _down 1 tile_ or _down 2 tiles_. The red block (the "prisoner") has one possible move: _left 1 tile_.  The 1x2 block in the fourth column has no possible moves.

The puzzles in _Unblock Me_ are organized into four categories of difficulty, as determined by the minimum number of moves required to solve.  The categories are:

* Beginner: 15-20 moves
* Intermediate: 21-25 moves
* Advanced: 26-30 moves
* Expert: 31 moves or more

(There is also an "Original Free" category, which includes puzzles of several levels of difficulty.)

The puzzles in each category are numbered sequentially starting at 1, so to identify a specific puzzle we give the first letter of the category and the number of the puzzle. For example, the puzzle shown in Figure 1 would be denoted "B-7764."

The game can be played in "Relax Mode" or "Challenge Mode".  The puzzles are the same in both modes; the difference is that Challenge Mode displays the minimum number of moves required to solve the puzzle and the number of moves the player has made.

_Unblock Me_ offers a choice of themes, which determine the appearance of the board and the blocks.  There are six "wood" themes (Original 1, Original 2, Oak Wood, Pine Wood, Cherry Wood, and Maple Wood) and several "special" themes (Christmas, Valentine, etc.)  _Unblocker_ will work with any of the "wood" themes, but not with the others.
 
[Contents](#contents)

## Using the app

The procedure for using _Unblocker_ to solve an _Unblock Me_ puzzle is as follows;

1. In _Unblock Me_ set the theme to one of the "wood" themes, and bring up the puzzle to be solved.  (It doesn't matter whether this is the Relax Mode or the Challenge Mode, although all the examples used in this Guide are displayed in Challenge Mode.)
2. Make a screenshot by pressing the Home button and the Power button simultaneously.
3. In _Unblocker_ tap **New puzzle** and select the last image in the camera roll, which should be the screenshot from step 2.
4. Tap **solve**.
5. Use the buttons to play and stop the solution, single-step forward and back, and reset to the initial step.

The home screen shows some statistics about the solution, and of course there are more at the **Additional stats** tab.  If you cannot recall the number of the puzzle you just solved, the **Original image** tab will show it to you.   

The longest-running puzzle I have found is
Puzzle I-4, with timings as shown below. Note that timings
vary from one run to the next, so these numbers are approximate.

Device    |  Debug     | Release
--------- |  --------: | --------: 
iPad Air  |  17.6 sec  | 1.84 sec
iPhone 6  |  21.5 sec  | 2.53 sec
iPhone SE |   8.5 sec  | 0.93 sec

[Contents](#contents)

## How the program works

The next four sections of this Guide go into the working of the program in some detail. While the code listings could have been truncated or eliminated in order to shorten this document, the convenience of having the code inline — as opposed to having to view the code in a different file — outweighed considerations of brevity. If the reader wants to skip the code, it is easy to scroll past it.

Note:  In this Guide, instances of types are denoted by lowercasing the first letter of the type name.  For example, we may use "blockView" to denote an instance of BlockView without saying so explicitly.

[Contents](#contents)

## [Domain & UI models](Unblocker/Domain%20&%20UI%20models.swift)

#### Block

The Block struct represents a block at its current position.

Every instance of the Block struct has a fixed, unique `ID`.
The properties `length`, `isHorizontal`, and `isPrisoner` are also fixed for a given
instance.  In addition, there are three variable properties:  `col`, `row`, and
`hashValue`.

The column and row define the position of the block in the board, which is
represented by the position of the block's topmost or leftmost end.

The ID uniquely identifies a particular block regardless of its position.
The property `hashValue` uniquely identifies a particular block at a particular position
on the board.  Thus `hashValue` not only satisfies the definition of "hash
value" (if two blocks-with-position are equal then their hash values are
equal), but also can be used to define equality (if two blocks-with-position
have the same `hashValue` then they are equal, i.e., their corresponding properties are 
all equal).


~~~ swift
struct Block: Hashable {
   static var nextId = 0
   static func ==(lhs: Block, rhs: Block) -> Bool {
      return lhs.hashValue == rhs.hashValue
   }
   let id: Int
   let length: Int
   let isHorizontal: Bool
   let isPrisoner: Bool
   var col: Int
   var row: Int
   var hashValue: Int {
      return id << 10 | col << 5 | row
   }
   init(col: Int, row: Int, length: Int, isHorizontal: Bool,
        isPrisoner: Bool) {
      id = Block.nextId
      Block.nextId += 1
      self.col = col
      self.row = row
      self.length = length
      self.isHorizontal = isHorizontal
      self.isPrisoner = isPrisoner
   }
}
~~~
	

#### BlockView

The BlockView class is a UIView which represents the corresponding block on the screen.

A `blockView` has a transparent background. On it is drawn an opaque
rounded rectangle which is slightly smaller than the bounds of the
view. The background of `boardView` shows through the transparent
edges of the `blockView` outside of the rounded rectangle, creating
a visual border separating adjacent blocks.
	
On the iPad, `tileSize` can change if the device is rotated.
In that case, `boardView` will set the tile size of `blockView`,
and `blockView` will redraw itself at the correct size and position.

~~~ swift
class BlockView: UIView {
   let id: Int   // This is the ID of the corresponding Block
   let color: UIColor
   let width: Int
   let height: Int
   var col: Int
   var row: Int

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

   override func draw(_ rect: CGRect) {
      let gap = tileSize * Const.gapRatio
      let cornerRadius = gap * 2
      let rect = bounds.insetBy(dx: gap, dy: gap)
      let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
      color.set()
      path.fill()
   }
   
   init(id: Int, color: UIColor, width: Int, height: Int, col: Int,
        row: Int, tileSize: CGFloat)
   {
      self.id = id
      self.color = color
      self.col = col
      self.row = row
      self.width = width
      self.height = height
      self.tileSize = tileSize
      super.init(frame: CGRect.zero)
      layout()
      contentMode = .redraw
      isOpaque = false
      backgroundColor = UIColor.clear
   }
   ...
}   
~~~

#### Board

Elements of a Set must be Hashable (hence also Equatable, by definition of Hashable).
Note that Block satisfies this requirement, so we can define a `Board` to
be a `Set` of `Block` elements.

~~~ swift	
typealias Board = Set<Block>
~~~

#### BoardView

`boardView` is a UIView which represents the playing board on the screen.
Every `blockView` is a subview of the `boardView`. When the dimensions of the board change, each
`blockView` is updated with the new `tileSize`.
	
~~~ swift
class BoardView: UIView {
   override func layoutSubviews() {
      let tileSize = bounds.size.width / CGFloat(Const.cols)
      let blockViews = subviews as! [BlockView]
      for blockView in blockViews {
         blockView.tileSize = tileSize
      }
   }
}
~~~

#### Move

In [the Solver class](Unblocker/Solver.swift), the dictionary **`lookupMoveForBoard(:)`** returns 
the move which was applied to the previous board to arrive at the given 
board. The move identifies the block which was moved and the position
of the block in the previous board.

~~~ swift
struct Move {
   let blockID: Int
   let col: Int
   let row: Int
}
~~~

#### SolutionMove

Once a solution has been found, the Solver class will construct an array
of type `[SolutionMove]`. The UnblockerViewController class will use the array
to animate moves in both the forward and backward directions.  For details about the properties of `SolutionMove` see the comment at the end of `func updateSolution()` in [Solver.swift](Unblocker/Solver.swift).
	
~~~ swift
struct SolutionMove {
   let blockID: Int
   let colFwd: Int
   let rowFwd: Int
   let colBack: Int
   let rowBack: Int
}
~~~

[Contents](#contents)

## Scanning the image

The [Scanner class](Unblocker/Scanner.swift) is responsible for converting an image of an _Unblock Me_ puzzle into a representation
of the puzzle within the domain model.
**`UnblockerViewController.newImage()`** invokes an instance of UIImagePickerController to pick
an image from the photo library, and then passes the image to **`scanner.generateBoard()`**, which returns an instance of the struct Board. Scanner makes use of two structs, `Pixel` and `Pixels`, to represent an image.  These structs were taken almost verbatim from
https://github.com/Swiftor/ImageProcessing.

#### Pixel

A pixel is a 32-bit value which is the concatenation of four 8-bit values representing RGB plus Alpha.

~~~ swift
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
~~~

#### Pixels

An instance of Pixels is effectively a 2-dimensional array, each element of which is a pixel, representing a UIImage image which is passed in the initializer.

~~~ swift
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
~~~

#### getBoardImage()

`getBoardImage()` in class Scanner determines the position of the playing board and the size of the tiles.  First it scans the right edge of the image and detects the position and size of the escape chute, which is a darker color than the rest of the edge. The height of the escape chute is the tile size, and the position of the escape chute determines the position of the playing board.

~~~ swift
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

      // Continue scanning till not empty color, set bottom of escape chute
      repeat {
         let pixel = pixels[pixels.imgWidth-1, y]
         red = pixel.red
         bottomOfEscape = y
         y += 1
      } while red < Const.emptyRedHiThreshold && y < endRow

      // Set tile size equal to the height of the escape chute.
      // Horizontal center of image is horizontal center of board.
      // Bottom  of escape chute is vertical center of board.
      

      self.tileSize = bottomOfEscape - topOfEscape
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
~~~

#### convertTile()

**`convertTile(:)`** is a method to convert row or col to a coordinate of a pixel at (or near) the center of a tile.

~~~ swift
private func convertTile(_ coordinate:Int) -> Int {
   return coordinate*tileSize + tileSize/2
}
~~~

#### generateBoard()

Method `generateBoard()` uses the array of pixels returned by `getBoardImage()` and returns an optional board.  If the presumed board does not follow the rules of the game, the method returns nil.

In `generateBoard()` and `getBoardImage()`, the values used to test colors of pixels were determined by experiment, using the cherry wood theme.  Serendipitously the same values work for all the "wood" themes.

~~~ swift
func generateBoard(fromImage image:UIImage) -> Board? {
   guard var pixels = getBoardImage(fromImage: image) else {return nil}
   var board = Board()
   wasVisited.reset()
   Block.nextId = 0

   // MARK: Main loop for func generateBoard
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
         // Operator ^^ is exclusive OR; see "Extensions & generics.swift"
         guard blockWidth==1 ^^ blockHeight==1 else {return nil}
         let block = Block(
            col: col,
            row: row,
            length: max(blockWidth, blockHeight),
            isHorizontal: blockWidth > 1,
            isPrisoner: pixels[convertTile(col),convertTile(row)].green <
               Const.redBlockGreenHiThreshold
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
      if prisoner.isHorizontal && prisoner.length == 2 && prisoner.row == 2 {
         return board
      }
   }
   return nil
}
~~~

#### findBlockwidth() and findBlockheight()

`findBlockwidth(col: row: pixels:)` returns the width of the block at [col, row] and sets `wasVisited = true` for every tile in row number `row` which is covered by the block.  The code for 
`findBlockheight(col: row: pixels:)` is similar but returns the height of the block.

~~~ swift
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
~~~

[Contents](#contents)

## Solving the puzzle

The [Solver class](Unblocker/Solver.swift) is responsible for finding a solution. **`solve(initialBoard:)`** takes an argument of type `Board` and returns a result of optional type `Solution?`.

#### Struct Solution

~~~ swift
struct Solution {
   var timeInterval: TimeInterval = 0.0
   var numMoves = 0
   var initialBoard: Board = []
   var winningBoard: Board = []
   var numBoardsExamined: Int = 0
   var numBoardsEnqueued: Int = 0
   var finalQSize: Int = 0
   var maxQSize: Int = 0
   var numBoardsExaminedAtLevel: [Int] = []
   var numBoardsEnqueuedAtLevel: [Int] = []
   var boardAtLevel: [Board] = []
   var moves: [SolutionMove] = []
   var isUnsolvable = false
}
~~~  

#### Solution algorithm

We define a "level" of a board as the number of moves took to reach that board, starting from the initial board. As we shall see in a moment, in _Unblocker_ the level is in fact _the minimum_ number of moves required to reach the given board from the initial board, so it makes sense to talk about _the_ level of a board.

We will need two constructs to hold data, a queue **`q = Queue<(Board,Int)>()`**, where the generic type `Queue` is defined in the file [Extensions & generics.swift](Unblocker/Extensions%20&%20generics.swift), and a dictionary **`lookupMoveForBoard: [Board : Move]`**.    For a given board, `lookupMoveForBoard[board]` returns the move which
was applied to the previous board to arrive at the given board.  The move identifies the block which was moved and its position in the previous board.

The puzzle is solved with a ["breadth-first" search](https://en.wikipedia.org/wiki/Breadth-first_search). Each node of q is a tuple consisting of a board and a level.
To start with, q has just one entry, initialBoard at level 0. As the solution progresses, boards and their levels are removed from the top of q, and other boards and their levels are added to the bottom of q. Since the added boards are in non-decreasing order of level, every possible board at level n is dequeued and examined before any board at level n+1.  Therefore a solution, if it exists, will eventually be found (provided there is enough time and memory available), and there will be no solution at any lower level.  In fact, _every_ board in q is inserted into q at the lowest possible level for that board.

Here is the procedure in more detail.  

* Starting with an empty queue, enqueue (initialBoard, 0)
* While queue is not empty and no solution has been found
    * Dequeue (currentBoard, currentLevel)
    * For every newBoard which can be derived from currentBoard by moving one block
        * If newBoard is in dictionary it was found at a lower level, so skip to next newBoard
        * Otherwise calculate move from currentBoard to newBoard
        * Add [newBoard : move] to dictionary
        * Enqueue (newBoard, currentLevel+1)
        * If newBoard has prisoner adjacent to escape chute then newBoard is a winner; mark solution solved and break out of both loops
* If q is empty and no solution has been found, mark solution unsolvable 
* Return solution

#### solve()

Because it may take a significant amount of time to run, `solve()` runs in a GCD queue which is not the main queue, i.e., it runs in a separate thread. In order to terminate `solve()` while it is running, UnblockerViewController sets `abortingSolve = true`.

~~~ swift
   func solve(initialBoard: Board) -> Solution? {
      if initialBoard.isEmpty {return nil}
      if abortingSolve {return nil}
      solution.isUnsolvable = false
      solution = Solution()
      solution.initialBoard = initialBoard
      startTime = Date()
      solution.numBoardsEnqueuedAtLevel.append(1)
      solution.numBoardsExaminedAtLevel.append(1)
      var allDone = false
      lookupMoveForBoard = [:]
      // Set blockID to -1 as sentinel
      lookupMoveForBoard[initialBoard] = Move(blockID: -1, col:0, row:0)
      q.clearQueue()
      q.enQueue((initialBoard,0))
      solution.maxQSize = q.size

      // MARK: Outer loop
      while !q.isEmpty && !allDone {
         let currentBoard = q.peek()!.0
         currentLevel = q.deQueue()!.1
         var isOccupied = Matrix<Bool>(cols: Const.cols, rows: Const.rows, defaultElement: false)

         // Mark occupied tiles
         for block in currentBoard {
            let width = block.isHorizontal ? block.length : 1
            let height = block.isHorizontal ? 1 : block.length
            for col in block.col..<block.col+width {
               for row in block.row..<block.row+height {
                  isOccupied[col, row] = true
               }
            }
         }

         // MARK: Inner loop
         // may be executed tens of thousands of times
         //
         for block in currentBoard {
            let length = block.length
            if block.isHorizontal {

               // Check tiles to left of block until encountering an
               // occupied tile or the left edge of the board.

               var col = block.col - 1
               while col >= 0 && !isOccupied[col, block.row] && !allDone {
                  allDone = registerBoard(currentBoard,
                                          block: block,
                                          col: col,
                                          row: block.row,
                                          level: currentLevel+1)
                  col -= 1
               }

               // Check tiles to right of block until encountering an
               // occupied tile or the right edge of the board.

               col = block.col + length
               while col < Const.cols && !isOccupied[col, block.row] && !allDone {
                  allDone = registerBoard(currentBoard,
                                          block: block,
                                          col: col-length+1,
                                          row: block.row,
                                          level: currentLevel+1)
                  col += 1
               }

            } else { // Block is vertical

               // Check tiles above block until encountering an
               // occupied tile or the top edge of the board.

               var row = block.row - 1
               while row >= 0 && !isOccupied[block.col, row] && !allDone {
                  allDone = registerBoard(currentBoard,
                                          block: block,
                                          col: block.col,
                                          row: row,
                                          level: currentLevel+1)
                  row -= 1
               }

               // Check tiles below block until encountering an
               // occupied tile or the bottom edge of the board.

               row = block.row + length
               while row < Const.rows && !isOccupied[block.col, row] && !allDone {
                  allDone = registerBoard(currentBoard,
                                          block: block,
                                          col: block.col,
                                          row: row-length+1,
                                          level: currentLevel+1)
                  row += 1
               }
            }
            if allDone {break}
         }    // for block in currentBoard (Inner loop)
      }    // while !q.isEmpty && !allDone (Outer loop)
      if abortingSolve {
         abortingSolve = false
         return nil
      }
      if q.isEmpty && !allDone {
         updateSolution(forWinningLevel: currentLevel, winningBoard: [], isUnsolvable: true)
      }
      return solution
   }
~~~

#### registerBoard()

The `solve()` method calls **`registerBoard()`**, which moves a given block to a given position in a given board, and if the result has not been seen before adds the board to the dictionary and the queue.

~~~ swift
   private func registerBoard(
      _ board: Board,
      block: Block,
      col:Int,
      row:Int,
      level:Int) -> Bool {

      // Any board is only enqueued once.  When dequeuing
      // there is no need to check whether the board
      // has already been visited.

      // Create new board by moving a block
      if abortingSolve {return true}
      var newBoard = board
      var newBlock = newBoard.remove(block)!
      newBlock.col = col
      newBlock.row = row
      newBoard.insert(newBlock)

      // Bump counter
      if level == solution.numBoardsExaminedAtLevel.count {
         solution.numBoardsExaminedAtLevel.append(0)
      }
      solution.numBoardsExaminedAtLevel[level] += 1

      // If newBoard was already enqueued, ignore it
      if lookupMoveForBoard[newBoard] != nil {return false}

      // Bump other counter
      if level == solution.numBoardsEnqueuedAtLevel.count {
         solution.numBoardsEnqueuedAtLevel.append(0)
      }
      solution.numBoardsEnqueuedAtLevel[level] += 1

      // Compute move from board to newBoard, update dictionary and queue

      let move = Move(blockID: block.id, col: block.col, row: block.row)
      lookupMoveForBoard[newBoard] = move
      q.enQueue((newBoard,level))
      if solution.maxQSize < q.size {solution.maxQSize = q.size}

      // If newBoard is a winning board, wrap it up;
      // otherwise keep on truckin'.
      if newBlock.isPrisoner && newBlock.col == Const.cols - 2 {
         updateSolution(forWinningLevel: level, winningBoard: newBoard, isUnsolvable: false)
         return true
      } else {
         return false
      }
   }
~~~

[Contents](#contents)

#### updateSolution()
 
The **`updateSolution()`** method assigns values to the `solution` entity.

~~~ swift
   private func updateSolution(forWinningLevel level:Int,
                               winningBoard board:Board,
                               isUnsolvable: Bool) {
      solution.numBoardsEnqueued = 0
      solution.numBoardsExamined = 0
      for index in 0...level {
         solution.numBoardsEnqueued += solution.numBoardsEnqueuedAtLevel[index]
         solution.numBoardsExamined += solution.numBoardsExaminedAtLevel[index]
      }
      // Set properties which were not set previously
      solution.winningBoard = board
      solution.numMoves = level
      solution.finalQSize = q.size
      solution.timeInterval = Date().timeIntervalSince(startTime)
      solution.isUnsolvable = isUnsolvable
      if isUnsolvable {return}

      // Change winning board to have prisoner block offstage
      var board = solution.winningBoard
      let block = board.first(where: {$0.isPrisoner})!
      let move = lookupMoveForBoard[board]!
      lookupMoveForBoard[board] = nil
      var newBlock = board.remove(block)!
      newBlock.col = Const.cols + 1 // "Offstage" is (7, 2)
      board.insert(newBlock)
      lookupMoveForBoard[board] = move
      solution.winningBoard = board

      //************************************************************************
      // Populate arrays solution.moves and solution.boardAtLevel

      while true { // "infinite" loop will exit when blockID = -1

         // We traverse the solution "backwards", i.e., from the final (winning)
         // board to the initial board.

         // Insert board at beginning of solution.boardAtLevel
         solution.boardAtLevel.insert(board, at: 0)

         //*********************************************************************
         // Compute solutionMove and insert it at beginning of solution.moves

         let move = lookupMoveForBoard[board]!
         if move.blockID == -1 {break} // -1 blockID is sentinel
         // Get the block which moves
         let block = board.first(where: {$0.id == move.blockID})!
         // Remove it from the board
         var newBlock = board.remove(block)!
         // Update its position
         newBlock.col = move.col
         newBlock.row = move.row
         // Put it back in the board, ready for the next pass through the loop
         board.insert(newBlock)

         // Although we can think of 'newBlock' as "the same block as 'block,'
         // but in a different position," they are in fact two distinct
         // elements of 'board,' which is just a set of blocks.  That is why we
         // remove 'block' from the board and put 'newBlock' in.

         // Generate the corresponding 'solutionMove'
         let solutionMove = SolutionMove(
            blockID: block.id,
            colFwd: block.col,
            rowFwd: block.row,
            colBack: newBlock.col,
            rowBack: newBlock.row
         )
         solution.moves.insert(solutionMove, at: 0)
      } // while true

      // moves[n].blockID identifies the sole block whose position in
      // boardAtLevel[n] differs from its position in boardAtLevel[n+1]. That
      // block's coordinates in boardAtLevel[n] are (moves[n].colBack, moves[n].rowBack),
      // and its coordinates in boardAtLevel[n+1] are (moves[n].colFwd, moves[n].rowFwd).

   } // private func updateSolution
} // class Solver
~~~

[Contents](#contents)

## User interface
**(aka "Punt Time for the Documentation, which is _way_ too long already")**

Most of the user interface is in [Main.storyboard](Unblocker/Main.storyboard) and [UnblockerViewController.swift](Unblocker/UnblockerViewController.swift) (The latter contains 624 lines of code!). Classes BlockView and BoardView are also important pieces of the UI; they are in the file 
[Domain & UI models.swift](Unblocker/Domain%20&%20UI%20models.swift).

Although programming the UI required by far the largest investment of time and effort in this project, I don't think the UI is very interesting compared to the problems solved by the Scanner and Solver classes.  I will get around to documenting the UI eventually, but not right now.  I did try to put the code in some sort of rational order, and I made extensive use of the MARK: comment in _UnblockerController.swift_, although there are not many other comments. If you want to slog through it, I recommend perusing the code in Xcode, making good use of the jump bar, jump to definition, find in project, etc.

The animations in the app are UIView animations. I did it that way because I knew how to do it. UIView animations work just fine, but one of these days I'll learn Core Animation.  Perhaps that would have been the better tool; I don't know. 

[Contents](#contents)

## Observations

The solver uses a pure brute force approach, unlike human players, who would be hard put to solve a puzzle if they had to consider thousands of possibilities, as _Unblocker_ does. The human solver uses heuristics which quickly eliminate most of the possibilities. We could try to implement some sort of heuristic in _Unblocker_, but the program as it stands solves so quickly that there would not be much point in doing that. Besides, the program is guaranteed to find a solution in the minimal number of moves, which might not be the case if heuristics were involved.
   
There does not seem to be much correlation between the number of moves required for a solution with the amount of time the solving takes. To date, the longest solve time has been Puzzle I-4, which has a 23-move solution and requires examining 522,541 boards (40,919 different boards). Puzzle E-535, on the other hand, requires 51 moves, but only 22,622 boards (3,025 different boards) need to be examined. Incidentally, I believe E-535 requires the greatest number of moves of all the puzzles in the Kiragames selection.

![Puzzle I-4](images/Puzzle-I-4.png) ![Puzzle E-535](images/Puzzle-E-535.jpg)

I used Photoshop Elements to create a couple of unsolvable puzzles, and include them here in case you want to try them out.  (The first one started life as B-5572, but it has been altered.)

![no solution 1](images/no-solution-1.jpg) ![no solution 2](images/no-solution-2.jpg)

## Future additions

I have a couple of ideas for extending the program, which I may or may not get around to implementing.

1. Allow the user to edit a board, or create one from scratch.
1. Create a database of puzzles and solutions, which could be used to look for patterns.

If you would like to tackle one of these or some other idea of your own you are 
welcome to do so, although I would be surprised if anyone besides me has that much interest in the project.

[Contents](#contents)

