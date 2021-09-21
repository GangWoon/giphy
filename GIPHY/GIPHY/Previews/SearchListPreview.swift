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
            viewController.update(with: items)
        }
    }
}

struct SearchListPreview_Previews: PreviewProvider {
    static var previews: some View {
        SearchListPreview()
    }
}

private extension SearchListPreview {
    var items: [Data] {
        return [
            (UIImage(systemName: "xmark")?.pngData())!,
            (UIImage(systemName: "circle")?.pngData())!,
            (UIImage(systemName: "pencil")?.pngData())!,
            (UIImage(systemName: "scribble")?.pngData())!,
            (UIImage(systemName: "pencil.tip")?.pngData())!,
            (UIImage(systemName: "trash")?.pngData())!,
            (UIImage(systemName: "folder.fill")?.pngData())!,
            (UIImage(systemName: "paperplane.fill")?.pngData())!
        ]
    }
}
