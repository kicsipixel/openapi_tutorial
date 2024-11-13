import ArgumentParser
import Foundation
import Hummingbird
import Logging
import OpenAPIHummingbird
import OpenAPIRuntime

@main
struct AppCommand: AsyncParsableCommand {
  @Option(name: .shortAndLong)
  var hostname: String = "127.0.0.1"
  
  @Option(name: .shortAndLong)
  var port: Int = 8080
  
  @Option(name: .shortAndLong)
  var logLevel: Logger.Level?
  
  func run() async throws {
    let router = Router()
    router.middlewares.add(LogRequestsMiddleware(.info))
    let api = APIServiceImpl()
    
    try api.registerHandlers(on: router)
    
    let app = Application(
      router: router,
      configuration: .init(address: .hostname(hostname, port: port))
    )
    
    try await app.runService()
  }
}

  /// Extend `Logger.Level` so it can be used as an argument
#if hasFeature(RetroactiveAttribute)
extension Logger.Level: @retroactive ExpressibleByArgument {}
#else
extension Logger.Level: ExpressibleByArgument {}
#endif
