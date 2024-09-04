//
//  EntryCreationViewController.swift
//  KanshuReader
//
//  Created by AC on 12/15/23.
//

import UIKit
import UniformTypeIdentifiers

class DocumentSelectionViewController: UIViewController, ComicCellDelegate, UIViewControllerTransitioningDelegate {
    
    var comics: [Comic] = []
    var selectedComic: Comic? = nil
    
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
        comics = BookmarkManager.retrieveComics()
        documentCollectionView.reloadData()
        
        emptyLabel.isHidden = comics.count > 0 && !(comics.count == 1 && comics[0].isTutorial)
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

    @objc func didTapImport() {
        importButton.animateBackgroundFlash()
        
        let fileTypes: [UTType] = [.zip, UTType(filenameExtension: "rar"), UTType(importedAs: "com.acherian.cbz"), UTType(importedAs: "com.acherian.cbr")].compactMap { $0 }
        
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: fileTypes, asCopy: false)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        documentPicker.modalPresentationStyle = .fullScreen
        present(documentPicker, animated: true, completion: nil)
    }
    
    func didTapComic(position: Int) {
        let comic = comics[position]
        openComic(comic)
    }
    
    func openComic(_ comic: Comic) {
        if let url = comic.url {
            comic.lastOpened = Date()
            CoreDataManager.shared.updateComic(comic: comic)
            let images = BookmarkManager.getImages(for: url)?.images ?? []
            self.navigationController?.pushViewController(ReaderViewController(images: images, comic: comic), animated: true)
        }
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
    
    func deleteAction(_ comic: Comic) {
        let alert = UIAlertController(
            title: "Confirm deletion",
            message: "This will delete this comic. This action is irreversible. Do you wish to proceed?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: "Delete",
            style: .destructive,
            handler: { _ in
                CoreDataManager.shared.deleteComic(comic: comic)
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
    
    func changeCover(_ comic: Comic) {
        selectedComic = comic
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }
    
    func pickedCover(_ image: UIImage) {
        selectedComic?.cover = image.pngData()
        CoreDataManager.shared.updateComic(comic: selectedComic)
        refreshData()
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






extension DocumentSelectionViewController: UIDocumentPickerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let comics = urls.compactMap { url in
            return BookmarkManager.createComic(from: url)
        }
        
        if(urls.count == 1 && comics.count == 1) {
            controller.dismiss(animated: true, completion: {
                self.openComic(comics[0])
            })
        }
        
        refreshData()
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return comics.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let comic = comics[indexPath.item]
        
        let cell = documentCollectionView.dequeueReusableCell(withReuseIdentifier: ComicCell.identifier, for: indexPath) as! ComicCell
        cell.tag = indexPath.item
        cell.delegate = self
        
        cell.title.text = comic.name
        cell.progress.text = "Pages: " + String(comic.lastPage + 1) + " / " + String(comic.totalPages)
        
        cell.coverView.image = UIImage(data: comic.cover ?? Data()) ?? UIImage()
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                         contextMenuConfigurationForItemAt indexPath: IndexPath,
                         point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            let comic = self.comics[indexPath.item]
            
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
            guard let tutorial = CoreDataManager.shared.fetchComic(name: "Sample Tutorial") ?? BookmarkManager.createTutorial() else { return nil }
            openComic(tutorial)
        }
        
        return nil
    }
}
