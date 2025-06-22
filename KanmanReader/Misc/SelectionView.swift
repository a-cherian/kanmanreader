//
//  SelectionView.swift
//  KanmanReader
//
//  Created by AC on 6/12/25.
//

import UIKit

class Selection: UIView {
    private var offset: CGPoint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .clear
        isOpaque = true
        contentMode = .redraw
        setNeedsDisplay()
        addGestures()
    }
    
    private func addGestures() {
        
    }
    
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath()
        let margin: CGFloat = 0;
        path.move(to: CGPoint(x: margin, y: margin))
        path.addLine(to: CGPoint(x: rect.width - margin, y: margin))
        path.addLine(to: CGPoint(x: rect.width - margin, y: rect.height - margin))
        path.addLine(to: CGPoint(x: margin, y: rect.height - margin))
        path.close()
        UIColor.red.setStroke()
        path.lineWidth = 4;
        path.stroke()
    }
}
