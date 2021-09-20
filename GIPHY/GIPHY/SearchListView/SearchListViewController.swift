//
//  SearchListViewController.swift
//  GIPHY
//
//  Created by Cloud on 2021/09/19.
//

import UIKit
import Combine

final class SearchListViewController: UIViewController {
    
    // MARK: - Properties
    let actionDispatcher: PassthroughSubject<Action, Never>
    private let theme: Theme
    private let listViewLineSpacing: CGFloat = 8
    private var dataSource: UICollectionViewDiffableDataSource<Section, UIImage?>?
    private var cancellable: AnyCancellable?
    
    // MARK: - Lifecycle
    init(_ theme: Theme = .standard) {
        self.theme = theme
        actionDispatcher = .init()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        build()
    }
    
    // MARK: - Methods
    func listenViewState(subject updateViewListener: PassthroughSubject<[UIImage?], Never>) {
        cancellable = updateViewListener
            .sink { [weak self] in
                self?.update(with: $0)
            }
    }
    
    private func update(with state: [UIImage?]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, UIImage?>()
        snapshot.appendSections([.main])
        snapshot.appendItems(state)
        dataSource?.apply(snapshot)
    }
    
    private func build() {
        view.backgroundColor = .white
        buildNavigationItem()
        buildVStack()
    }
    
    private func buildNavigationItem() {
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = theme.navigationTitle
    }
    
    private func buildVStack() {
        let vStack = UIStackView()
        vStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.axis = .vertical
        vStack.spacing = 8
        vStack.addArrangedSubview(buildSearchBar())
        vStack.addArrangedSubview(buildListView())
        view.addSubview(vStack)
        
        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            vStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: listViewLineSpacing),
            vStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -listViewLineSpacing),
            vStack.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func buildSearchBar() -> UIView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        let textField = UITextField()
        textField.placeholder = theme.searchBarPlaceholder
        textField.clearButtonMode = .whileEditing
        textField.addTarget(
            self,
            action: #selector(searchBarChanged),
            for: .editingChanged
        )
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(
            theme.searchButtonImage,
            for: .normal
        )
        button.backgroundColor = theme.searchButtonBackgroundColor
        button.addTarget(
            self,
            action: #selector(searchButtonTapped),
            for: .touchUpInside
        )
        stackView.addArrangedSubview(textField)
        stackView.addArrangedSubview(button)
        
        NSLayoutConstraint.activate([
            stackView.heightAnchor.constraint(equalToConstant: 52),
            button.widthAnchor.constraint(equalTo: button.heightAnchor)
        ])
        
        return stackView
    }
    
    private func buildViewLayout() -> UICollectionViewFlowLayout {
        let listViewLayout = UICollectionViewFlowLayout()
        listViewLayout.scrollDirection = .vertical
        listViewLayout.minimumInteritemSpacing = listViewLineSpacing
        listViewLayout.minimumLineSpacing = listViewLineSpacing
        
        return listViewLayout
    }
    
    private func buildListView() -> UIView {
        let listView = UICollectionView(
            frame: .zero,
            collectionViewLayout: buildViewLayout()
        )
        listView.register(
            SearchListRow.self,
            forCellWithReuseIdentifier: SearchListRow.identifier
        )
        listView.backgroundColor = .clear
        listView.alwaysBounceVertical = true
        dataSource = .init(
            collectionView: listView,
            cellProvider: { listView, indexPath, image in
                let cell = listView.dequeueReusableCell(
                    withReuseIdentifier: SearchListRow.identifier,
                    for: indexPath
                ) as? SearchListRow
                cell?.update(with: image)
                
                return cell
            }
        )
        listView.dataSource = dataSource
        listView.delegate = self
        
        return listView
    }
    
    @objc private func searchButtonTapped() {
        actionDispatcher.send(.searchButtonTapped)
    }
    
    @objc private func searchBarChanged(_ sender: UITextField) {
        actionDispatcher.send(.searchBarChanged(sender.text ?? ""))
    }
}

// MARK: - SearchListViewController + Extension
extension SearchListViewController {
    
    struct Theme {
        static let standard = Self(
            navigationTitle: "Search",
            searchBarPlaceholder: "Search GIPHY",
            searchButtonImage: UIImage(systemName: "magnifyingglass"),
            searchButtonBackgroundColor: .systemPink
        )
        let navigationTitle: String
        let searchBarPlaceholder: String
        let searchButtonImage: UIImage?
        let searchButtonBackgroundColor: UIColor
    }
    
    enum Action: Equatable {
        case searchBarChanged(String)
        case searchButtonTapped
        case replaceItems(UIImage?)
    }
    
    private enum Section: Hashable {
        case main
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension SearchListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let length = (collectionView.frame.width - listViewLineSpacing) / 2
        return CGSize(width: length, height: length)
    }
}
