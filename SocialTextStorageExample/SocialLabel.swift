//
//  SocialLabel.swift
//  Tattoodo
//
//  Created by Dominik Hádl on 22/10/15.
//  Copyright © 2015 Nodes. All rights reserved.
//

import UIKit

class SocialLabel: UILabel {

    // MARK: - Public Closures -

    var mentionHandler: ((String) -> Void)?
    var hashtagHandler: ((String) -> Void)?
    var linkHandler: ((String) -> Void)?
    var usernameHandler: ((String) -> Void)?

    // MARK: - Private Text Properties -

    typealias SocialElement = (range: NSRange, element: String, elementType: SocialTextType)

    private let textStorage   = SocialTextStorage()
    private let textContainer = NSTextContainer()
    private let layoutManager = NSLayoutManager()

    private var selectedElement: SocialElement?

    // MARK: - Init and Setup -

    convenience init() {
        self.init(frame: CGRectZero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()

        if let attributedText = attributedText where attributedText.length > 0 {
            textStorage.setAttributedString(attributedText)
        } else if let text = text where text.characters.count > 0 {
            textStorage.setAttributedString(NSAttributedString(string: text))
        }
    }

    private func setup() {
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        textContainer.lineFragmentPadding = 0

        textStorage.highlightSettings.insert(.Username)

        let touchRecognizer = UILongPressGestureRecognizer(target: self, action: "onTouch:")
        touchRecognizer.minimumPressDuration = 0.00001
        touchRecognizer.delegate = self
        addGestureRecognizer(touchRecognizer)

        userInteractionEnabled = true
    }

    // MARK: - Property Overrides -

    override var text: String? {
        didSet {
            if let text = text where text.characters.count > 0 {
                textStorage.setAttributedString(NSAttributedString(string: text))
            }
        }
    }

    override var attributedText: NSAttributedString? {
        didSet {
            if let attributedText = attributedText where attributedText.length > 0 {
                textStorage.setAttributedString(attributedText)
            }
        }
    }

    override var textColor: UIColor? {
        didSet {
            textStorage.defaultColor = textColor
        }
    }

    override var font: UIFont? {
        didSet {
            textStorage.defaultFont = font
        }
    }

    var contentInsets: UIEdgeInsets = UIEdgeInsetsZero

    var usernames = [String]() {
        didSet {
            textStorage.usernames = usernames
        }
    }

    var showsUsernames = true {
        didSet {
            if showsUsernames {
                textStorage.highlightSettings.insert(.Username)
            } else {
                textStorage.highlightSettings.remove(.Username)
            }
        }
    }

    // MARK: - Drawing -

    override func drawTextInRect(rect: CGRect) {
        let range = textStorage.stringRange

        let insetRect = UIEdgeInsetsInsetRect(rect, contentInsets)
        textContainer.size = insetRect.size

        layoutManager.drawBackgroundForGlyphRange(range, atPoint: insetRect.origin)
        layoutManager.drawGlyphsForGlyphRange(range, atPoint: insetRect.origin)
    }

    override func sizeThatFits(size: CGSize) -> CGSize {
        let currentSize = textContainer.size
        defer {
            textContainer.size = currentSize
        }

        textContainer.size = size
        var size = layoutManager.usedRectForTextContainer(textContainer).size
        size.width += contentInsets.left + contentInsets.right
        size.height += contentInsets.top + contentInsets.bottom
        return size
    }

    func heightWithWidth(width: CGFloat) -> CGFloat {
        return sizeThatFits(CGSizeMake(width, CGFloat.max)).height
    }

    // MARK: - Touch Handling -

    func onTouch(gesture: UILongPressGestureRecognizer) {
        let location = gesture.locationInView(self)

        switch gesture.state {

        case .Began, .Changed:
            if let element = elementAtLocation(location) {
                if element.range.location != selectedElement?.range.location || element.range.length != selectedElement?.range.length {
                    selectedElement = element
                }
            } else {
                selectedElement = nil
            }

        case .Cancelled, .Ended:
            guard let selectedElement = selectedElement else { return }

            switch selectedElement.2 {
            case .Mention: mentionHandler?(selectedElement.1)
            case .Hashtag: hashtagHandler?(selectedElement.1)
            case .URL: linkHandler?(selectedElement.1)
            case .Username: usernameHandler?(selectedElement.1)
            }

            let when = dispatch_time(DISPATCH_TIME_NOW, Int64(0.25 * Double(NSEC_PER_SEC)))
            dispatch_after(when, dispatch_get_main_queue()) { self.selectedElement = nil }

        default: break
        }
    }

    private func elementAtLocation(location: CGPoint) -> SocialElement? {
        guard textStorage.length > 0 else {
            return nil
        }

        let boundingRect = layoutManager.boundingRectForGlyphRange(NSRange(location: 0, length: textStorage.length), inTextContainer: textContainer)
        guard boundingRect.contains(location) else {
            return nil
        }

        let index = layoutManager.glyphIndexForPoint(location, inTextContainer: textContainer)

        if let usernames = textStorage.socialElements[.Username] {
            for (range, value) in usernames {
                if index >= range.location && index <= range.location + range.length {
                    return (range, value, .Username)
                }
            }
        }

        if let mentions = textStorage.socialElements[.Mention] {
            for (range, value) in mentions {
                if index >= range.location && index <= range.location + range.length {
                    return (range, value, .Mention)
                }
            }
        }

        if let hashtags = textStorage.socialElements[.Hashtag] {
            for (range, value) in hashtags {
                if index >= range.location && index <= range.location + range.length {
                    return (range, value, .Hashtag)
                }
            }
        }

        if let urls = textStorage.socialElements[.URL] {
            for (range, value) in urls {
                if index >= range.location && index <= range.location + range.length {
                    return (range, value, .URL)
                }
            }
        }

        return nil
    }
}

extension SocialLabel: UIGestureRecognizerDelegate {

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOfGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
