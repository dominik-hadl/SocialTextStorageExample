//
//  SocialTextView.swift
//  Tattoodo
//
//  Created by Dominik Hádl on 22/10/15.
//  Copyright © 2015 Nodes. All rights reserved.
//

import UIKit

class SocialTextView: UITextView {

    let socialTextStorage = SocialTextStorage()
    override var textStorage: NSTextStorage {
        return socialTextStorage
    }

    convenience init(frame: CGRect) {
        self.init(frame: frame, textContainer: nil)
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        var container = textContainer
        if container == nil {
            let layoutManager = NSLayoutManager()

            container = NSTextContainer(size: frame.size)
            if let container = container {
                container.widthTracksTextView = true
                layoutManager.addTextContainer(container)
            }

            socialTextStorage.addLayoutManager(layoutManager)
        }

        super.init(frame: frame, textContainer: container)
    }


    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    override dynamic var textColor: UIColor? {
        didSet {
            socialTextStorage.defaultColor = textColor
            typingAttributes[NSForegroundColorAttributeName] = textColor
        }
    }

    override dynamic var font: UIFont? {
        didSet {
            socialTextStorage.defaultFont = font
            typingAttributes[NSFontAttributeName] = font
        }
    }
}

