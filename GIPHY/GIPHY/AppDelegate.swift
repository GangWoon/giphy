//
//  AppDelegate.swift
//  GIPHY
//
//  Created by Cloud on 2021/09/19.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    private let documentFileManager: DocumentFileManager = .default
    
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
    
    private func buildInitialViewController() -> UIViewController {
        let searchListViewController = SearchListViewController()
        let networkManager = NetworkManager(
            urlSession: .shared,
            decoder: JSONDecoder()
        )
        let scheduler = DispatchQueue.main
        let container = SearchListViewStore.Navigator.Container(
            scheduler: scheduler,
            documentFileManager: documentFileManager
        )
        let navigator = SearchListViewStore.Navigator(
            viewController: searchListViewController,
            container: container
        )
        let environment = SearchListViewStore.Environment(
            scheduler: scheduler,
            presentDetailView: navigator.presentDetailView(id:metaData:),
            search: networkManager.fetchItems
        )
        let store = SearchListViewStore(
            state: .empty,
            environment: environment
        )
        store.updateView = { [weak searchListViewController] items in
            searchListViewController?.update(with: items)
        }
        searchListViewController.dispatch = store.dispatch
        let navigationController = UINavigationController(rootViewController: searchListViewController)
        
        return navigationController
    }
}
