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
        static var empty = Self(image: nil, isFavorites: false)
        var image: UIImage?
        var isFavorites: Bool
    }
    
    let updateViewSubject: PassthroughSubject<DetailViewController.ViewState, Never>
    @Published private var state: State
    private var cancellabels: Set<AnyCancellable>
    
    init(state: State) {
        self.state = state
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
