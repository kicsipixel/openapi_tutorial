import APIService
import Foundation
import Hummingbird
import OpenAPIHummingbird
import OpenAPIRuntime
import PostgresNIO

struct APIServiceImpl: APIProtocol {
    let client: PostgresClient
    
    // A shared DateFormatter instance
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
    
    
    // MARK: - Greetings
    func hello(_: APIService.Operations.hello.Input) async throws -> APIService.Operations.hello.Output {
        .ok(.init(body: .plainText("Hello, World! 🌍")))
    }
    
    // MARK: - Server health
    func healthCheck(_: APIService.Operations.healthCheck.Input) async throws -> APIService.Operations.healthCheck.Output {
        .ok(.init())
    }
    
    // MARK: - Create
    func createPerson(_ input: APIService.Operations.createPerson.Input) async throws -> APIService.Operations.createPerson.Output {
        let id = UUID()
        
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
        \(APIServiceImpl.dateFormatter.date(from: dateOfBirth)),
        \(isActive)
      )
      """
        )
        
        return .created(.init())
    }
    
    // MARK: - List
    func listPeople(_: APIService.Operations.listPeople.Input) async throws -> APIService.Operations.listPeople.Output {
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
        let guid = UUID(uuidString: input.path.id)
        
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
            WHERE id = \(guid)
            """
        )
        
        for try await (id, number_of_publications, first_name, last_name, date_of_birth, is_active) in stream.decode((String, Int, String, String, Date, Bool).self) {
            return .ok(.init(body: .json(Components.Schemas.Person(id: id, number_of_publications: number_of_publications, name: .init(first_name: first_name, last_name: last_name), date_of_birth: "\(date_of_birth)", is_active: is_active))))
        }
        
        return .notFound(.init())
    }
    
    func updatePersonById(_ input: APIService.Operations.updatePersonById.Input) async throws -> APIService.Operations.updatePersonById.Output {
        let guid = UUID(uuidString: input.path.id)
        
        guard case .json(let person) = input.body,
              let name = person.name,
              let firstName = name.first_name,
              let lastName = name.last_name,
              let numberOfPubications = person.number_of_publications,
              let dateOfBirth = person.date_of_birth,
              let isActive = person.is_active
        else {
            return .badRequest(.init())
        }
        
        let query: PostgresQuery =
                            """
                            UPDATE openapi_tutorial
                            SET number_of_publications = \(numberOfPubications),
                                first_name = \(firstName),
                                last_name = \(lastName),
                                date_of_birth = \(APIServiceImpl.dateFormatter.date(from: dateOfBirth)),
                                is_active = \(isActive)
                            WHERE id = \(guid)
                            """
        
        print("\(APIServiceImpl.dateFormatter.date(from: dateOfBirth))")
        try await self.client.query(query)
        
        return .ok(.init())
    }
}
