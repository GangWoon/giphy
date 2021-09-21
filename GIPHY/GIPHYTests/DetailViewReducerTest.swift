//
//  DetailViewReducerTest.swift
//  GIPHYTests
//
//  Created by Cloud on 2021/09/22.
//

import XCTest
@testable import GIPHY

class DetailViewReducerTest: XCTestCase {
    
    func testInitialData_noEffect() {
        var state = DetailViewStore.State(image: nil, isFavorites: false)
        let dummyFavorites = true
        let isFavoritesClosure: () -> Bool = {
            return dummyFavorites
        }
        let environment = DetailViewStore.Environment(
            scheduler: .main,
            isFavorites: isFavoritesClosure,
            toggleFavorites: { _ in fatalError("Should not be called") }
        )
        let reducer = DetailViewStore.Reducer(environment: environment)
        reducer.reduce(.initialData, state: &state)
        XCTAssertEqual(state.isFavorites, dummyFavorites)
    }
    
    func testFavoritesButtonTapped_noEffect() {
        let dummyFavorites = true
        var state = DetailViewStore.State(image: nil, isFavorites: dummyFavorites)
        let exp = expectation(description: "Toggle Favorites")
        let toggleFavoritesClosure: (Bool) -> Void = { _ in
            exp.fulfill()
        }
        let environment = DetailViewStore.Environment(
            scheduler: .main,
            isFavorites: { fatalError("should not be called") },
            toggleFavorites: toggleFavoritesClosure
        )
        let reducer = DetailViewStore.Reducer(environment: environment)
        reducer.reduce(.favoritesButtonTapped, state: &state)
        XCTAssertEqual(state.isFavorites, !dummyFavorites)
        wait(for: [exp], timeout: 0.1)
    }
}
