//
//  DocumentSelectionViewController.swift
//  KanmanReader
//
//  Created by AC on 12/15/23.
//

import UIKit
import UniformTypeIdentifiers
import CoreData

class DocumentSelectionViewController: UIViewController, ComicCellDelegate, UIViewControllerTransitioningDelegate {
    
    var appPreferences = AppPreferences(from: nil)
//    var comics: [Comic] = []
    var comicFetchResultsController = NSFetchedResultsController<Comic>()
    var selectedComic: Comic? = nil
    var isSelecting = false
    
    lazy var importButton = {
        let item = UIBarButtonItem(image: UIImage(systemName: "doc.badge.plus"), style: .plain, target: self, action: #selector(didTapImport))
        return item
    }()
    
    lazy var selectButton = {
        let item = UIBarButtonItem(image: UIImage(systemName: "checkmark.circle"), style: .plain, target: self, action: #selector(didTapSelect))
        return item
    }()
    
    lazy var deleteButton = {
        let deleteAction = UIAction(title: "About") { _ in self.didTapDelete() }
        let item = UIBarButtonItem(systemItem: .trash, primaryAction: deleteAction)
        item.tintColor = .red
        return item
    }()
    
    lazy var cancelButton = {
        let item = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(didTapSelect))
        return item
    }()
    
    lazy var selectAllButton = {
        let item = UIBarButtonItem(title: "Select All", style: .plain, target: self, action: #selector(didTapSelectAll))
        return item
    }()
    
    lazy var documentCollectionView: UICollectionView = {
        let screenHeight = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let screenWidth = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: min(screenWidth / 2.5, screenHeight / 5), height: screenHeight / 4)
        layout.minimumLineSpacing = 20
        layout.sectionInset = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: -5)
        
        let collection = UICollectionView(frame: CGRectZero, collectionViewLayout: layout)
        collection.contentInset = UIEdgeInsets(top: 30, left: 15, bottom: 30, right: 15)
        collection.backgroundColor = .clear
        collection.tintColor = .black
        collection.showsVerticalScrollIndicator = false
        collection.dataSource = self
        collection.delegate = self
        collection.register(ComicCell.self, forCellWithReuseIdentifier: ComicCell.identifier)
        
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
        title = "Library"
        
        view.backgroundColor = .white
        view.layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        
        navigationController?.toolbar.frame = navigationController?.tabBarController?.tabBar.frame ?? navigationController?.toolbar.frame ?? .zero
        
        disableSelectionMode()
        
        comicFetchResultsController = CoreDataManager.shared.getComicResultsController(delegate: self)
        comicFetchResultsController.delegate = self
        
        refreshData()
        
        addSubviews()
        configureUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        appPreferences = AppPreferences(from: nil)
        refreshData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        hidesBottomBarWhenPushed = true
        checkOnboarding()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        hidesBottomBarWhenPushed = false
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func refreshData() {
        documentCollectionView.reloadData()
        
        let visibleComicCount = comicFetchResultsController.sections?[0].numberOfObjects ?? 0
        emptyLabel.isHidden = visibleComicCount > 0 && !(visibleComicCount == 1  && comicFetchResultsController.object(at: IndexPath(item: 0, section: 0)).isTutorial)
    }
    
    func addSubviews() {
        view.addSubview(documentCollectionView)
        view.addSubview(emptyLabel)
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
            onboardingViewController.transitioningDelegate = self
            if let presentationController = onboardingViewController.presentationController as? UISheetPresentationController {
                presentationController.detents = [.large()]
                presentationController.prefersEdgeAttachedInCompactHeight = true
                presentationController.prefersGrabberVisible = true
                presentationController.prefersScrollingExpandsWhenScrolledToEdge = false
            }
            
            self.present(onboardingViewController, animated: true)
            
            UserDefaults.standard.setValue(true, forKey: Constants.HAS_ONBOARDED_KEY)
        }
    }
    
    func disableSelectionMode() {
        isSelecting = false
        documentCollectionView.allowsSelection = false
        documentCollectionView.allowsMultipleSelection = false
        
        navigationItem.rightBarButtonItems = [selectButton]
        navigationItem.leftBarButtonItems = [importButton]
        toolbarItems = []
        
        navigationController?.setToolbarHidden(true, animated: true)
    }
    
