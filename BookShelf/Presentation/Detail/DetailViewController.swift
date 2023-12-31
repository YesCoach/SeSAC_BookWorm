//
//  DetailViewController.swift
//  BookShelf
//
//  Created by 박태현 on 2023/07/31.
//

import UIKit

final class DetailViewController: UIViewController {

    @IBOutlet var posterImageView: UIImageView!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var overviewLabel: UILabel!
    @IBOutlet var memoTextView: UITextView!
    @IBOutlet var stackView: UIStackView!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var toolBar: UIToolbar!
    @IBOutlet var scrollViewBottomConstraint: NSLayoutConstraint!

    private lazy var favoriteButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "star"), for: .normal)
        button.setImage(UIImage(systemName: "star.fill"), for: .selected)
        button.addTarget(self, action: #selector(didFavoriteBarButtonTouched), for: .touchUpInside)
        button.tintColor = .systemMint
        return button
    }()

    private let localBookUseCase = DIContainer.shared.makeLocalBookUseCase()

    private var data: Book?
    private let placeHolder = "메모를 입력해보세요"

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureLayout()
        configureNavigationItem()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        enableLargeTitle()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        disableLargeTitle()
    }

    @IBAction func didBackgroundViewTouched(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }

    // viewController의 화면 전환 방식에 따른 돌아가기 버튼 로직 분기 처리
    @objc func didDismissBarButtonTouched() {
        if navigationController?.modalPresentationStyle == .fullScreen {
            dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    @objc func didFavoriteBarButtonTouched(_ sender: UIBarButtonItem) {
        sender.isSelected.toggle()
        data?.isFavorite = sender.isSelected
    }

    @IBAction func didSaveButtonTouched(_ sender: Any) {
        saveChangedData()
        didDismissBarButtonTouched()
    }

    @IBAction func didDeleteBarButtonTouched(_ sender: Any) {
        if let data {
            localBookUseCase.deleteBookData(book: data)
        }
        didDismissBarButtonTouched()
    }



}

private extension DetailViewController {
    func configureUI() {
        guard let data else { return }
        infoLabel.text = data.title
        overviewLabel.text = data.contents
        if let localImageURL = data.localImageURL {
            posterImageView.image = FileSystemManager
                .shared
                .loadImageFromDocument(fileName: localImageURL)
        }
        posterImageView.contentMode = .scaleAspectFill
        favoriteButton.isSelected = data.isFavorite

        memoTextView.text = data.memo
        memoTextView.setupDetailTextView()
        memoTextView.setupPlaceHolder(with: placeHolder)
        memoTextView.isScrollEnabled = false
        memoTextView.delegate = self

        let spacing = 16.0
        stackView.layoutMargins = .init(
            top: spacing,
            left: spacing,
            bottom: spacing,
            right: spacing
        )
        stackView.isLayoutMarginsRelativeArrangement = true
    }

    // viewController의 화면 전환 방식에 따른 네비게이션 아이템 구성 로직 분기 처리
    func configureNavigationItem() {
        navigationItem.title = data?.title ?? ""

        if navigationController?.modalPresentationStyle == .fullScreen {
            let dismissButton = UIBarButtonItem(
                image: .init(systemName: "xmark"),
                style: .plain,
                target: self,
                action: #selector(didDismissBarButtonTouched)
            )
            navigationItem.leftBarButtonItem = dismissButton
        } else {
            let dismissButton = UIBarButtonItem(
                image: .init(systemName: "chevron.left"),
                style: .plain,
                target: self,
                action: #selector(didDismissBarButtonTouched)
            )
            navigationItem.leftBarButtonItem = dismissButton
        }
        navigationItem.leftBarButtonItem?.tintColor = .systemMint
        let favoriteButton = UIBarButtonItem(customView: favoriteButton)
        navigationItem.rightBarButtonItem = favoriteButton
        navigationItem.largeTitleDisplayMode = .automatic
    }

    func configureLayout() { }

    func enableLargeTitle() {
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    func disableLargeTitle() {
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    /// VC가 사라지기 전에, 변동 데이터를 저장하는 메소드입니다.
    func saveChangedData() {
        if memoTextView.text! == placeHolder || memoTextView.text.isEmpty {
            data?.memo = nil
        } else {
            data?.memo = memoTextView.text!
        }
        if let data {
            localBookUseCase.updateBookData(book: data)
        }
    }
}

extension DetailViewController {
    func configure(with data: Book) {
        self.data = data
    }
}

// MARK: - TextViewDelegate 구현부

extension DetailViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        toolBar.isHidden = true
        scrollViewBottomConstraint.constant = toolBar.frame.height * (-1)
        if textView.text == placeHolder {
            textView.text = ""
            textView.textColor = .label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        toolBar.isHidden = false
        scrollViewBottomConstraint.constant = 0
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = ""
            textView.setupPlaceHolder(with: placeHolder)
        }
    }
}
