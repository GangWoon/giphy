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
    
    // MARK: - Environment
    struct Environment {
        
        struct Navigator {
            
            private let viewController: UIViewController
            
            init(viewController: UIViewController) {
                self.viewController = viewController
            }
            
            func presentDetailView(id: String, metaData: Data) {
                let detailViewControler = DetailViewController()
                let manager = DocumentFileManager.standard
                let env = DetailViewStore.Environment(
                    image: UIImage(data: metaData)
                ) { 
                        manager.readFavorites(with: id)
                    } toggleFavorites: { fact in
                        manager.writeFavorites(with: id, value: fact)
                        manager.writeForDocuments()
                    }
                
                let store = DetailViewStore(state: .empty, environment: env)
                
                store.listenAction(subject: detailViewControler.actionDispatcher)
                detailViewControler.listenViewState(subject: store.updateViewSubject)
                
                viewController.show(detailViewControler, sender: viewController)
            }
        }
        
        let scheduler: DispatchQueue
        let navigator: Navigator
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
                environment.navigator
                    .presentDetailView(id: item.key, metaData: item.data)
                
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
    let updateViewSubject: PassthroughSubject<[Data], Never>
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
                self.updateViewSubject.send(state.items.map(\.data))
            }
            .store(in: &cancellables)
    }
}
