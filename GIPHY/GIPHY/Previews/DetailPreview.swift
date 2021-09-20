//
//  DetailPreview.swift
//  GIPHY
//
//  Created by Cloud on 2021/09/21.
//

import SwiftUI
import Combine

struct DetailPreview: View {
    let subject: PassthroughSubject<DetailViewController.ViewState, Never> = .init()
    var body: some View {
        WrappedViewController(DetailViewController()) { viewController in
            viewController.listenViewState(subject: subject)
        }
        .onAppear {
            subject.send(.dummy)
        }
    }
}

struct DetailPreview_Previews: PreviewProvider {
    static var previews: some View {
        DetailPreview()
    }
}

private extension DetailViewController.ViewState {
    static var dummy = Self(image: UIImage(systemName: "xmark"), isFavorites: true)
}
