#if false && canImport(SwiftUI)
import SwiftUI
import InitializeOnce

@Observable @MainActor
final class BookManager {
  init() {
    print("BookManager initialized")
  }
  
  deinit {
    print("BookManager deinitialized")
  }
  
  var books: [String] = ["SwiftUI Essentials", "Combine Basics"]
  var count = 0
  
  func addBook(_ book: String) {
    books.append(book)
    Task {
      try await Task.sleep(for: .seconds(1))
      await self.addCount()
    }
  }
  
  func addCount() async {
    count = books.count
  }
  
  func removeBook(_ book: String) {
    books.removeAll { $0 == book }
    count = books.count
  }
}

struct ContentView: View {
  @State var count = 0
  var body: some View {
    VStack {
      Button("Count \(count)") {
        count += 1
      }
      
      DetailView()
    }
  }
}

struct DetailView: View {
  @State var bookManager = BookManager()
//  @State var bookManager = InitializeReferenceOnce(BookManager())
  
  func addNewBook() {
    let book = "New Book \(bookManager.books.count + 1)"
    Task {
//      try await bookManager.withUnsafeMutation {
//        $0.addBook(book)
//        try await Task.sleep(for: .seconds(1))
//      }
       bookManager.addBook(book)
    }
  }
  
  func removeLastBook() {
    if let lastBook = bookManager.books.last {
//      bookManager.withMutation {
//        $0.removeBook(lastBook)
//      }
       bookManager.removeBook(lastBook)
    }
  }
  
  var body: some View {
    VStack {
      Text("Books: \(bookManager.count)")
        .font(.headline)
      
      List(bookManager.books, id: \.self) { book in
        Text(book)
      }
      
      Button("Add Book") {
        addNewBook()
      }
      .padding()
      
      Button("Remove Last Book") {
        removeLastBook()
      }
      .padding()
    }
  }
}

#Preview(traits: .sizeThatFitsLayout) {
  ContentView()
}
#endif
