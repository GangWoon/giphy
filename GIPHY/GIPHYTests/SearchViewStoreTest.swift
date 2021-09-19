//
//  SearchViewStoreTest.swift
//  GIPHYTests
//
//  Created by Cloud on 2021/09/19.
//

import XCTest
import Combine
@testable import GIPHY

class SearchViewStoreTest: XCTestCase {
    
    private var cancellables: Set<AnyCancellable> = []

    func testSearchBarChanged_noEffect() {
        let environment = SearchListViewStore.Environment(
            scheduler: .main,
            search: { _ in return Just([]).eraseToAnyPublisher() }
        )
        let reducer = SearchListViewStore.Reducer(environment: environment)
        var state = SearchListViewStore.State.empty
        let query = "Hello"
        reducer.reduce(.searchBarChanged(query), state: &state)
        XCTAssertEqual(state.query, query)
    }
    
    func testReplaceItems_noEffect() {
        let environment = SearchListViewStore.Environment(
            scheduler: .main,
            search: { _ in return Just([]).eraseToAnyPublisher() }
        )
        let reducer = SearchListViewStore.Reducer(environment: environment)
        var state = SearchListViewStore.State.empty
        let items: [URL] = [.dummy, .dummy, .dummy]
        reducer.reduce(.replaceItems(items), state: &state)
        XCTAssertEqual(state.items, items)
    }
    
    func testSearchButtonTapped_1Effect() {
        let dummyItems: [URL] = [.dummy, .dummy]
        let dummyQuery = "Hi"
        let exp = XCTestExpectation(description: "Fire replaceItems action")
        
        let subject = PassthroughSubject<[URL], Never>()
        let searchClosure: (String) -> AnyPublisher<[URL], Never> = { query in
            XCTAssertEqual(query, dummyQuery)
            return subject.eraseToAnyPublisher()
        }
        
        let environment = SearchListViewStore.Environment(
            scheduler: .main,
            search: searchClosure
        )
        let reducer = SearchListViewStore.Reducer(environment: environment)
        var state = SearchListViewStore.State.empty
        state.query = dummyQuery
        reducer.reduce(.searchButtonTapped, state: &state)?
            .sink { action in
                exp.fulfill()
                XCTAssertEqual(action, .replaceItems(dummyItems))
            }
            .store(in: &cancellables)
        
        subject.send(dummyItems)
        wait(for: [exp], timeout: 0.1)
    }
}

private extension URL {
    static var dummy: Self {
        return URL(string: "Test")!
    }
}
