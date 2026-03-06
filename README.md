# NetworkKit

**NetworkKit** is a lightweight, modular, and testable network layer built using `Combine` and clean architecture principles.
It helps you decouple API logic from UI, enforce consistency, and write better unit tests.

---

## 🔧 Features

- ✅ Combine-based `AnyPublisher` interface
- ✅ Built-in error handling (`NetworkError`)
- ✅ Supports both wrapped and plain JSON responses
- ✅ Easily mockable via `NetworkSessionInterface`
- ✅ Clean and extensible architecture
- ✅ Designed for modular feature-based project structures

---

## 📦 Installation

You can add `NetworkKit` to your project as a **local Swift Package**:

1. Open your Xcode project
2. Go to **File > Add Packages...**
3. Click **Add Local...**
4. Select the folder containing the `Package.swift` file of NetworkKit

> ℹ️ This setup is ideal during development when `NetworkKit` is part of the same repository or under active local iteration.

---

Alternatively, to integrate it via a remote Git repository:

```swift
dependencies: [
    .package(url: "https://github.com/NetworkKit.git", from: "1.0.0")
]
```

Import the module where needed:

```swift
import NetworkKit
```

---

## 🚀 Quick Start

### 1. Define Your Request

```swift
struct HomeRequest: BaseRequest {
    var baseURL: String = "dummyjson.com"
    var path: String = "recipes"
}
```

### 2. Call It Using `NetworkManager`

```swift
NetworkManager.shared.execute(HomeRequest(), model: Recipes.self)
    .sink(
        receiveCompletion: { completion in
            if case .failure(let error) = completion {
                print("Error: \(error)")
            }
        },
        receiveValue: { data in
            print("Data: \(data)")
        }
    )
    .store(in: &cancellables)
```

---

## 🧱 Architecture

| Component | Description |
|-----------|-------------|
| `BaseRequest` | Protocol to define request components |
| `NetworkManager` | Singleton class that performs network calls |
| `NetworkSessionInterface` | Protocol to allow dependency injection for testing |
| `NetworkError` | Enum for decoding and response errors |
| `BaseResponse<T>` | Optional response wrapper that unpacks `data` |

---

## 🧪 Testing & Mocking

To mock networking in unit tests, conform to `NetworkSessionInterface`:

```swift
class MockNetworkSession: NetworkSessionInterface {
    func execute<T>(_ request: BaseRequest, model: T.Type) -> AnyPublisher<T, NetworkError> where T : Decodable {
        let mock = T(...) // Construct mock response
        return Just(mock)
            .setFailureType(to: NetworkError.self)
            .eraseToAnyPublisher()
    }
}
```

---

## 📝 Documentation

This package includes full symbol-level documentation.
To view it in Xcode:

1. Open the Swift package in Xcode
2. Select any target
3. Go to **Product > Build Documentation**

Or hold **⌥ Option** and click any symbol to view inline documentation.

---

## 📱 Requirements

- iOS 15+
- Swift 5.5+
- Combine

---
