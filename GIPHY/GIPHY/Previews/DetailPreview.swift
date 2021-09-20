//
//  DetailPreview.swift
//  GIPHY
//
//  Created by Cloud on 2021/09/21.
//

import SwiftUI

struct DetailPreview: View {
    var body: some View {
        WrappedViewController(DetailViewController()) { viewController in
            viewController.update(with: .dummy)
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
