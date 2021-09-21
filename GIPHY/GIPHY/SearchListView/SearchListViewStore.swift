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
        
        struct Item: Equatable {
            var key: String
            var data: Data
        }
        
        static var empty = Self(query: "", items: [])
        var query: String
        var items: [Item]
    }
    
    struct Navigator {
        
        struct Container {
            let scheduler: DispatchQueue
            let documentFileManager: DocumentFileManager
        }
        
        private let viewController: UIViewController
        private let container: Container
        
        init(
            viewController: UIViewController,
            container: Container
        ) {
            self.viewController = viewController
            self.container = container
        }
        
        func presentDetailView(id: String, metaData: Data) {
            let detailViewControler = DetailViewController()
            let manager = container.documentFileManager
            let state = DetailViewStore.State(image: UIImage(data: metaData))
            let environment = DetailViewStore.Environment(scheduler: container.scheduler) { [weak manager] in
                return manager?.readFavorites(id) ?? false
            } toggleFavorites: { [weak manager] in
                manager?.updateFavorites(id, value: $0)
            }
            let store = DetailViewStore(state: state, environment: environment)
            store.updateView = { [weak detailViewControler] state in
                let viewState = DetailViewController.ViewState(
                    image: state.image,
                    isFavorites: state.isFavorites
                )
                detailViewControler?.update(with: viewState)
            }
            detailViewControler.dispatch = store.dispatch
            
            viewController.show(detailViewControler, sender: viewController)
        }
    }
    
    // MARK: - Environment
    struct Environment {
        let scheduler: DispatchQueue
        let presentDetailView: (String, Data) -> Void
        let search: (String) -> AnyPublisher<(String, Data), Never>
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
                    .map { SearchListViewController.Action.replaceItems(key: $0.0, data: $0.1) }
                    .eraseToAnyPublisher()
                
            case let .listItemTapped(index):
                let item = state.items[index]
                environment.presentDetailView(item.key, item.data)
                
            case let .replaceItems(key, data):
                state.items.append(State.Item(key: key, data: data))
            }
            
            return nil
        }
    }
    
    // MARK: - Properties
    private var reducer: Reducer {
        Reducer(environment: environment)
    }
    var updateView: (([Data]) -> Void)?
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
        cancellables = []
        listenState()
    }
    
    // MARK: - Methods
    func dispatch(_ action: SearchListViewController.Action) {
        reducer.reduce(action, state: &state)
            .map { effect in
                self.fireEffectAndForget(effect)
            }
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
                self.updateView?(state.items.map(\.data))
            }
            .store(in: &cancellables)
    }
}