    func enableSelectionMode() {
        isSelecting = true
        documentCollectionView.allowsSelection = true
        documentCollectionView.allowsMultipleSelection = true
        
        navigationItem.rightBarButtonItems = [cancelButton]
        navigationItem.leftBarButtonItems = [selectAllButton]
        toolbarItems = [UIBarButtonItem(systemItem: .flexibleSpace), deleteButton]

        navigationController?.setToolbarHidden(false, animated: true)
    }
    
    @objc func didTapImport() {
        let fileTypes: [UTType] = [.zip, UTType(filenameExtension: "rar"), UTType(importedAs: "com.acherian.cbz"), UTType(importedAs: "com.acherian.cbr")].compactMap { $0 }
        
        let documentPicker = KMRDocumentPickerViewController(forOpeningContentTypes: fileTypes, asCopy: false)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        documentPicker.modalPresentationStyle = .fullScreen
        present(documentPicker, animated: true, completion: nil)
    }
    
    @objc func didTapSelect() {
        isSelecting = !isSelecting
        
        if(isSelecting) {
            enableSelectionMode()
        }
        else {
            disableSelectionMode()
        }
        
        refreshData()
    }
    
    @objc func didTapSelectAll() {
        for row in 0..<documentCollectionView.numberOfItems(inSection: 0) {
            documentCollectionView.selectItem(at: IndexPath(row: row, section: 0), animated: false, scrollPosition: [])
        }
    }
    
    @objc func didTapDelete() {
        let selected = documentCollectionView.indexPathsForSelectedItems
        let comicsToDelete = selected?.compactMap { indexPath in
            comicFetchResultsController.object(at: indexPath)
        } ?? []
        
        if comicsToDelete.count == 0  { return }
        
        let alert = UIAlertController(
            title: "Confirm deletion",
            message: "This will remove \(comicsToDelete.count) of your manhua from your library. This action is irreversible. Do you wish to proceed?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: "Delete",
            style: .destructive,
            handler: { _ in
                comicsToDelete.forEach { comic in
                    ComicFileManager.deleteComic(comic: comic)
                }
                self.disableSelectionMode()
        }))
        alert.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: { _ in
            // cancel action
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func didTapComic(position: Int) {
        let comic = comicFetchResultsController.object(at: IndexPath(item: position, section: 0))
        openComic(comic)
    }
    
    func openComic(_ comic: Comic) {
        if let url = comic.url, let images = try? ComicFileManager.getImages(for: url) {
            comic.lastOpened = Date()
            CoreDataManager.shared.updateComic(comic: comic)
            comic.lastOpened = Date()
            CoreDataManager.shared.updateComic(comic: comic)
            self.navigationController?.pushViewController(ReaderViewController(images: images, comic: comic), animated: true)
            return
        }
        
        ComicFileManager.deleteComic(comic: comic)
        
        let alert = UIAlertController(
            title: "Could not open manhua",
            message: "\"\(comic.name ?? "Manhua")\" was unable to be opened, and will be removed from your library. Try re-importing the manhua file, or contact support if the problem persists.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: "OK",
            style: .default,
            handler: { _ in
                // cancel action
            }))
        alert.show()
    }
    
