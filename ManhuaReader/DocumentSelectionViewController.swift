//
//  EntryCreationViewController.swift
//  ManhuaReader
//
//  Created by AC on 12/15/23.
//

import UIKit
import UniformTypeIdentifiers
import ZIPFoundation

class DocumentSelectionViewController: UIViewController, UIDocumentPickerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, BookCellDelegate {
    
    var books: [Book] = []
    
    lazy var importButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        
        button.backgroundColor = .black
        button.tintColor = Constants.accentColor
        button.layer.cornerRadius = 10
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 2
        button.setImage(UIImage(systemName: "doc.badge.plus"), for: .normal)
        
        button.addTarget(self, action: #selector(didTapImport), for: .touchUpInside)
        return button
    }()
    
    lazy var documentCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        
        let collection = UICollectionView(frame: CGRectZero, collectionViewLayout: layout)
        collection.backgroundColor = .white
        collection.tintColor = .black
        collection.showsVerticalScrollIndicator = false
        collection.dataSource = self
        collection.delegate = self
        collection.register(BookCell.self, forCellWithReuseIdentifier: BookCell.identifier)
        
        return collection
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
        hidesBottomBarWhenPushed = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        hidesBottomBarWhenPushed = false
    }
    
    func refreshData() {
        books = BookmarkManager.shared.retrieveBooks()
        print(books)
        documentCollectionView.reloadData()
    }
    
    func addSubviews() {
        view.addSubview(importButton)
        view.addSubview(documentCollectionView)
    }

    func configureUI() {
        configureDocumentCollectionView()
    }
    
    func configureDocumentCollectionView() {
        documentCollectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            documentCollectionView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            documentCollectionView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
            documentCollectionView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            documentCollectionView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])
    }

    @objc func didTapImport() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.zip], asCopy: false)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        documentPicker.modalPresentationStyle = .fullScreen
        present(documentPicker, animated: true, completion: nil)
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        let images = BookmarkManager.shared.getImages(for: url).images
        guard let book = BookmarkManager.shared.createBook(from: url) else { return }
        
        controller.dismiss(animated: true, completion: {
            self.navigationController?.pushViewController(ReaderViewController(images: images, book: book), animated: true)
        })
    }
    
    func didTapBook(position: Int) {
        let book = books[position]
        guard let url = book.url else { return }
        
        let images = BookmarkManager.shared.getImages(for: url).images
        
        self.navigationController?.pushViewController(ReaderViewController(images: images, book: book), animated: true)
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
        cell.progress.text = "Progress: " + String(book.lastPage) + " / " + String(book.totalPages)
        cell.coverView.image = UIImage(data: book.cover ?? Data()) ?? UIImage()
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = view.frame.size.width
        let cellWidth: CGFloat = 160
        let cellHeight: CGFloat = 250
        
        let marginsAndInsets = documentCollectionView.safeAreaInsets.left + documentCollectionView.safeAreaInsets.right + 20
        let twoRowWidth = ((collectionView.bounds.size.width - marginsAndInsets) / CGFloat(2)).rounded(.down)
        
        if twoRowWidth < cellWidth { return CGSize(width: width * 0.8, height: width * 0.8 * (cellHeight / cellWidth)) }
        
        return CGSize(width: cellWidth, height: cellHeight)
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

