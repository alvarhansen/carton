// Copyright 2020 Carton contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import CartonHelpers
#if canImport(Combine)
import Combine
#else
import OpenCombine
#endif
import SwiftToolchain
import TSCBasic
import Vapor

private enum Event {
  enum CodingKeys: String, CodingKey {
    case kind
    case stackTrace
    case testOutput
  }

  enum Kind: String, Decodable {
    case stackTrace
  }

  case stackTrace(String)
  case testOutput(String)
}

extension Event: Decodable {
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    let kind = try container.decode(Kind.self, forKey: .kind)

    switch kind {
    case .stackTrace:
      let rawStackTrace = try container.decode(String.self, forKey: .stackTrace)
      self = .stackTrace(rawStackTrace)
    }
  }
}

/// This `Hashable` conformance is required to handle simulatenous connections with `Set<WebSocket>`
extension WebSocket: Hashable {
  public static func == (lhs: WebSocket, rhs: WebSocket) -> Bool {
    lhs === rhs
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }
}

final class Server {
  private let decoder = JSONDecoder()
  private var connections = Set<WebSocket>()
  private var subscriptions = [AnyCancellable]()
  private let watcher: Watcher
  private let app: Application
  private let localURL: String
  private let skipAutoOpen: Bool

  init(
    builder: Builder,
    pathsToWatch: [AbsolutePath],
    customIndexContent: String?,
    package: SwiftToolchain.Package,
    verbose: Bool,
    skipAutoOpen: Bool,
    _ terminal: InteractiveWriter,
    port: Int
  ) throws {
    watcher = try Watcher(pathsToWatch)

    var env = Environment(name: verbose ? "development" : "production", arguments: ["vapor"])
    localURL = "http://0.0.0.0:\(port)/"
    self.skipAutoOpen = skipAutoOpen

    try LoggingSystem.bootstrap(from: &env)
    app = Application(env)
    app.configure(
      port: port,
      mainWasmPath: builder.mainWasmPath,
      customIndexContent: customIndexContent,
      package: package,
      onWebSocketOpen: { [weak self] ws, environment in
        ws.onText { _, text in
          guard
            let data = text.data(using: .utf8),
            let event = try? self?.decoder.decode(Event.self, from: data)
          else {
            return
          }

          switch event {
          case let .stackTrace(rawStackTrace):
            guard environment == .firefox else { break }

            let stackTrace = rawStackTrace.firefoxStackTrace

            terminal.write("\nAn error occurred, here's a stack trace for it:\n", inColor: .red)
            stackTrace.forEach { item in
              terminal.write("  \(item.symbol)", inColor: .cyan)
              terminal.write(" at \(item.location)\n")
            }
          case let .testOutput(output):
            terminal.write(output)
          }
        }
        self?.connections.insert(ws)
      },
      onWebSocketClose: { [weak self] in
        self?.connections.remove($0)
      }
    )
    // Listen to Vapor App lifecycle events
    app.lifecycle.use(self)

    watcher.publisher
      .flatMap(maxPublishers: .max(1)) { changes -> AnyPublisher<String, Never> in
        if !verbose {
          terminal.clearWindow()
        }
        terminal.write("\nThese paths have changed, rebuilding...\n", inColor: .yellow)
        for change in changes.map(\.pathString) {
          terminal.write("- \(change)\n", inColor: .cyan)
        }
        return builder
          .run()
          .handleEvents(receiveCompletion: { [weak self] in
            guard case .finished = $0, let self = self else { return }

            terminal.write("\nBuild completed successfully\n", inColor: .green, bold: false)
            terminal.logLookup("The app is currently hosted at ", self.localURL)
            self.connections.forEach { $0.send("reload") }
          })
          .catch { _ in Empty().eraseToAnyPublisher() }
          .eraseToAnyPublisher()
      }
      .sink(receiveValue: { _ in })
      .store(in: &subscriptions)
  }

  /// Blocking function that starts the HTTP server
  func run() throws {
    defer { app.shutdown() }
    try app.run()
    for conn in connections {
      try conn.close().wait()
    }
  }
}

extension Server: LifecycleHandler {
  public func didBoot(_ application: Application) throws {
    guard !skipAutoOpen else { return }
    openInSystemBrowser(url: localURL)
  }

  /// Attempts to open the specified URL string in system browser on macOS and Linux.
  /// - Returns: true if launching command returns successfully.
  @discardableResult
  private func openInSystemBrowser(url: String) -> Bool {
    #if os(macOS)
    let openCommand = "open"
    #elseif os(Linux)
    let openCommand = "xdg-open"
    #else
    return false
    #endif
    let process = Process(
      arguments: [openCommand, url],
      outputRedirection: .none,
      verbose: false,
      startNewProcessGroup: true
    )
    do {
      try process.launch()
      return true
    } catch {
      return false
    }
  }
}
