# InitializeOnce

A Swift package that provides efficient lazy initialization for reference type objects in SwiftUI, solving the performance issues caused by repeated object creation during view re-evaluation.

## 🚀 Features

- **Lazy Initialization**: Objects are created only when first accessed, not during every view re-evaluation
- **Transparent Access**: Direct property access through `@dynamicMemberLookup` without wrapper syntax
- **Safe Mutations**: Structured mutation operations with `withMutation` and `withUnsafeMutation`
- **Actor Support**: Full support for `@MainActor` isolated objects and async operations
- **SwiftUI Integration**: Drop-in replacement for `@State` with reference types

## 📋 Requirements

- iOS 17.0+ / macOS 14.0+ / tvOS 17.0+ / watchOS 10.0+
- Swift 6.0+
- Xcode 16.0+

## 📦 Installation

### Swift Package Manager

Add `InitializeOnce` to your project using Xcode's Package Manager:

```
https://github.com/arasan01/InitializeOnce
```

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/arasan01/InitializeOnce", from: "0.1.0")
]
```

## 🎯 Problem & Solution

### The Problem

In SwiftUI, when a parent view's state changes, all child views are re-evaluated, causing stored properties to be re-initialized:

```swift
struct ParentView: View {
    @State var counter = 0

    var body: some View {
        VStack {
            Button("Count: \(counter)") { counter += 1 }
            ChildView() // Re-creates ChildView every time counter changes
        }
    }
}

struct ChildView: View {
    @State var manager = ExpensiveManager() // 🚨 New instance created on every re-evaluation!

    var body: some View {
        Text("Data: \(manager.data)")
    }
}
```

**Issues:**
1. `ExpensiveManager()` is created repeatedly
2. Only the first instance is kept by `@State`, others are immediately deallocated
3. Unnecessary object creation degrades performance
4. Expensive initialization logic runs multiple times

### The Solution

`InitializeReferenceOnce` uses the same `@autoclosure` technique as `@StateObject` to defer initialization:

```swift
struct ChildView: View {
    @State var manager = InitializeReferenceOnce(ExpensiveManager()) // ✅ Created only once!

    var body: some View {
        Text("Data: \(manager.data)") // Transparent property access
    }
}
```

## 🔧 Usage

### Basic Usage

```swift
import SwiftUI
import InitializeOnce

@Observable @MainActor
class BookManager {
    var books: [String] = []
    var count: Int { books.count }

    func addBook(_ title: String) {
        books.append(title)
    }

    func removeBook(_ title: String) {
        books.removeAll { $0 == title }
    }
}

struct BookListView: View {
    @State var bookManager = InitializeReferenceOnce(BookManager())

    var body: some View {
        VStack {
            Text("Books: \(bookManager.count)") // Direct property access

            List(bookManager.books, id: \.self) { book in
                Text(book)
            }

            Button("Add Book") {
                bookManager.addBook("New Book") // Direct method calls
            }
        }
    }
}
```

### Structured Mutations

For complex operations, use `withMutation` to group multiple changes:

```swift
Button("Add Multiple Books") {
    bookManager.withMutation { manager in
        manager.addBook("Swift Essentials")
        manager.addBook("SwiftUI Guide")
        manager.sortBooks()
    }
}
```

### Async Operations

For async operations with `@MainActor` objects, use `withUnsafeMutation`:

```swift
Button("Load Books") {
    Task {
        await bookManager.withUnsafeMutation { manager in
            let books = await NetworkService.fetchBooks()
            manager.books = books
            await manager.processBooks()
        }
    }
}
```

### Actor Safety

The `withUnsafeMutation` method temporarily bypasses Actor isolation using `nonisolated(unsafe)`. Use it carefully to avoid data races:

```swift
// ✅ Safe: Sequential operations
await manager.withUnsafeMutation { manager in
    await manager.loadData()
    await manager.processData()
}

// ⚠️ Potentially unsafe: Concurrent access
Task {
    await manager.withUnsafeMutation { $0.updateData() }
}
Task {
    await manager.withUnsafeMutation { $0.updateData() } // Potential race condition
}
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
