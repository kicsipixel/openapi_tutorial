import APIService
import Foundation
import Hummingbird
import OpenAPIHummingbird
import OpenAPIRuntime

struct APIServiceImpl: APIProtocol {
  
    // MARK: - Greetings
  func hello(_: APIService.Operations.hello.Input) async throws -> APIService.Operations.hello.Output {
    .ok(.init(body: .plainText("Hello, World! 🌍")))
  }
  
    // MARK: - Server health
  func healthCheck(_: APIService.Operations.healthCheck.Input) async throws -> APIService.Operations.healthCheck.Output {
    .ok(.init())
  }
}
