//
//  SearchListViewStore.swift
//  GIPHY
//
//  Created by Cloud on 2021/09/19.
//

import UIKit
import Combine

final class SearchListViewStore {
    
    // MARK: - State
    struct State: Equatable {
        static var empty = Self(query: "", items: [])
        var query: String
        var items: [URL]
    }
    
    // MARK: - Environment
    struct Environment {
        let scheduler: DispatchQueue
        let search: (String) -> AnyPublisher<[URL], Never>
    }
    
    // MARK: - Reducer
    struct Reducer {
        
        private let environment: Environment
        
        init(environment: Environment) {
            self.environment = environment
        }
        
        @discardableResult
        func reduce(
            _ action: SearchListViewController.Action,
            state: inout State
        ) -> AnyPublisher<SearchListViewController.Action, Never>? {
            switch action {
            case let .searchBarChanged(query):
                state.query = query
                
            case .searchButtonTapped:
                return environment.search(state.query)
                    .map { SearchListViewController.Action.replaceItems($0) }
                    .eraseToAnyPublisher()
                
            case let .replaceItems(items):
                state.items = items
            }
            
            return nil
        }
    }
    
    // MARK: - Properties
    private var reducer: Reducer {
        Reducer(environment: environment)
    }
    let updateViewSubject: PassthroughSubject<[URL], Never>
    @Published private var state: State
    private let environment: Environment
    private var cancellables: Set<AnyCancellable>
    
    // MARK: - Lifecycle
    init(
        state: State,
        environment: Environment
    ) {
        self.state = state
        self.environment = environment
        updateViewSubject = .init()
        cancellables = []
        listenState()
    }
    
    // MARK: - Methods
    func listenAction(subject actionListener: PassthroughSubject<SearchListViewController.Action, Never>) {
        actionListener
            .debounce(for: 0.3, scheduler: environment.scheduler)
            .sink { action in
                self.reducer.reduce(action, state: &self.state)
                    .map(self.fireEffect)
            }
            .store(in: &cancellables)
    }
    
    private func fireEffect(_ effect: AnyPublisher<SearchListViewController.Action, Never>) {
        effect
            .sink { action in
                self.reducer.reduce(action, state: &self.state)
            }
            .store(in: &cancellables)
    }
    
    private func listenState() {
        $state
            .removeDuplicates()
            .receive(on: environment.scheduler)
            .sink { state in
                self.updateViewSubject.send(state.items)
            }
            .store(in: &cancellables)
    }
}
