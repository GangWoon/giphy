//
//  SearchListPreview.swift
//  GIPHY
//
//  Created by Cloud on 2021/09/20.
//

import SwiftUI
import Combine

struct SearchListPreview: View {
    
    var subject: PassthroughSubject<[URL], Never> = .init()
    
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
    var items: [URL] {
        return [
            URL(string: "https://media2.giphy.com/media/3o6Zt481isNVuQI1l6/100w_s.gif?cid=68e125e87n058bexv9lh7wbikfytgpdpnzeem3lgeozebc8q&rid=100w_s.gif&ct=g")!
        ]
    }
}
