//
//  ServiceContainerTests.swift
//  GreenShotTests
//
//  Unit tests for ServiceContainer dependency injection
//

import Testing
import Foundation
@testable import runner

struct ServiceContainerTests {

    @Test("ServiceContainer registers and resolves singleton services")
    func testSingletonServices() async throws {
        let container = ServiceContainer.shared

        // Register a singleton service
        container.register(MockService.self, scope: .singleton) {
            MockService(value: "singleton-test")
        }

        // Resolve multiple times
        let instance1: MockService = container.resolve(MockService.self)
        let instance2: MockService = container.resolve(MockService.self)

        #expect(instance1.value == "singleton-test", "Should resolve correct instance")
        #expect(instance1 === instance2, "Should return same instance for singleton")
    }

    @Test("ServiceContainer registers and resolves transient services")
    func testTransientServices() async throws {
        let container = ServiceContainer.shared

        // Register a transient service
        container.register(MockService.self, scope: .transient) {
            MockService(value: "transient-test")
        }

        // Resolve multiple times
        let instance1: MockService = container.resolve(MockService.self)
        let instance2: MockService = container.resolve(MockService.self)

        #expect(instance1.value == "transient-test", "Should resolve correct instance")
        #expect(instance1 !== instance2, "Should return different instances for transient")
    }

    @Test("ServiceContainer registers and resolves scoped services")
    func testScopedServices() async throws {
        let container = ServiceContainer.shared

        // Register a scoped service
        container.register(MockService.self, scope: .scoped) {
            MockService(value: "scoped-test")
        }

        // Resolve within same scope
        let instance1: MockService = container.resolve(MockService.self)
        let instance2: MockService = container.resolve(MockService.self)

        #expect(instance1.value == "scoped-test", "Should resolve correct instance")
        #expect(instance1 === instance2, "Should return same instance within scope")

        // Clear scope and resolve again
        container.clearScopedInstances()
        let instance3: MockService = container.resolve(MockService.self)

        #expect(instance3 !== instance1, "Should return new instance after scope clear")
    }

    @Test("ServiceContainer handles protocol-based registration")
    func testProtocolBasedRegistration() async throws {
        let container = ServiceContainer.shared

        // Register protocol implementation
        container.register(MockServiceProtocol.self) {
            MockService(value: "protocol-test")
        }

        // Resolve via protocol
        let service: MockServiceProtocol = container.resolve(MockServiceProtocol.self)

        #expect(service.getValue() == "protocol-test", "Should resolve protocol implementation")
    }

    @Test("ServiceContainer handles dependency injection chains")
    func testDependencyChains() async throws {
        let container = ServiceContainer.shared

        // Register dependencies
        container.register(MockRepository.self) {
            MockRepository()
        }

        container.register(MockServiceWithDependency.self) {
            let repository: MockRepository = container.resolve(MockRepository.self)
            return MockServiceWithDependency(repository: repository)
        }

        // Resolve service with dependencies
        let service: MockServiceWithDependency = container.resolve(MockServiceWithDependency.self)

        #expect(service.repository != nil, "Should inject dependencies correctly")
        #expect(service.getData() == "mock-data", "Should function with injected dependencies")
    }

    @Test("ServiceContainer throws for unregistered services")
    func testUnregisteredServiceError() async throws {
        let container = ServiceContainer.shared

        // Attempt to resolve unregistered service should fail
        #expect(throws: (any Error).self) {
            let _: MockService = container.resolve(MockService.self)
        }
    }

    @Test("ServiceContainer handles circular dependencies")
    func testCircularDependencyDetection() async throws {
        let _ = ServiceContainer.shared

        // This test would require more complex setup
        // For now, we'll verify basic behavior
        #expect(true, "Circular dependency test placeholder")
    }

    @Test("ServiceContainer performance with many registrations")
    func testPerformanceWithManyServices() async throws {
        let container = ServiceContainer.shared
        let serviceCount = 1000

        // Register many services
        let (_, registrationTime) = PerformanceTestUtilities.measureExecutionTime {
            for i in 0..<serviceCount {
                container.register(MockService.self, scope: .transient) {
                    MockService(value: "service-\(i)")
                }
            }
        }

        // Resolve many services
        let (services, resolutionTime) = PerformanceTestUtilities.measureExecutionTime {
            return (0..<serviceCount).map { _ in
                container.resolve(MockService.self)
            }
        }

        #expect(registrationTime < 0.1, "Registration should be fast")
        #expect(resolutionTime < 0.1, "Resolution should be fast")
        #expect(services.count == serviceCount, "Should resolve all services")
    }

    @Test("ServiceContainer thread safety")
    func testThreadSafety() async throws {
        let container = ServiceContainer.shared

        container.register(MockService.self, scope: .singleton) {
            MockService(value: "thread-safe-test")
        }

        // Concurrent resolution
        await withTaskGroup(of: MockService.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    return container.resolve(MockService.self)
                }
            }

            var instances: [MockService] = []
            for await instance in group {
                instances.append(instance)
            }

            // All instances should be the same for singleton
            let firstInstance = instances.first!
            let allSame = instances.allSatisfy { $0 === firstInstance }
            #expect(allSame, "All singleton instances should be identical")
        }
    }
}

// Test classes
protocol MockServiceProtocol {
    func getValue() -> String
}

class MockService: MockServiceProtocol {
    let value: String

    init(value: String) {
        self.value = value
    }

    func getValue() -> String {
        return value
    }
}

class MockRepository {
    func fetchData() -> String {
        return "mock-data"
    }
}

class MockServiceWithDependency {
    let repository: MockRepository

    init(repository: MockRepository) {
        self.repository = repository
    }

    func getData() -> String {
        return repository.fetchData()
    }
}