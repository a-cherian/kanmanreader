//
//  EntryCreationViewController.swift
//  KanshuReader
//
//  Created by AC on 12/15/23.
//

import UIKit
import UniformTypeIdentifiers

class DocumentSelectionViewController: UIViewController, BookCellDelegate {
    
    var books: [Book] = []
    
    lazy var importButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        
        button.backgroundColor = .black
        button.tintColor = .white
        button.layer.cornerRadius = 10
        button.layer.borderColor = Constants.accentColor.cgColor
        button.layer.borderWidth = 2
        button.setImage(UIImage(systemName: "doc.badge.plus"), for: .normal)
        
        button.addTarget(self, action: #selector(didTapImport), for: .touchUpInside)
        return button
    }()
    
    lazy var documentCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: min(UIScreen.main.bounds.width/2.5, UIScreen.main.bounds.height/5), height: UIScreen.main.bounds.height / 3)
        layout.sectionInset = UIEdgeInsets(top: 10, left: -5, bottom: 10, right: -5)
        
        let collection = UICollectionView(frame: CGRectZero, collectionViewLayout: layout)
        collection.contentInset = UIEdgeInsets(top: 15, left: 10, bottom: 15, right: 15)
        collection.backgroundColor = .clear
        collection.tintColor = .black
        collection.showsVerticalScrollIndicator = false
        collection.dataSource = self
        collection.delegate = self
        collection.register(BookCell.self, forCellWithReuseIdentifier: BookCell.identifier)
        
        return collection
    }()
    
    lazy var emptyLabel: UILabel = {
        let label = UILabel()
        
        label.textColor = .black
        label.attributedText = getEmptyLabelText()
        label.textAlignment = .center
        label.numberOfLines = 5
        label.lineBreakMode = .byWordWrapping
        
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: importButton)
        
        refreshData()
        
        addSubviews()
        configureUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        refreshData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: UIApplication.didBecomeActiveNotification, object: nil)
        hidesBottomBarWhenPushed = true
        
        checkOnboarding()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        hidesBottomBarWhenPushed = false
    }
    
    @objc func refreshData() {
        books = BookmarkManager.retrieveBooks()
        documentCollectionView.reloadData()
        
        emptyLabel.isHidden = books.count > 0 && !(books.count == 1 && books[0].isTutorial)
    }
    
    func addSubviews() {
        view.addSubview(importButton)
        view.addSubview(emptyLabel)
        view.addSubview(documentCollectionView)
    }

    func configureUI() {
        configureEmptyLabel()
        configureDocumentCollectionView()
    }
    
    func configureDocumentCollectionView() {
        documentCollectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            documentCollectionView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            documentCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            documentCollectionView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            documentCollectionView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])
    }
    
    func configureEmptyLabel() {
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyLabel.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            emptyLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 20),
            emptyLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -20)
        ])
    }
    
    func checkOnboarding() {
        let hasOnboarded = UserDefaults.standard.bool(forKey: Constants.HAS_ONBOARDED_KEY)
        
        if(!hasOnboarded) {
            let onboardingViewController = OnboardingViewController()
            if let presentationController = onboardingViewController.presentationController as? UISheetPresentationController {
                presentationController.detents = [.large()]
                presentationController.prefersGrabberVisible = true
                presentationController.prefersScrollingExpandsWhenScrolledToEdge = false
            }
            
            self.present(onboardingViewController, animated: true)
            
            UserDefaults.standard.setValue(true, forKey: Constants.HAS_ONBOARDED_KEY)
        }
    }

    @objc func didTapImport() {
        let fileTypes: [UTType] = [.zip, .archive, UTType(importedAs: "com.acherian.cbz"), UTType(importedAs: "com.acherian.cbr")].compactMap { $0 }
        
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: fileTypes, asCopy: false)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        documentPicker.modalPresentationStyle = .fullScreen
        present(documentPicker, animated: true, completion: nil)
    }
    
    func didTapBook(position: Int) {
        let book = books[position]
        openBook(book)
    }
    
    func openBook(_ book: Book) {
        if let url = book.url {
            book.lastOpened = Date()
            CoreDataManager.shared.updateBook(book: book)
            let images = BookmarkManager.getImages(for: url)?.images ?? []
            self.navigationController?.pushViewController(ReaderViewController(images: images, book: book), animated: true)
        }
    }
    
    func renameAction(_ book: Book) {
        let alert = UIAlertController(
            title: "Rename book",
            message: "Enter a new title for your book.",
            preferredStyle: .alert
        )
        alert.addTextField { (textField) in
            textField.text = book.name
        }
        alert.addAction(UIAlertAction(
            title: "OK",
            style: .default,
            handler: { _ in
                let name = alert.textFields?[0].text
                book.name = name
                CoreDataManager.shared.updateBook(book: book)
                self.refreshData()
        }))
        alert.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: { _ in
            // cancel action
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func resetAction(_ book: Book) {
        let alert = UIAlertController(
            title: "Reset book progress",
            message: "This will reset this book's progress to 0. Do you wish to proceed?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: "Reset",
            style: .destructive,
            handler: { _ in
                book.lastPage = 0
                CoreDataManager.shared.updateBook(book: book)
                self.refreshData()
        }))
        alert.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: { _ in
            // cancel action
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func deleteAction(_ book: Book) {
        let alert = UIAlertController(
            title: "Confirm deletion",
            message: "This will delete this book. This action is irreversible. Do you wish to proceed?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: "Delete",
            style: .destructive,
            handler: { _ in
                CoreDataManager.shared.deleteBook(book: book)
                self.refreshData()
        }))
        alert.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: { _ in
            // cancel action
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func getEmptyLabelText() -> NSAttributedString {
        let attachment:NSTextAttachment = NSTextAttachment()
        attachment.image = UIImage(systemName: "doc.badge.plus")

        let string = NSMutableAttributedString(string: "This library is feeling a little empty!\n\n Click ")
        let attachmentString = NSAttributedString(attachment: attachment)
        let endPortion = NSAttributedString(string: " to add comics in ZIP, RAR, CBR, or CBZ format.")
        
        string.append(attachmentString)
        string.append(endPortion)

        return string
    }
}






extension DocumentSelectionViewController: UIDocumentPickerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let books = urls.compactMap { url in
            return BookmarkManager.createBook(from: url)
        }
        
        if(urls.count == 1 && books.count == 1) {
            controller.dismiss(animated: true, completion: {
                self.openBook(books[0])
            })
        }
        
        refreshData()
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return books.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let book = books[indexPath.item]
        
        let cell = documentCollectionView.dequeueReusableCell(withReuseIdentifier: BookCell.identifier, for: indexPath) as! BookCell
        cell.tag = indexPath.item
        cell.delegate = self
        
        cell.title.text = book.name
        cell.progress.text = "Pages: " + String(book.lastPage + 1) + " / " + String(book.totalPages)
        
        cell.coverView.image = UIImage(data: book.cover ?? Data()) ?? UIImage()
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                         contextMenuConfigurationForItemAt indexPath: IndexPath,
                         point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            let book = self.books[indexPath.item]
            let renameAction = UIAction(title: "Rename") { _ in self.renameAction(book) }
            let resetAction = UIAction(title: "Reset Progress") { _ in self.resetAction(book) }
            let deleteAction = UIAction(title: "Delete") { _ in self.deleteAction(book) }
            return UIMenu(title: "", children: [renameAction, resetAction, deleteAction])
        }
    }
}