    func renameAction(_ comic: Comic) {
        let alert = UIAlertController(
            title: "Rename comic",
            message: "Enter a new title for your comic.",
            preferredStyle: .alert
        )
        alert.addTextField { (textField) in
            textField.text = comic.name
        }
        alert.addAction(UIAlertAction(
            title: "OK",
            style: .default,
            handler: { _ in
                let name = alert.textFields?[0].text
                comic.name = name
                CoreDataManager.shared.updateComic(comic: comic)
        }))
        alert.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: { _ in
            // cancel action
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func resetAction(_ comic: Comic) {
        let alert = UIAlertController(
            title: "Reset comic progress",
            message: "This will reset this comic's progress to the start. Do you wish to proceed?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: "Reset",
            style: .destructive,
            handler: { _ in
                comic.lastPage = 0
                CoreDataManager.shared.updateComic(comic: comic)
        }))
        alert.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: { _ in
            // cancel action
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func openTutorial() {
        guard let tutorial = ComicFileManager.createTutorial() else { return }
        openComic(tutorial)
    }
    
    func openAbout() {
        let aboutViewController = AboutViewController()
        if let presentationController = aboutViewController.presentationController as? UISheetPresentationController {
            presentationController.detents = [.medium(), .large()]
            presentationController.prefersEdgeAttachedInCompactHeight = true
            presentationController.prefersGrabberVisible = true
            presentationController.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        
        self.present(aboutViewController, animated: true)
    }
    
    func deleteAction(_ comic: Comic) {
        let alert = UIAlertController(
            title: "Confirm deletion",
            message: "This will remove this manhua from your library. This action is irreversible. Do you wish to proceed?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: "Delete",
            style: .destructive,
            handler: { _ in
                ComicFileManager.deleteComic(comic: comic)
        }))
        alert.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: { _ in
            // cancel action
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func changeCover(_ comic: Comic) {
        selectedComic = comic
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }
    
    func pickedCover(_ image: UIImage) {
        selectedComic?.cover = image.pngData()
        CoreDataManager.shared.updateComic(comic: selectedComic)
    }
    
    func getEmptyLabelText() -> NSAttributedString {
        let attachment:NSTextAttachment = NSTextAttachment()
        attachment.image = UIImage(systemName: "doc.badge.plus")

        let string = NSMutableAttributedString(string: "This library is feeling a little empty!\n\n Click the ")
        let attachmentString = NSAttributedString(attachment: attachment)
        let endPortion = NSAttributedString(string: " above to add manhua in ZIP, RAR, CBR, or CBZ format.")
        
        string.append(attachmentString)
        string.append(endPortion)

        return string
    }
}






extension DocumentSelectionViewController: UIDocumentPickerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate {
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        refreshData()
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if(urls.count == 1) {
            controller.dismiss(animated: true, completion: {
                guard let comic = ComicFileManager.createComic(from: urls[0]) else { return }
                self.openComic(comic)
            })
        }
        else {
            Task {
                await ComicFileManager.createComics(for: urls)
                print("Batch of comics created...")
            }
        }
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return comicFetchResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let comic = comicFetchResultsController.object(at: indexPath)
        
        let cell = documentCollectionView.dequeueReusableCell(withReuseIdentifier: ComicCell.identifier, for: indexPath) as! ComicCell
        cell.tag = indexPath.item
        cell.delegate = self
        cell.gestureRecognizers?.first?.delegate = self
        
        cell.title.text = comic.name
        cell.progress.text = "Pages: " + String(comic.lastPage + 1) + " / " + String(comic.totalPages)
        
        cell.coverView.image = UIImage(data: comic.cover ?? Data()) ?? UIImage()
        
        cell.selectView.isHidden = !isSelecting
        cell.chapterNumber = nil
        
        if(!appPreferences.displayChapterNumbers) { return cell }
        
        // try to scan english chapter number
        let scanner = Scanner(string: comic.name ?? "")
        _ = scanner.scanUpToCharacters(from: CharacterSet(charactersIn: "123456789."))
        if let scannedVal = scanner.scanDouble() {
            cell.chapterNumber = CGFloat(scannedVal)
            return cell
        }
        
        // try to scan chinese chapter number
        if let chineseNumber = comic.name?.firstMatch(of: /[零一二三四五六七八九十百千万亿兆]+/)?.0 as? Substring {
            let formatter = NumberFormatter()
            formatter.locale = Locale(identifier: "zh")
            formatter.numberStyle = .spellOut
            guard let number = formatter.number(from: String(chineseNumber)) else { return cell }
            cell.chapterNumber = CGFloat(truncating: number)
            
            return cell
        }
        
        cell.chapterNumber = nil
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                         contextMenuConfigurationForItemAt indexPath: IndexPath,
                         point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            let comic = self.comicFetchResultsController.object(at: indexPath)
            
            let renameAction = UIAction(title: "Rename") { _ in self.renameAction(comic) }
            let changeCoverAction = UIAction(title: "Change Cover") { _ in self.changeCover(comic) }
            let resetAction = UIAction(title: "Reset Progress") { _ in self.resetAction(comic) }
            let deleteAction = UIAction(title: "Delete") { _ in self.deleteAction(comic) }
            
            return UIMenu(title: "", children: [renameAction, changeCoverAction, resetAction, deleteAction])
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else { return }
        pickedCover(image)
        dismiss(animated: true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let vc = dismissed as? OnboardingViewController else { return nil }
        
        if(vc.shouldPresentSample()) {
            openTutorial()
        }
        
        return nil
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !isSelecting
    }

}
