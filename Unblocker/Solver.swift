//
//  Solver.swift
//
//  Unblocker
//  Swift 3.1
//
//  Copyright © 2017 Cameron C. Pitcairn.
//  See the file license.txt in the Unblocker project.
//

import Foundation

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

/*******************************************************************************
 Solution is by a breadth-first search. Each node of the queue named q is a
 tuple consisting of a board and a level. The level is the number of moves
 by which the board was reached from initialBoard. To start with, q has just one
 entry, initialBoard at level 0. As the solution progresses, boards are added to
 the bottom of q and other boards are removed from the top of q. Since the
 added boards are in non-decreasing order of level, every possible board at
 level n is dequeued and examined before any board at level n+1.  Therefore a
 solution, if it exists, will eventually be found (provided there is enough
 memory available), and there will be no solution at any lower level.

 The procedure in more detail:

 The method solve() removes a board from the top of the queue (call it
 currentBoard, with level currentLevel) and generates every board which
 can be obtained by moving just one block in currentBoard.  If a generated
 board, call it newBoard, is a key in the dictionary lookUpMoveForBoard[:], then
 newBoard was already encountered earlier (i.e. on a lower level) so it is
 discarded.  Otherwise, the program sets lookupMoveForBoard[newBoard] = move,
 where move is the move which was applied to currentBoard to reach newBoard.
 Then newBoard is added to the bottom of q, with a level of currentLevel + 1.
 Finally, if the most recently moved block is the prisoner block and is adjacent
 to the escape chute, then newBoard is the winning board and the solution has
 been found.  All that remains is to finish setting the properties in var
 solution (which is an instance of struct Solution).
 *******************************************************************************/

// MARK: -
//
class Solver {

   // UnblockerViewController, which runs in the main thread, will set
   // abortingSolve = true in order to abort method solve(), which runs in
   // a different thread.
   var abortingSolve = false
   var solution = Solution()
   var currentLevel = 0
   private var q = Queue<(board: Board, level:Int)>()
   private var startTime = Date()

   // For a given board, dictionary lookupMoveForBoard returns the move which
   // was applied to the previous board to arrive at the given board.  The move
   // identifies the block which was moved and its position in the previous 
   // board.
   private var lookupMoveForBoard: [Board : Move] = [:]

   //***************************************************************************
   // MARK: -
   // Solve for given initial board.  Return nil if solving is aborted;
   // otherwise return solution.  If puzzle is unsolvabe, return "solution"
   // with isUnsolvable set to true.

   func solve(initialBoard: Board) -> Solution? {
      if initialBoard.isEmpty {return nil}
      if abortingSolve {return nil}
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
         let node = q.deQueue()!
         let currentBoard = node.board
         currentLevel = node.level
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
         for block in currentBoard where !block.isFixed{
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

   //***************************************************************************
   // MARK: -
   // Move block in board to (col, row). If resulting newBoard is not in
   // dictionary lookupMoveForBoard, compute move and add [newBoard:move] to
   // dictionary. Also in this case enqueue (newBoard, level).  Then check if
   // a solution has been found. Return true if a solution has been found or
   // solve() is being aborted; otherwise return false.

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

   //***************************************************************************
   // MARK: -
   // Finish up after solution has been found

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

      //************************************************************************
      // Change winning board to have prisoner block offstage

      // Get last move
      var board = solution.winningBoard
      let move = lookupMoveForBoard[board]!
      // Delete old winning board from dictionary
      lookupMoveForBoard[board] = nil
      // Get last block moved
      let block = board.first(where: {$0.id == move.blockID})!
      // Last block moved must be prisoner
      assert(block.isPrisoner)
      // Move prisoner "offstage" to position (7, 2)
      var newBlock = board.remove(block)!
      newBlock.col = Const.cols + 1
      board.insert(newBlock)
      // Add new winning board to dictionary
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



