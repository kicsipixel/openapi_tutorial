import APIService
import Foundation
import Hummingbird
import OpenAPIHummingbird
import OpenAPIRuntime

struct APIServiceImpl: APIProtocol {
  
  func hello(_: APIService.Operations.hello.Input) async throws -> APIService.Operations.hello.Output {
    .ok(.init(body: .plainText("Hello, World! 🌍")))
  }
}
