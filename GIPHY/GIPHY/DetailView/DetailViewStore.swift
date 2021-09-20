//
//  DetailViewStore.swift
//  GIPHY
//
//  Created by Cloud on 2021/09/21.
//

import UIKit
import Combine

final class DetailViewStore {
    
    struct State: Equatable {
        static var empty = Self(id: "", image: nil, isFavorites: false)
        var id: String
        var image: UIImage?
        var isFavorites: Bool
    }
    
    struct Environment {
        let image: UIImage?
        let isFavorites: (String) -> Bool
        let toggleFavorites: (Bool) -> Void
    }
    
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
            case .viewDidLoad:
                state.image = environment.image
                state.isFavorites = environment.isFavorites(state.id)
                
            case .favoritesButtonTapped:
                state.isFavorites.toggle()
                environment.toggleFavorites(state.isFavorites)
            }
        }
    }
    
    private var reducer: Reducer {
        return Reducer(environment: environment)
    }
    let updateViewSubject: PassthroughSubject<DetailViewController.ViewState, Never>
    @Published private var state: State
    private let environment: Environment
    private var cancellabels: Set<AnyCancellable>
    
    init(
        state: State,
        environment: Environment
    ) {
        self.state = state
        self.environment = environment
        updateViewSubject = .init()
        cancellabels = []
        listenState()
    }
    
    private func listenState() {
        $state
            .removeDuplicates()
            .sink { state in
                self.updateViewSubject.send(DetailViewController.ViewState(with: state))
            }
            .store(in: &cancellabels)
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
