//
//  SocialTextStorage.swift
//  Tattoodo
//
//  Created by Dominik Hádl on 22/10/15.
//  Copyright © 2015 Nodes. All rights reserved.
//

import UIKit

enum SocialTextType {
    case Mention
    case Hashtag
    case URL
    case Username
}

struct SocialTextHighlightSettings: OptionSetType {
    let rawValue: Int

    static let Mention = SocialTextHighlightSettings(rawValue: 1 << 0)
    static let Hashtag = SocialTextHighlightSettings(rawValue: 1 << 1)
    static let URL     = SocialTextHighlightSettings(rawValue: 1 << 2)
    static let Username = SocialTextHighlightSettings(rawValue: 1 << 3)
}

class SocialTextStorage: NSTextStorage {

    typealias HighlightAttributes = [SocialTextType : [String : AnyObject]]
    var highlightAttributes: HighlightAttributes
    var highlightSettings: SocialTextHighlightSettings = [.Mention, .Hashtag, .URL]

    var defaultColor: UIColor?
    var defaultFont: UIFont?

    private var usernameRegexes = [NSRegularExpression]()
    var usernames = [String]() {
        didSet {
            var regexes = [NSRegularExpression]()

            if usernames.count > 0 {
                for username in usernames {
                    do {
                        let regex = try NSRegularExpression(pattern: "((?<!=@)(\(username)))", options: NSRegularExpressionOptions(rawValue: 0))
                        regexes.append(regex)
                    } catch { fatalError("Couldn't create username (\(username)) regex.") }
                }
            }

            usernameRegexes = regexes
        }
    }

    var socialElements: [SocialTextType : [(range: NSRange, element: String)]] = [
        .Mention: [],
        .Hashtag: [],
        .URL: [],
        .Username: []
    ]

    var stringRange: NSRange {
        return NSMakeRange(0, backingStore.length)
    }

    private let backingStore = NSMutableAttributedString()

    private static var mentionRegex: NSRegularExpression {
        do {
            let regex = try NSRegularExpression(pattern: "(^@([a-zA-Z0-9._-])+)|((?<=\\s)(@([a-zA-Z0-9._-])+))", options: NSRegularExpressionOptions(rawValue: 0))
            return regex
        } catch { fatalError("Couldn't create mention regex.") }
    }

    private static var hashtagRegex: NSRegularExpression {
        do {
            let regex = try NSRegularExpression(pattern: "#([a-zA-Z0-9._-])+", options: NSRegularExpressionOptions(rawValue: 0))
            return regex
        } catch { fatalError("Couldn't create hashtag regex.") }
    }

    private static var urlRegex: NSRegularExpression {
        do {
            let regex = try NSRegularExpression(pattern: "(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+",
                options: NSRegularExpressionOptions(rawValue: 0))
            return regex
        } catch { fatalError("Couldn't create URL regex.") }
    }

    override convenience init() {
        self.init(highlightAttributes: nil)
    }

