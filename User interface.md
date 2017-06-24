## User interface

Most of the user interface is in [Main.storyboard](Unblocker/Main.storyboard) and [UnblockerViewController.swift](Unblocker/UnblockerViewController.swift) (The latter contains 624 lines of code!). Classes BlockView and BoardView are also important pieces of the UI; they are in the file 
[Domain & UI models.swift](Unblocker/Domain%20&%20UI%20models.swift).

>Although programming the UI required by far the largest investment of time and effort in this project, I don't think the UI is very interesting compared to the problems solved by the Scanner and Solver classes.  I will get around to documenting the UI eventually, but not right now.  I did try to put the code in some sort of rational order, and I made extensive use of the MARK: comment in _UnblockerController.swift_, although there are not many other comments. If you want to slog through it, I recommend perusing the code in Xcode, making good use of the jump bar, jump to definition, find in project, etc.

The animations in the app are UIView animations. I did it that way because I knew how to do it. UIView animations work just fine, but one of these days I'll learn Core Animation.  Perhaps that would have been the better tool; I don't know.

 ---
The top-level UI element is a tab bar controller with three tabs:

1. The "Unblocker" tab is the default tab.  This is the main program. It invokes UnblockerViewController, which is the primary view controller (over 600 line of code, including comments). 
2. The "Additional stats" tab invokes TextViewController, which presents statistics about the puzzle solution. The text containing the statistics is provided by UnblockerViewController.
3. The "Original image" tab invokes ImageViewControllelr, which presents an image of the _Unblock Me_ screenshot.  The image is provided by UnblockerViewController.

UnblockerViewController, in its ViewDidLoad() method, assigns itself as delegate for the other two view controllers.


[Protocols.swift](Unblocker/Protocols.swift):

~~~ swift
protocol TextProviderDelegate: class {
   var textToShow: String? {get}
}

protocol ImageProviderDelegate: class {
   var imageToShow: UIImage? {get}
}
~~~

<br>

####[UnblockerViewController.swift](Unblocker/UnblockerViewController.swift):

~~~ swift
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
~~~

~~~ swift
class UnblockerViewController: UIViewController, UINavigationControllerDelegate,
   UIImagePickerControllerDelegate, TextProviderDelegate, ImageProviderDelegate
~~~
~~~ swift
   override func viewDidLoad() {
      super.viewDidLoad()
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
~~~

 
 ---

[Contents](#contents)
