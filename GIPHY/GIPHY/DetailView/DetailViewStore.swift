//
//  DetailViewStore.swift
//  GIPHY
//
//  Created by Cloud on 2021/09/21.
//

import UIKit
import Combine

final class DetailViewStore {
    
    // MARK: - State
    struct State: Equatable {
        static var empty = Self(image: nil, isFavorites: false)
        var image: UIImage?
        var isFavorites: Bool = false
    }
    
    // MARK: - Environment
    struct Environment {
        let scheduler: DispatchQueue
        let isFavorites: () -> Bool
        let toggleFavorites: (Bool) -> Void
    }
    
    // MARK: - Reducer
    struct Reducer {
        
        private let environment: Environment
        
        init(environment: Environment) {
            self.environment = environment
        }
        
        func reduce(
            _ action: DetailViewController.Action,
            state: inout State
        ) {
            switch action {
            case .initialData:
                state.isFavorites = environment.isFavorites()
                
            case .favoritesButtonTapped:
                state.isFavorites.toggle()
                environment.toggleFavorites(state.isFavorites)
            }
        }
    }
    
    // MARK: - Properties
    private var reducer: Reducer {
        return Reducer(environment: environment)
    }
    var updateView: ((DetailViewController.ViewState) -> Void)?
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
    func dispatch(_ action: DetailViewController.Action) {
        reducer.reduce(action, state: &state)
    }
    
    private func listenState() {
        $state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateView?(.init(with: state))
            }
            .store(in: &cancellables)
    }
}

private extension DetailViewController.ViewState {
    init(with state: DetailViewStore.State) {
        self.init(
            image: state.image,
            isFavorites: state.isFavorites
        )
    }
}
