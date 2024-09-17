//
//  Appearance.swift
//  KanmanReader
//
//  Created by AC on 9/13/24.
//

import UIKit

func configureNavbarAppearance() {
    let navbar = UINavigationBar.appearance()
    navbar.barTintColor = .black
    navbar.backgroundColor = .black
    navbar.tintColor = Constants.accentColor
    navbar.isTranslucent = false
}

func configureToolbarAppearance() {
    let toolbar = UIToolbar.appearance()
    toolbar.barTintColor = .black
    toolbar.backgroundColor = .black
    toolbar.tintColor = Constants.accentColor
    toolbar.isTranslucent = true
}

func resetNavbarAppearance() {
    let navbar = UINavigationBar.appearance()
    navbar.barTintColor = nil
    navbar.backgroundColor = nil
    navbar.tintColor = nil
    navbar.isTranslucent = true
}

func resetToolbarAppearance() {
    let toolbar = UIToolbar.appearance()
    toolbar.barTintColor = nil
    toolbar.backgroundColor = nil
    toolbar.tintColor = nil
    toolbar.isTranslucent = true
}
