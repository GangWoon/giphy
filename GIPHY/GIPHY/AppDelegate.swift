//
//  AppDelegate.swift
//  GIPHY
//
//  Created by Cloud on 2021/09/19.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: - Properties
    var window: UIWindow?
    private let documentFileManager: DocumentFileManager = DocumentFileManager {
        let urls = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask)
        return urls[0]
    }
    
    // MARK: - App Lifecyle
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        window = UIWindow()
        documentFileManager.readDocuments()
        let navigationController = buildInitialViewController()
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        documentFileManager.updateDocuments()
    }
    
    // MARK: - Methods
    private func buildInitialViewController() -> UIViewController {
        let searchListViewController = SearchListViewController()
        let navigator = SearchListViewStore.Navigator(
            viewController: searchListViewController,
            container: container
        )
        let store = SearchListViewStore(
            state: .empty,
            environment: makeEnvironment(presentDetailView: navigator.presentDetailView)
        )
        store.updateView = { [weak searchListViewController] items in
            searchListViewController?.update(with: items)
        }
        searchListViewController.dispatch = store.dispatch
        let navigationController = UINavigationController(rootViewController: searchListViewController)
        
        return navigationController
    }
    
    private func makeEnvironment(presentDetailView: @escaping (String, Data) -> Void) -> SearchListViewStore.Environment {
        return SearchListViewStore.Environment(
            scheduler: scheduler,
            presentDetailView: presentDetailView,
            search: networkManager.fetchItems
        )
    }
}

private extension AppDelegate {
    var scheduler: DispatchQueue {
        return .main
    }
    
    var networkManager: NetworkManager {
        return NetworkManager(
            urlSession: .shared,
            decoder: JSONDecoder()
        )
    }
    
    var container: SearchListViewStore.Navigator.Container {
        return SearchListViewStore.Navigator.Container(
            scheduler: scheduler,
            documentFileManager: documentFileManager
        )
    }
}
