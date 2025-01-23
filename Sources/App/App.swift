import ArgumentParser
import Foundation
import Hummingbird
import Logging
import OpenAPIHummingbird
import OpenAPIRuntime
import PostgresNIO

@main
struct AppCommand: AsyncParsableCommand {
  @Option(name: .shortAndLong)
  var hostname: String = "127.0.0.1"

  @Option(name: .shortAndLong)
  var port: Int = 8080

  func run() async throws {
    let router = Router()
    router.middlewares.add(LogRequestsMiddleware(.info))

    var logger = Logger(label: "openapi_tutorial")
    logger.logLevel = .debug

    let env = try await Environment.dotEnv()
      // env.get("DATABASE_HOST") ??
    let client = PostgresClient(configuration: .init(host:  "localhost",
                                                     username: env.get("DATABASE_USERNAME") ?? "hb_usernam3",
                                                     password: env.get("DATABASE_PASSWORD") ?? "s3cr3t",
                                                     database: env.get("DATABASE_NAME") ?? "openapi_tutorial",
                                                     tls: .disable))

    let api = APIServiceImpl(client: client)
    try api.registerHandlers(on: router)

    let app = Application(
      router: router,
      configuration: .init(address: .hostname(hostname, port: port))
    )

    try await withThrowingDiscardingTaskGroup { group in
      group.addTask {
        await client.run()
      }

      group.addTask {
        try await app.runService()
      }

      try await client.query(
                  """
                  CREATE TABLE IF NOT EXISTS openapi_tutorial (
                    "id" UUID PRIMARY KEY,
                    "number_of_publications" INT,
                    "first_name" TEXT,
                    "last_name" TEXT,
                    "date_of_birth" DATE,
                    "is_active" BOOLEAN
                  )
                  """
      )
    }
  }
}