    init(highlightAttributes: HighlightAttributes?) {
        self.highlightAttributes = highlightAttributes ?? SocialTextStorage.defaultHighlightAttributes()
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class func defaultHighlightAttributes() -> HighlightAttributes {
        return [
            .Mention : [NSForegroundColorAttributeName : UIColor.redColor(), NSFontAttributeName : UIFont.systemFontOfSize(12)],
            .Hashtag : [NSForegroundColorAttributeName : UIColor.greenColor(), NSFontAttributeName : UIFont.systemFontOfSize(12)],
            .URL : [NSForegroundColorAttributeName : UIColor.blueColor(), NSFontAttributeName : UIFont.systemFontOfSize(12)],
            .Username : [NSForegroundColorAttributeName : UIColor.purpleColor(), NSFontAttributeName : UIFont.boldSystemFontOfSize(12)]
        ]
    }

    override var string: String {
        return backingStore.string
    }

    override func attributesAtIndex(location: Int, effectiveRange range: NSRangePointer) -> [String : AnyObject] {
        return backingStore.attributesAtIndex(location, effectiveRange: range)
    }

    override func replaceCharactersInRange(range: NSRange, withString str: String) {
        beginEditing()
        backingStore.replaceCharactersInRange(range, withString: str)
        edited(.EditedCharacters, range: range, changeInLength: str.utf16.count - range.length)
        endEditing()
    }

    override func setAttributes(attrs: [String : AnyObject]?, range: NSRange) {
        beginEditing()
        backingStore.setAttributes(attrs, range: range)
        backingStore.fixAttributesInRange(range)
        edited(.EditedAttributes, range: range, changeInLength: 0)
        endEditing()
    }

    override func processEditing() {
        super.processEditing()

        let string = self.string as NSString
        let paragraphRange = string.paragraphRangeForRange(NSMakeRange(0, backingStore.length))

        if let defaultColor = defaultColor {
            removeAttribute(NSForegroundColorAttributeName, range:paragraphRange)
            addAttribute(NSForegroundColorAttributeName, value: defaultColor, range: paragraphRange)
        }

        if let defaultFont = defaultFont {
            removeAttribute(NSFontAttributeName, range: paragraphRange)
            addAttribute(NSFontAttributeName, value: defaultFont, range: paragraphRange)
        }

        // Remove all elements
        for (type, _) in socialElements {
            socialElements[type]?.removeAll()
        }

        // Check for mentions if enabled
        if highlightSettings.contains(.Mention), let attributes = highlightAttributes[.Mention] {
            SocialTextStorage.mentionRegex.enumerateMatchesInString(
                string as String,
                options: NSMatchingOptions(rawValue: 0),
                range: paragraphRange,
                usingBlock: { (result, flags, stop) -> Void in
                    if let result = result {
                        self.addAttributes(attributes, range: result.range)
                        self.socialElements[.Mention]?.append((result.range, string.substringWithRange(result.range)))
                    }
            })
        }

        // Check for hashtags if enabled
        if highlightSettings.contains(.Hashtag), let attributes = highlightAttributes[.Hashtag] {
            SocialTextStorage.hashtagRegex.enumerateMatchesInString(
                string as String,
                options: NSMatchingOptions(rawValue: 0),
                range: paragraphRange,
                usingBlock: { (result, flags, stop) -> Void in
                    if let result = result {
                        self.addAttributes(attributes, range: result.range)
                        self.socialElements[.Hashtag]?.append((result.range, string.substringWithRange(result.range)))
                    }
            })
        }

        // Check for URLs if enabled
        if highlightSettings.contains(.URL), let attributes = highlightAttributes[.URL] {
            SocialTextStorage.urlRegex.enumerateMatchesInString(
                string as String,
                options: NSMatchingOptions(rawValue: 0),
                range: paragraphRange,
                usingBlock: { (result, flags, stop) -> Void in
                    if let result = result {
                        self.addAttributes(attributes, range: result.range)
                        self.socialElements[.URL]?.append((result.range, string.substringWithRange(result.range)))
                    }
            })
        }

        // If usernames should be colored
        if (highlightSettings.contains(.Username) && usernameRegexes.count > 0), let attributes = highlightAttributes[.Username] {
            for usernameRegex in usernameRegexes {
                usernameRegex.enumerateMatchesInString(
                    string as String,
                    options: NSMatchingOptions(rawValue: 0),
                    range: paragraphRange,
                    usingBlock: { (result, flags, stop) -> Void in
                        if let result = result {
                            self.addAttributes(attributes, range: result.range)
                            self.socialElements[.Username]?.append((result.range, string.substringWithRange(result.range)))
                        }
                })
            }
        }

        backingStore.fixAttributesInRange(paragraphRange)

        // HACK, ewww
        // Fix emoji font size
        self.backingStore.enumerateAttribute(NSFontAttributeName, inRange: paragraphRange,
            options: NSAttributedStringEnumerationOptions(rawValue: 0)) { (font, range, stop) -> Void in
            if let font = font as? UIFont where font.familyName == "Apple Color Emoji" {
                var size: CGFloat = 10
                if let defaultFont = self.defaultFont {
                    size = defaultFont.pointSize * 0.8
                }

                self.addAttribute(NSFontAttributeName, value: UIFont(name: "AppleColorEmoji", size: size)!, range: range)
            }
        }
    }
}
