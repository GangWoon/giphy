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
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        window = UIWindow()
        let navigationController = buildInitialViewController()
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        return true
    }
    
    private func buildInitialViewController() -> UIViewController {
        let searchListViewController = SearchListViewController()
        let networkManager = NetworkManager(
            urlSession: .shared,
            decoder: JSONDecoder()
        )
        let navigator = SearchListViewStore.Environment.Navigator(viewController: searchListViewController)
        let environment = SearchListViewStore.Environment(
            scheduler: .main,
            navigator: navigator,
            search: networkManager.fetchItems
        )
        let store = SearchListViewStore(
            state: .empty,
            environment: environment
        )
        store.listenAction(subject: searchListViewController.actionDispatcher)
        searchListViewController.listenViewState(subject: store.updateViewSubject)
        let navigationController = UINavigationController(rootViewController: searchListViewController)
        
        return navigationController
    }
}
