//
//  SearchViewReducerTest.swift
//  GIPHYTests
//
//  Created by Cloud on 2021/09/19.
//

import XCTest
import Combine
@testable import GIPHY

class SearchViewReducerTest: XCTestCase {
    
    private var cancellables: Set<AnyCancellable> = []
    
    func testSearchBarChanged_noEffect() {
        let environment = SearchListViewStore.Environment(
            scheduler: .main,
            presentDetailView: { _, _ in },
            search: { _ in
                return Just(("", Data()))
                    .eraseToAnyPublisher()
            }
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
            presentDetailView: { _, _ in },
            search: { _ in
                return Just(("", Data()))
                    .eraseToAnyPublisher()
            }
        )
        let reducer = SearchListViewStore.Reducer(environment: environment)
        var state = SearchListViewStore.State.empty
        let dummyItem = ("url", Data())
        reducer.reduce(.replaceItems(key: dummyItem.0, data: dummyItem.1), state: &state)
        XCTAssertEqual(state.items.first!.key, dummyItem.0)
        XCTAssertEqual(state.items.first!.data, dummyItem.1)
    }
    
    func testListItemTapped_0Effect() {
        let exp = expectation(description: "Present DetailView")
        let key = "URL"
        let dummyData = Data()
        let presentDetailView: (String, Data) -> Void = { url, data in
            exp.fulfill()
            XCTAssertEqual(url, key)
            XCTAssertEqual(data, dummyData)
        }
        let environment = SearchListViewStore.Environment(
            scheduler: .main,
            presentDetailView: presentDetailView,
            search: { _ in
                return Just(("", Data()))
                    .eraseToAnyPublisher()
            }
        )
        let reducer = SearchListViewStore.Reducer(environment: environment)
        var state = SearchListViewStore.State(query: "", items: [.init(key: key, data: dummyData)])
        reducer.reduce(.listItemTapped(.zero), state: &state)
        wait(for: [exp], timeout: 0.1)
    }
    
    func testSearchButtonTapped_1Effect() {
        let dummyItem: Data = .init()
        let dummyQuery = "Hi"
        let exp = XCTestExpectation(description: "Fire replaceItems action")

        let subject = PassthroughSubject<(String, Data), Never>()
        let searchClosure: (String) -> AnyPublisher<(String, Data), Never> = { query in
            XCTAssertEqual(query, dummyQuery)

            return subject
                .eraseToAnyPublisher()
        }

        let environment = SearchListViewStore.Environment(
            scheduler: .main,
            presentDetailView: { _, _ in },
            search: searchClosure
        )
        let reducer = SearchListViewStore.Reducer(environment: environment)
        var state = SearchListViewStore.State.empty
        state.query = dummyQuery
        reducer.reduce(.searchButtonTapped, state: &state)?
            .sink { action in
                exp.fulfill()
                XCTAssertEqual(action, .replaceItems(key: dummyQuery, data: dummyItem))
            }
            .store(in: &cancellables)

        subject.send((dummyQuery, dummyItem))
        wait(for: [exp], timeout: 0.1)
    }
}

private extension UIImage {
    static var dummy: UIImage? {
        return .init(systemName: "xmark")
    }
}
