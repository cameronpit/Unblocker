//
//  Extensions & generics.swift
//
//  Unblocker
//  Swift 3.1
//
//  Copyright © 2017 Cameron C. Pitcairn.
//  See the file license.txt in the Unblocker project.
//

//******************************************************************************
// MARK: -

extension String {
   func rightAlign(inWidth width:Int) -> String {
      let count = self.characters.count
      let spaces = String(repeating: " ", count: max(width - count, 0))
      return spaces + self
   }
}

//******************************************************************************
// MARK: - Define generic 2-D array

struct Matrix<T> {
   var matrix: Array <T>
   let cols: Int
   let rows: Int
   let defaultElement: T
   init (cols:Int, rows:Int, defaultElement: T) {
      self.cols = cols
      self.rows = rows
      self.defaultElement = defaultElement
      matrix = Array <T>(repeating: defaultElement, count: cols*rows)
   }

   // 2-dimensional
   subscript(x: Int, y:Int) -> T {
      get {
         assert(x<cols && y<rows)
         return matrix[x + y * cols]
      }
      set {
         assert(x<cols && y<rows)
         matrix[x + y * cols] = newValue
      }
   }

   // 1-dimensional
   subscript(x:Int) -> T {
      get {return matrix[x]}
      set {matrix[x] = newValue}
   }

   mutating func reset() {
      matrix = Array <T>(repeating: defaultElement, count: cols*rows)
   }
}

//******************************************************************************
//  MARK: - Define generic queue
//
//  Adapted from Ryan Huebert's answer on
//  http://stackoverflow.com/questions/29567711

class QNode<T> {
   var value: T
   var next: QNode?

   init(item:T) {
      value = item
   }
}

struct Queue<T> {
   private var top: QNode<T>!
   private var bottom: QNode<T>!
   var size = 0

   mutating func enQueue(_ item: T) {

      let newNode:QNode<T> = QNode(item: item)
      size += 1
      if top == nil {
         top = newNode
         bottom = top
         return
      }

      bottom.next = newNode
      bottom = newNode
   }

   mutating func deQueue() -> T? {

      let topItem: T? = top?.value
      if topItem == nil {
         return nil
      }
      size -= 1
      if let nextItem = top.next {
         top = nextItem
      } else {
         top = nil
         bottom = nil
      }

      return topItem
   }

   var isEmpty: Bool {
      return top == nil
   }

   func peek() -> T? {
      return top?.value
   }

   mutating func clearQueue() {
      top = nil
      bottom = nil
      size = 0
   }
}

