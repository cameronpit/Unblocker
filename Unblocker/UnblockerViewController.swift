//
//  UnblockerViewController.swift
//
//  Unblocker
//  Swift 3.1
//
//  Copyright © 2017 Cameron C. Pitcairn.
//  See the file license.txt in the Unblocker project.
//
//  Tab bar icons provided by http://www.iconbeast.com
//

import UIKit

//******************************************************************************
// MARK: - Define, and relate, program states and program operations
       
private enum ProgramState {
   case boardEmpty
   case notSolved
   case solutionInProgress
   case solutionPlaying
   case atFirstStep
   case atLastStep
   case atOtherStep
   case noSolutionExists
}

private enum ProgramOperation {
   case solve
   case playAll
   case reset
   case stepForward
   case stepBack
   case newImage
}

private func isOperation(_ operation: ProgramOperation,
                         ValidForState state: ProgramState) -> Bool {
   switch state {
   case .boardEmpty:
      switch operation {
      case .newImage: return true
      default: return false
      }
   case .notSolved:
      switch operation {
      case .newImage: return true
      case .solve: return true
      default: return false
      }
   case .atFirstStep:
      switch operation {
      case .newImage: return true
      case .solve: return true
      case .playAll: return true
      case .stepForward: return true
      default: return false
      }
   case .atLastStep:
      switch operation {
      case .newImage: return true
      case .reset: return true
      case .stepBack: return true
      default: return false
      }
   case .atOtherStep:
      switch operation {
      case .playAll: return true
      case .newImage: return true
      case .reset: return true
      case .stepForward: return true
      case .stepBack: return true
      default: return false
      }
   case .solutionInProgress:
      switch operation {
      case .reset: return true
      default: return false
      }
   case .solutionPlaying:
      switch operation {
      case .reset: return true
      case .playAll: return true
      default: return false
      }
   case .noSolutionExists:
      switch operation {
      case .newImage: return true
      case .solve: return true
      default: return false
      }
   }
}

//******************************************************************************
// MARK: -

