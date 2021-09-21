//
//  SearchListPreview.swift
//  GIPHY
//
//  Created by Cloud on 2021/09/20.
//

import SwiftUI
import Combine

struct SearchListPreview: View {
    
    var subject: PassthroughSubject<[UIImage?], Never> = .init()
    
    var body: some View {
        WrappedViewController(SearchListViewController()) { viewController in
//            viewController.listenViewState(subject: subject)
        }
        .onAppear {
            subject.send(items)
        }
    }
}

struct SearchListPreview_Previews: PreviewProvider {
    static var previews: some View {
        SearchListPreview()
    }
}

private extension SearchListPreview {
    var items: [UIImage?] {
        return [
            .init(systemName: "xmark"),
            .init(systemName: "circle"),
            .init(systemName: "pencil"),
            .init(systemName: "scribble"),
            .init(systemName: "pencil.tip"),
            .init(systemName: "trash"),
            .init(systemName: "folder.fill"),
            .init(systemName: "paperplane.fill")
        ]
    }
}
