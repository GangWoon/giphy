//
//  Helper.swift
//  GIPHY
//
//  Created by Cloud on 2021/09/20.
//

import SwiftUI

struct WrappedViewController<Wrapped: UIViewController>: UIViewControllerRepresentable {
   
    private let viewController: Wrapped
    private let update: (Wrapped) -> Void
    
    init(_ viewController: Wrapped, update: @escaping (Wrapped) -> Void) {
        self.viewController = viewController
        self.update = update
    }
    
    func makeUIViewController(context: Context) -> Wrapped {
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: Wrapped, context: Context) {
        update(uiViewController)
    }
}
