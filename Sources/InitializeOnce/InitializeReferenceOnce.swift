import Foundation

/**
 # InitializeReferenceOnce

 A wrapper class for initializing reference type objects only once in SwiftUI.

 ## Background Problem

 In SwiftUI Views, the `body` property is re-evaluated every time the parent View's state changes,
 and the initializers of the View's stored properties are also re-executed during this process.

 ```swift
 struct ParentView: View {
     @State var counter = 0

     var body: some View {
         VStack {
             Button("Count: \(counter)") { counter += 1 }
             ChildView() // ChildView is re-initialized every time counter changes
         }
     }
 }

 struct ChildView: View {
     @State var manager = ExpensiveManager() // New instances are created every time counter changes

     var body: some View {
         Text("Data: \(manager.data)")
     }
 }
 ```

 In this example, every time `ParentView`'s `counter` changes:
 1. `ChildView`'s body is re-evaluated
 2. `ExpensiveManager()` is newly created
 3. SwiftUI's `@State` keeps only the first instance and immediately deinitializes new ones
 4. Performance degrades due to unnecessary object creation

 ## StateObject's Mechanism and the Role of autoclosure

 `@StateObject` internally uses `@autoclosure` to solve this problem:
 - `@autoclosure` enables lazy evaluation of initializers as closures
 - The actual object is created only on first access
 - Existing instances are reused in subsequent re-evaluations

 ## This Class's Solution

 `InitializeReferenceOnce` provides a similar mechanism to `@StateObject` but
 allows for more flexible operations:
 - Transparent property access through `@dynamicMemberLookup`
 - Safe mutation operations via `withMutation` and `withUnsafeMutation`
 - Support for any reference type objects

 ## Usage Example

 ```swift
 struct DetailView: View {
     @State var bookManager = InitializeReferenceOnce(BookManager())

     var body: some View {
         VStack {
             Text("Books: \(bookManager.count)") // Transparent property access

             Button("Add Book") {
                 bookManager.withMutation { manager in
                     manager.addBook("New Book")
                 }
             }
         }
     }
 }
 ```

 ## Notes

 While Apple recommends using `.task()` for asynchronous initialization,
 this approach is effective when synchronous initialization is needed,
 as `.task()` does not execute synchronously at the very beginning of view appearance.

 - Reference: [Apple Developer Documentation - State](https://developer.apple.com/documentation/swiftui/state#Store-observable-objects)
 */
@dynamicMemberLookup
public final class InitializeReferenceOnce<Value: AnyObject> {
  /**
   * The actual instance of the lazily evaluated object
   *
   * With the `lazy` keyword, the `_value()` closure is executed when first accessed,
   * and the object is initialized. Subsequent accesses return the same instance.
   */
  private lazy var value: Value = _value()

  /**
   * The closure that initializes the object
   *
   * The initializer passed via `@autoclosure` is stored as a closure,
   * and its execution is deferred until actually needed.
   */
  private let _value: () -> Value

  /**
   * Initializer that performs lazy initialization
   *
   * - Parameter value: The object to be initialized. Actual execution is deferred by `@autoclosure`
   *
   * Using `@autoclosure` enables calls like the following:
   * ```swift
   * let wrapper = InitializeReferenceOnce(ExpensiveObject())
   * ```
   *
   * At this point, `ExpensiveObject()` is not executed, and initialization
   * occurs only when the object is actually accessed for the first time.
   */
  public init(_ value: @autoclosure @escaping () -> Value) {
    _value = value
  }

  /**
   * Transparent property access through dynamic member lookup
   *
   * - Parameter keyPath: The key path to the property to access
   * - Returns: The value of the property
   *
   * This subscript enables direct access to the wrapped object's properties:
   *
   * ```swift
   * let wrapper = InitializeReferenceOnce(BookManager())
   * let count = wrapper.count // Direct access to BookManager.count
   * wrapper.books = newBooks  // Setting is also possible
   * ```
   *
   * Both reading and writing are supported, allowing transparent manipulation
   * of the wrapped object's properties.
   */
  public subscript<T>(dynamicMember keyPath: ReferenceWritableKeyPath<Value, T>) -> T {
    get { value[keyPath: keyPath] }
    set { value[keyPath: keyPath] = newValue }
  }

  /**
   * Method for safely executing synchronous mutation operations
   *
   * - Parameter mutate: A closure that receives the object and performs mutation operations
   * - Returns: The return value of the closure
   * - Throws: Re-throws any exceptions thrown by the closure
   *
   * Using this method, you can safely execute multiple operations
   * on the wrapped object together:
   *
   * ```swift
   * wrapper.withMutation { manager in
   *     manager.addBook("Book 1")
   *     manager.addBook("Book 2")
   *     manager.sortBooks()
   * }
   * ```
   *
   * It also supports operations with return values:
   * ```swift
   * let result = wrapper.withMutation { manager in
   *     return manager.processBooks()
   * }
   * ```
   */
  @discardableResult
  public func withMutation<T>(_ mutate: (Value) throws -> T) rethrows -> T {
    return try mutate(value)
  }

  /**
   * Method for executing asynchronous mutation operations (Actor isolation support)
   *
   * - Parameter isolation: Actor isolation context (defaults to current isolation state)
   * - Parameter mutate: A closure that receives the object and performs asynchronous mutation operations
   * - Returns: The return value of the closure
   * - Throws: Re-throws any exceptions thrown by the closure
   *
   * This method is used to safely execute asynchronous operations in Actor-isolated environments.
   * It uses `nonisolated(unsafe)` to temporarily bypass Actor isolation and access the object.
   *
   * ```swift
   * await wrapper.withUnsafeMutation { manager in
   *     await manager.loadDataFromNetwork()
   *     await manager.processAsyncData()
   * }
   * ```
   *
   * **Warning**: As the name suggests with "unsafe", this method
   * temporarily bypasses Actor isolation safety. When using this method,
   * design carefully to avoid synchronous data races.
   *
   * Primary use cases:
   * - Asynchronous operations on objects isolated with `@MainActor`
   * - Long-running processes involving network communication or file I/O
   * - Sequential execution of multiple asynchronous operations
   */
  @discardableResult
  public func withUnsafeMutation<T: Sendable>(_ isolation: isolated (any Actor)? = #isolation, _ mutate: (Value) async throws -> T) async rethrows -> T {
    nonisolated(unsafe) let currentValue = value
    return try await mutate(currentValue)
  }
}
