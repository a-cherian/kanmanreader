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
        let urls = readBookmarks()
        books = retrieveBooks(urls: urls)
        
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
        guard let url = urls.first/*, let _ = UIImage(contentsOfFile: url.path)*/ else { return }
        let (cover, images) = extractBookImages(url: url)
        
        var book = books.first(where: { $0.url == url })
        if book == nil {
            writeBookmarks(url: url)
            book = CoreDataManager.shared.createBook(name: url.lastPathComponent, lastPage: 0, totalPages: images.count, cover: cover, url: url, lastOpened: Date())
        } else {
            book?.lastOpened = Date()
            CoreDataManager.shared.updateBook(book: book)
        }
        
        guard let book = book else { return }
        
        controller.dismiss(animated: true, completion: {
            self.navigationController?.pushViewController(ReaderViewController(images: images, book: book), animated: true)
        })
    }
    
    func didTapBook(position: Int) {
        let book = books[position]
        guard let url = book.url else { return }
        
        let images = extractBookImages(url: url).images
        
        self.navigationController?.pushViewController(ReaderViewController(images: images, book: book), animated: true)
    }
    
    func extractBookImages(url: URL) -> (data: Data, images: [UIImage]) {
        guard url.startAccessingSecurityScopedResource() else {
            return (Data(), [])
        }

        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        guard let archive = Archive(url: url, accessMode: .read) else {
            return (Data(), [])
        }
        
        var images: [UIImage] = []
        
        let sorted = archive.sorted(by: { ($0.fileAttributes[FileAttributeKey(rawValue: "NSFileModificationDate")] as! Date).compare(($1.fileAttributes[FileAttributeKey(rawValue: "NSFileModificationDate")] as! Date)) == .orderedAscending })
        
        var cover: Data = Data([])
        
        for i in 0..<sorted.count {
            let entry = sorted[i]
            
            var extractedData: Data = Data([])
            
            do {
                _ = try archive.extract(entry) { extractedData.append($0) }
                if let image = UIImage(data: extractedData) {
                    images.append(image)
                }
                if(i == 0) { cover = extractedData }
            } catch {
                print(error.localizedDescription)
            }
        }
        
        return (cover, images)
    }
    
    func readBookmarks() -> [URL] {
        let files = try? FileManager.default.contentsOfDirectory(at:  getAppSandboxDirectory(), includingPropertiesForKeys: nil)
        
        let urls: [URL] = files?.compactMap {file in
            do {
                let bookmarkData = try Data(contentsOf: file)
                var isStale = false
                let url = try URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale)
                
                guard !isStale else {
                    deleteFile(url: file)
                    CoreDataManager.shared.deleteBook(for: url)
                    return nil
                }
                
                return url
            }
            catch {
                deleteFile(url: file)
                print(error.localizedDescription)
                return nil
            }
        }  ?? []
        
        return urls
    }
    
    func deleteBookmarks() {
        let files = try? FileManager.default.contentsOfDirectory(at:  getAppSandboxDirectory(), includingPropertiesForKeys: nil)
        
        files?.forEach { file in
            deleteFile(url: file)
        }
    }
    
    func retrieveBooks(urls: [URL]) -> [Book] {
        let books = CoreDataManager.shared.fetchBooks()
        
        let matchedBooks = urls.compactMap { url in
            books?.first(where: { $0.url == url } )
        }
        
        books?.forEach { book in
            if(!matchedBooks.contains(book)) { CoreDataManager.shared.deleteBook(book: book) }
        }
        
        return matchedBooks.sorted(by: { $0.lastOpened ?? Date(timeIntervalSince1970: 0) > $1.lastOpened ?? Date(timeIntervalSince1970: 0) })
    }
    
    func writeBookmarks(url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            return
        }

        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            let bookmarkData = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
            
            let uuid = UUID().uuidString
            try bookmarkData.write(to: getAppSandboxDirectory().appendingPathComponent(uuid))
        }
        catch {
            print("Error creating the bookmark")
        }
    }
    
    func deleteFile(url: URL) {
        let fm = FileManager.default
        do {
            try fm.removeItem(at: url)
        } catch {
            print(error)
        }
    }
    
    private func getAppSandboxDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
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
}

