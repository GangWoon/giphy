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
        var items: [UIImage?]
    }
    
    // MARK: - Environment
    struct Environment {
        let scheduler: DispatchQueue
        let search: (String) -> AnyPublisher<UIImage?, Never>
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
                state.items = []
                return environment.search(state.query)
                    .map { SearchListViewController.Action.replaceItems($0) }
                    .eraseToAnyPublisher()
                
            case let .replaceItems(items):
                state.items.append(items)
            }
            
            return nil
        }
    }
    
    // MARK: - Properties
    private var reducer: Reducer {
        Reducer(environment: environment)
    }
    let updateViewSubject: PassthroughSubject<[UIImage?], Never>
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
                    .map(self.fireEffectAndForget)
            }
            .store(in: &cancellables)
    }
    
    private func fireEffectAndForget(_ effect: AnyPublisher<SearchListViewController.Action, Never>) {
        var cancellable: AnyCancellable?
        cancellable = effect
            .sink(receiveCompletion: { result in
                guard case .finished = result,
                      let cancellable = cancellable else { return }
                self.cancellables.remove(cancellable)
            }, receiveValue: { action in
                self.reducer.reduce(action, state: &self.state)
            })
        cancellable?
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
