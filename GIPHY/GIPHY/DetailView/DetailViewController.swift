//
//  DetailViewController.swift
//  GIPHY
//
//  Created by Cloud on 2021/09/21.
//

import UIKit
import Combine

final class DetailViewController: UIViewController {
    
    // MARK: - Views
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor)
        ])
        
        return imageView
    }()
    private lazy var favoritesButton: UIButton = {
        let button = UIButton()
        button.tintColor = theme.favoritesButtonTintColor
        button.backgroundColor = theme.favoritesButtonBackgroundColor
        button.setImage(theme.favoritesButtonImage, for: .normal)
        button.setImage(theme.favoritesButtonSelectedImage, for: .selected)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(
            self,
            action: #selector(favoritesButtonTapped),
            for: .touchUpInside
        )
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        return button
    }()
    
    // MARK: - Properties
    var dispatch: ((Action) -> Void)?
    private let theme: Theme
    
    // MARK: - Lifecycle
    init(_ theme: Theme = .standard) {
        self.theme = theme
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dispatch?(.viewDidLoad)
        build()
    }
    
    // MARK: - Methods
    func update(with state: ViewState) {
        imageView.image = state.image
        favoritesButton.isSelected = state.isFavorites
    }
    
    private func build() {
        view.backgroundColor = .white
        let vStack = UIStackView()
        vStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.axis = .vertical
        vStack.spacing = 8
        vStack.addArrangedSubview(imageView)
        vStack.addArrangedSubview(favoritesButton)
        view.addSubview(vStack)
        
        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            vStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            vStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
        ])
    }
    
    @objc private func favoritesButtonTapped() {
        dispatch?(.favoritesButtonTapped)
    }
}

// MARK: - DetailViewController + Extension
extension DetailViewController {
    struct Theme {
        static let standard = Self(
            favoritesButtonTintColor: .systemPink,
            favoritesButtonBackgroundColor: .systemIndigo,
            favoritesButtonImage: UIImage(systemName: "heart"),
            favoritesButtonSelectedImage: UIImage(systemName: "heart.fill")
        )
        let favoritesButtonTintColor: UIColor
        let favoritesButtonBackgroundColor: UIColor
        let favoritesButtonImage: UIImage?
        let favoritesButtonSelectedImage: UIImage?
    }
    
    enum Action: Equatable {
        case viewDidLoad
        case favoritesButtonTapped
    }
    
    struct ViewState: Equatable {
        static var empty = Self(image: nil, isFavorites: false)
        var image: UIImage?
        var isFavorites: Bool
    }
}
