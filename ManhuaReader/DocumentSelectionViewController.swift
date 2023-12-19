//
//  EntryCreationViewController.swift
//  ManhuaReader
//
//  Created by AC on 12/15/23.
//

import UIKit
import UniformTypeIdentifiers
import ZIPFoundation

class DocumentSelectionViewController: UIViewController, UIDocumentPickerDelegate {
    
    lazy var importButton: UIButton = {
        let button = UIButton()
        button.setTitle("Import File", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(didTapImport), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemMint
        
        addSubviews()
        configureUI()
    }
    
    func addSubviews() {
        view.addSubview(importButton)
    }

    func configureUI() {
        configureImportButton()
    }
    
    func configureImportButton() {
        importButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            importButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            importButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            importButton.heightAnchor.constraint(equalToConstant: 100),
            importButton.widthAnchor.constraint(equalToConstant: 200)
        ])
    }

    @objc func didTapImport() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.zip]/*, asCopy: true*/)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        documentPicker.modalPresentationStyle = .fullScreen
        present(documentPicker, animated: true, completion: nil)
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first/*, let _ = UIImage(contentsOfFile: url.path)*/ else { return }
        
        guard url.startAccessingSecurityScopedResource() else {
            return
        }

        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        guard let archive = Archive(url: url, accessMode: .read) else {
            return
        }
        
        
        var images: [UIImage] = []
        
        let sorted = archive.sorted(by: { ($0.fileAttributes[FileAttributeKey(rawValue: "NSFileModificationDate")] as! Date).compare(($1.fileAttributes[FileAttributeKey(rawValue: "NSFileModificationDate")] as! Date)) == .orderedAscending })
        for entry in sorted {
            
            var extractedData: Data = Data([])
            
            do {
                let blah = try archive.extract(entry) { extractedData.append($0) }
                if let image = UIImage(data: extractedData) {
                    images.append(image)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        
        controller.dismiss(animated: true, completion: {
//            self.navigationController?.pushViewController(MenuViewController(), animated: true)
            self.navigationController?.pushViewController(ReaderViewController(images: images), animated: true)
//            self.navigationController?.pushViewController(CollectionViewController(collectionViewLayout: UICollectionViewFlowLayout()), animated: true)
        })
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
    }
}

