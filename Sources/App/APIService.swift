import APIService
import Foundation
import Hummingbird
import OpenAPIHummingbird
import OpenAPIRuntime
import PostgresNIO

struct APIServiceImpl: APIProtocol {
  let client: PostgresClient

  // MARK: - Greetings
  func hello(_: APIService.Operations.hello.Input) async throws -> APIService.Operations.hello.Output {
    .ok(.init(body: .plainText("Hello, World! 🌍")))
  }

  // MARK: - Server health
  func healthCheck(_: APIService.Operations.healthCheck.Input) async throws
    -> APIService.Operations.healthCheck.Output {
    .ok(.init())
  }

  // MARK: - Create
  func createPerson(_ input: APIService.Operations.createPerson.Input) async throws
    -> APIService.Operations.createPerson.Output {
    let id = UUID()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"

    guard case .json(let person) = input.body,
          let numberOfPublications = person.number_of_publications,
          let name = person.name,
          let firstName = name.first_name,
          let lastName = name.last_name,
          let dateOfBirth = person.date_of_birth,
          let isActive = person.is_active
    else {
      return .badRequest(.init())
    }

    try await client.query(
      """
      INSERT INTO openapi_tutorial (
        id,
        number_of_publications,
        first_name,
        last_name,
        date_of_birth,
        is_active
      )
      VALUES (
        \(id),
        \(numberOfPublications),
        \(firstName),
        \(lastName),
        \(dateFormatter.date(from: dateOfBirth)),
        \(isActive)
      )
      """
    )

    return .created(.init())
  }

  // MARK: - List
  func listPeople(_: APIService.Operations.listPeople.Input) async throws
    -> APIService.Operations.listPeople.Output {
    var people = [Components.Schemas.Person]()

    let stream = try await client.query(
      """
      SELECT
        id,
        number_of_publications,
        first_name,
        last_name,
        date_of_birth,
        is_active
      FROM
        openapi_tutorial
      """
    )

      for try await (id, number_of_publications, first_name, last_name, date_of_birth, is_active) in stream.decode((String, Int, String, String, Date, Bool).self) {
      people.append(
        .init(
          id: id,
          number_of_publications: number_of_publications,
          name: .init(first_name: first_name, last_name: last_name),
          date_of_birth: "\(date_of_birth)",
          is_active: is_active))
    }

    return .ok(.init(body: .json(people)))
  }
  
  // MARK: - Show
  func getPersonById(_ input: APIService.Operations.getPersonById.Input) async throws -> APIService.Operations.getPersonById.Output {
    let id = input.path.id
    
    print(id)
    
    let stream = try await client.query(
      """
      SELECT
        id,
        number_of_publications,
        first_name,
        last_name,
        date_of_birth,
        is_active
      FROM
        openapi_tutorial
      WHERE id = id
      """
    )
    
    for try await (id, number_of_publications, first_name, last_name, date_of_birth, is_active) in stream.decode((String, Int, String, String, Date, Bool).self) {
      return .ok(.init(body: .json(Components.Schemas.Person(id: id, number_of_publications: number_of_publications, name: .init(first_name: first_name, last_name: last_name), date_of_birth: "\(date_of_birth)", is_active: is_active))))
    }
    
    return .notFound(.init())
  }
}