class UnblockerViewController: UIViewController, UINavigationControllerDelegate,
   UIImagePickerControllerDelegate, TextProviderDelegate, ImageProviderDelegate
{

   //**************************************************************************
   // MARK: - Outlets

   @IBOutlet weak var boardView: BoardView!
   @IBOutlet weak var messageLabel: UILabel!
   @IBOutlet weak var spinner: UIActivityIndicatorView!

   // Buttons
   @IBOutlet weak var solveButton: UIButton!
   @IBOutlet weak var playAllButton: UIButton!
   @IBOutlet weak var resetButton: UIButton!
   @IBOutlet weak var stepForwardButton: UIButton!
   @IBOutlet weak var stepBackButton: UIButton!
   @IBOutlet weak var newImageButton: UIButton!

   // Labels
   @IBOutlet weak var timeLabel: UILabel!
   @IBOutlet weak var allBoardsLabel: UILabel!
   @IBOutlet weak var uniqueBoardsLabel: UILabel!
   @IBOutlet weak var maxQLabel: UILabel!
   @IBOutlet weak var finalQLabel: UILabel!
   @IBOutlet weak var movesLabel: UILabel!
   @IBOutlet weak var currentStepLabel: UILabel!
   @IBOutlet weak var blocksLabel: UILabel!
   @IBOutlet weak var tilesLabel: UILabel!


   //**************************************************************************
   // MARK: - Properties

   let solver = Solver()
   let serialQueue = DispatchQueue(label: "com.braehame.unblocker")
   let picker = UIImagePickerController()
   var solution: Solution!  // struct Solution declared in file Solver.swift
   var initialBoard: Board = []
   var puzzle: Puzzle!
   var originalImage: UIImage?

   var savedTileSize: CGFloat? // Used in viewDidLayoutSubviews()

   var tileSize: CGFloat {
      let returnValue = boardView.bounds.size.width / CGFloat(Const.cols)
      if savedTileSize == nil {
         savedTileSize = returnValue
      }
      return returnValue
   }

   var numBlocks = 0 {
      didSet {
         blocksLabel.text = String(numBlocks)
      }
   }

   var tiles = 0 {
      didSet {
         tilesLabel.text = String(tiles)
      }
   }

   var step = 0 {
      didSet {setStepLabel(step)}
   }

   //**************************************************************************
   // MARK: - Provide data for other tabs in tabBarController

   let noImageMessage = "No image has been selected\n\nTap \"New puzzle\""

   let invalidImageMessage = "The image you selected is not recognized by"
      + " Unblocker as a valid Unblock Me puzzle.\n\nTry a different image."

   let notSolvedMessage = "Statistics will be computed when"
      + " Unblocker solves the puzzle.\n\nTap \"Solve\""
      + " on the home screen."

   let noSolutionExistsMessage =  "No solution exists!"

   var imageToShow: UIImage? {
      return originalImage
   }

   var textToShow: String? {
      return statsText()
   }

   func statsText() -> String {
      guard originalImage != nil else { return noImageMessage +
         " on the home screen" }
      guard state != .boardEmpty else { return invalidImageMessage }
      guard state != .notSolved && solution != nil
         else { return notSolvedMessage }

      var statsText = ""
      if state == .noSolutionExists {
         statsText += "The puzzle was determined to be unsolvable after checking "
         statsText += "levels 0 to \(solution.numMoves) in "
      } else {
         statsText += "A solution was found at level \(solution.numMoves) in "
      }
      statsText += "\(String(format: "%.2f", solution.timeInterval)) seconds. "
      statsText += "Maximum queue size was \(solution.maxQSize) entries "
      statsText += "and final dictionary size was "
      statsText += "\(solution.numBoardsEnqueued) entries.\n\n"

      statsText += "Boards".rightAlign(inWidth: 17)
      statsText += "Boards".rightAlign(inWidth: 11)+"\n"

      statsText += "Level".rightAlign(inWidth: 8)
      statsText += "Examined".rightAlign(inWidth: 10)
      statsText += "Enqueued".rightAlign(inWidth: 11)+"\n\n"

      for index in 0...solution.numMoves {
         statsText += String(index).rightAlign(inWidth: 7)
         statsText += String(solution.numBoardsExaminedAtLevel[index]).rightAlign(inWidth: 10)
         statsText += String(solution.numBoardsEnqueuedAtLevel[index]).rightAlign(inWidth: 10)+"\n"
      }

      statsText += "\n" + "Totals:".rightAlign(inWidth: 8)
      statsText += String(solution.numBoardsExamined).rightAlign(inWidth: 9)
      statsText += String(solution.numBoardsEnqueued).rightAlign(inWidth: 10) + "\n"

      statsText += "\n" + "Per sec:".rightAlign(inWidth: 8)

      var value = Double(solution.numBoardsExamined)/solution.timeInterval
      statsText +=  String(format: "%9.f", value)

      value = Double(solution.numBoardsEnqueued)/solution.timeInterval
      statsText += String(format: "%10.f", value) + "\n"

      value = Double(solution.numBoardsExamined) / Double(solution.numBoardsEnqueued)
      statsText += "\nExamined/Enqueued = "
      statsText += String(format: "%.1f", value) + "\n"

      return statsText
   }

   //**************************************************************************
   // MARK: - Manage program state

   private var state: ProgramState = .boardEmpty {
      didSet {
         boardView.puzzle = state == .boardEmpty ? nil : puzzle
         setButtons(ForState: state)
         setMessageLabel(ForState: state)
      }
   }

   private func setButtons(ForState state: ProgramState) {
      if state == .solutionInProgress {
         solveButton.isHidden = true
         spinner.startAnimating()
      } else {
         spinner.stopAnimating()
         solveButton.isHidden = false
      }
      if state == .solutionPlaying {
         playAllButton.setTitle("Stop", for: UIControlState())
      } else {
         playAllButton.setTitle("Play", for: UIControlState())
      }
      solveButton.isEnabled = isOperation(.solve, ValidForState: state)
      playAllButton.isEnabled = isOperation(.playAll, ValidForState: state)
      resetButton.isEnabled = isOperation(.reset, ValidForState: state)
      stepForwardButton.isEnabled = isOperation(.stepForward, ValidForState: state)
      stepBackButton.isEnabled = isOperation(.stepBack, ValidForState: state)
      newImageButton.isEnabled = isOperation(.newImage, ValidForState: state)
   }

   private func setMessageLabel(ForState state: ProgramState) {
      messageLabel.backgroundColor = Const.emptyBackgroundColor
      if originalImage == nil {
         messageLabel.textColor = Const.normalMessageLabelColor
         messageLabel.text = noImageMessage
      } else if state == .boardEmpty {
         messageLabel.textColor = Const.urgentMessageLabelColor
         messageLabel.text = invalidImageMessage
      } else if state == .noSolutionExists {
         let fullMessage = "\n    \(noSolutionExistsMessage)    \n"
            + "    Halted at level \(solution.numMoves).\n"
         messageLabel.textColor = Const.urgentMessageLabelColor
         messageLabel.text = fullMessage
      } else {
         messageLabel.text = nil
      }
   }

   //**************************************************************************
   //MARK: - Label methods

   func setLabels(time: Double,
                  allBoards: Int,
                  uniqueBoards: Int,
                  maxQ: Int,
                  finalQ: Int,
                  moves: Int )  {
      timeLabel.text = String(format: "%.2f", time)
      allBoardsLabel.text = String(allBoards)
      uniqueBoardsLabel.text = String(uniqueBoards)
      maxQLabel.text = String(maxQ)
      finalQLabel.text = String(finalQ)
      movesLabel.text = String(moves)
   }

   func setStepLabel(_ step: Int) {
      currentStepLabel.text = String(step)
   }

   func clearLabels() {
      timeLabel.text = "---"
      allBoardsLabel.text = "------"
      uniqueBoardsLabel.text = "-----"
      maxQLabel.text = "----"
      finalQLabel.text = "----"
      movesLabel.text = "--"
      currentStepLabel.text = (state == .boardEmpty) ? "--" : "0"
   }

   //**************************************************************************
   // MARK: - UIViewController methods

   override func viewDidLoad() {
      super.viewDidLoad()
//      boardView.contentMode = .redraw
      picker.delegate = self
      state = .boardEmpty
      assignDelegates()

   }

   func assignDelegates() {
      if let tabBarVC = self.tabBarController {
         for viewController in tabBarVC.viewControllers! {
            if let showTextVC = viewController as? TextViewController {
               showTextVC.delegate = self
            } else {
               if let showImageVC = viewController as? ImageViewController {
                  showImageVC.delegate = self
               }
            }
         }
      } else { assert(false) }
   }

   override func viewDidLayoutSubviews() {
      super.viewDidLayoutSubviews()
      // If tileSize has changed, stop playback
      if tileSize != savedTileSize {
         savedTileSize = tileSize
         if state == .solutionPlaying { stopPlaying() }
      }
   }

   override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      if state == .solutionPlaying { stopPlaying() }
   }

   //**************************************************************************
   // MARK: - Get and scan puzzle image

   @IBAction func newImage() {
      guard isOperation(.newImage, ValidForState: state) else {return}

      // If picker.allowsEditing is false, then the image is selected as soon
      // as the thumbnail is tapped. The problem with this is that on some
      // devices the thumbnail is cropped, so that important information
      // such as the number of the puzzle cannot be seen. In order to display
      // the full-size uncropped image, we set allowsEditing to true, although
      // any actual editing of the image will be ignored.
      picker.allowsEditing = true
      present(picker, animated: true, completion: nil)
   }

   func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      dismiss(animated: true, completion: nil)
   }

   func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
      // Use the original image, that is, ignore the editing (if any).
      if let newImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
         originalImage = newImage
         let scanner = Scanner()
         if let optPuzzle = (scanner.generatePuzzle(fromImage: newImage)) {
            puzzle = optPuzzle
            initialBoard = puzzle.initialBoard
            solution = nil
            displayBoard(initialBoard)
            state = .notSolved
         } else {
            // Image not recognized
            clearBoard() // Sets state = .boardEmpty, among other things
         }
      } else {
         // No image -- happens rarely, if at all
         print("NO IMAGE RETURNED BY IMAGE PICKER CONTROLLER")
         clearBoard()
      }
      clearLabels()
      dismiss(animated: true, completion: nil)
   }

   //**************************************************************************
   // MARK: - Find solution
   // Method solver.solve() is executed on a separate thread, since it can be
   // time-consuming, depending on the speed of the device, and on whether
   // debugging is active.  The longest-running puzzle I have found is
   // Intermediate Puzzle #4, with timings as shown below. Note that timings
   // vary from one run to the next, so these numbers are approximate.
   //
   // Device       Debug       Release
   // =========    ========    ========
   // iPad Air     17.6 sec    1.84 sec
   // iPhone 6     21.5 sec    2.53 sec
   // iPhone SE     8.5 sec    0.93 sec

   @IBAction func solve() {
      guard isOperation(.solve, ValidForState: state) else {return}
      state = .solutionInProgress
      solution = nil
      clearLabels()
      serialQueue.async { [unowned self] in
         self.solution = self.solver.solve(puzzle: self.puzzle)
         DispatchQueue.main.async { [unowned self] in
            if self.state == .solutionInProgress {
               if self.solution != nil {
                  self.setLabels(
                     time: self.solution.timeInterval,
                     allBoards: self.solution.numBoardsExamined,
                     uniqueBoards: self.solution.numBoardsEnqueued,
                     maxQ: self.solution.maxQSize,
                     finalQ: self.solution.finalQSize,
                     moves: self.solution.numMoves
                  )
                  if self.solution.isUnsolvable {
                     self.state = .noSolutionExists
                  } else {
                     self.step = 0
                     self.state = .atFirstStep
                  }
               } else {
                  self.state = .notSolved
               } // if self.solution != nil
            } //  if self.state == .solutionInProgress
         } // DispatchQueue.main.async
      } // serialQueue.async
   } // func solve()

   //**************************************************************************
   // MARK: - Show moves

   @IBAction func stepForward() {
      guard isOperation(.stepForward, ValidForState: state) else {return}
      assert (step < solution.moves.count)
      moveBlock(index: step,
                duration: Const.blockViewAnimationDuration,
                delay: 0.0,
                isBack: false)
      step += 1
      if step == solution.moves.count {
         state = .atLastStep
      } else {
         state = .atOtherStep
      }
   }

   @IBAction func stepBack() {
      guard isOperation(.stepBack, ValidForState: state) else {return}
      step -= 1
      moveBlock(index: step,
                duration: Const.blockViewAnimationDuration,
                delay: 0.0,
                isBack: true)
      if step == 0 {
         state = .atFirstStep
      } else {
         state = .atOtherStep
      }
   }

   @IBAction func playSolution() {
      guard isOperation(.playAll, ValidForState: state) else {return}
      if state == .solutionPlaying {
         stopPlaying()
         return
      }
      state = .solutionPlaying
      setStepLabel(step+1)
      var delay = 0.0
      for index in step..<solution.numMoves {
         moveBlock(index: index,
                   duration: Const.blockViewAnimationDuration,
                   delay: delay,
                   isBack: false)
         delay += Const.blockViewAnimationDelay
      }
   }

   //**************************************************************************
   // MARK: - Reset

   @IBAction func resetBoard() {
      guard isOperation(.reset, ValidForState: state) else {return}
      if solution == nil {
         state = .notSolved
         solver.abortingSolve = true
         return
      }
      displayBoardAtStep(step)
      for blockView in boardView.subviews as! [BlockView] {
         // Find block in initial board corresponding to blockView
         let block = solution.initialBoard.first(where: {$0.id == blockView.id})!
         UIView.animate(
            withDuration: Const.boardViewResetAnimationDuration,
            delay: 0.0,
            options: [],
            animations: {
               blockView.col = block.col
               blockView.row = block.row
               blockView.layout() },
            completion: nil
         )
      }
      step = 0
      state = .atFirstStep
   }

   //**************************************************************************
   // MARK: - Supporting methods

   func moveBlock(index:Int, duration: Double, delay: Double, isBack: Bool) {
      // Note that here move is of type SolutionMove and moves is of type
      // [SolutionMove]
      let moves = solution.moves
      let move = moves[index]
      let col = isBack ? move.colBack : move.colFwd
      let row = isBack ? move.rowBack : move.rowFwd
      // Find the blockView to be moved
      let blockView = (boardView.subviews as! [BlockView])
         .first(where: {$0.id == move.blockID})!
      UIView.animate(
         withDuration: duration,
         delay: delay,
         options: [.curveEaseInOut],
         animations: {
            blockView.col = col
            blockView.row = row
            blockView.layout() },
         completion: {[unowned self] done in
            if done && self.state == .solutionPlaying {
               self.step = index + 1
               if self.step < self.solution.numMoves {
                  self.setStepLabel(self.step + 1)
               }
               if index == self.solution.numMoves - 1 {
                  self.state = .atLastStep
               }
            }
         }
      )
   }

   func stopPlaying() {
      if step < solution.numMoves {
         step += 1
      }
      displayBoardAtStep(step)
   }

   func displayBoardAtStep(_ step: Int) {
      let board = solution.boardAtLevel[step]
      displayBoard(board)
      self.step = step
      switch step {
      case 0:
         state = .atFirstStep
      case solution.moves.count:
         state = .atLastStep
      default:
         state = .atOtherStep
      }
   }

   func displayBoard(_ board: Board){
      clearBoardView()
      numBlocks = board.count
      tiles = 0
      boardView.backgroundColor = Const.boardBackgroundColor
      // displayEscape()
      for block in board {
         tiles += block.length
         let blockColor = block.isPrisoner ? Const.prisonerBlockColor : Const.normalBlockColor
         let width = block.isHorizontal ? block.length : 1
         let height = block.isHorizontal ? 1 : block.length
         let blockView = BlockView(
            id: block.id,
            color: blockColor,
            width: width,
            height: height,
            col: block.col,
            row: block.row,
            tileSize: tileSize,
            isFixed: block.isFixed
         )
         boardView.addSubview(blockView)
      }
   }

   func clearBoard() {
      clearBoardView()
      solution = nil
      initialBoard = []
      state = .boardEmpty
   }

   // If an animation is running, clearBoardView will terminate it, since it
   // deletes all the animated blocks.
   func clearBoardView() {
      for view in boardView.subviews {
         view.removeFromSuperview()
      }
      blocksLabel.text = "--"
      tilesLabel.text = "--"
      boardView.backgroundColor = Const.emptyBackgroundColor
   }

}
