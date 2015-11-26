//
//  MassiveViewController.swift
//  SocialTextStorageExample
//
//  Created by Dominik Hádl on 19/11/15.
//  Copyright © 2015 Nodes. All rights reserved.
//

import UIKit

class MassiveViewController: UIViewController {

    @IBOutlet var consoleTextView: UITextView!
    @IBOutlet var socialTextViewHolder: UIView!

    @IBOutlet var nodesImageView: UIImageView!

    @IBOutlet var socialLabel: SocialLabel!
    let socialTextView: SocialTextView = SocialTextView(frame: CGRectZero)

    @IBOutlet var timeOverlay: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        let eggRecognizer = UITapGestureRecognizer(target: self, action: "showJoke")
        eggRecognizer.numberOfTapsRequired = 4
        nodesImageView.addGestureRecognizer(eggRecognizer)

        clearConsole()
        setupSocialLabel()
        setupSocialTextView()

        let activeDate = NSDate(timeIntervalSince1970: 1448031600)
        if activeDate.timeIntervalSinceNow.isSignMinus {
            timeOverlay.hidden = true
        }
    }

    // MARK: - UI Setup -

    func setupSocialLabel() {
        socialLabel.font = UIFont.systemFontOfSize(12)
        socialLabel.textColor = UIColor.blackColor()
        socialLabel.usernames = ["Nodes"]

        let attributes = [NSFontAttributeName : UIFont.systemFontOfSize(12), NSForegroundColorAttributeName: UIColor.blackColor()]
        socialLabel.attributedText = NSAttributedString(string: "Want to develop apps at Nodes?. Ask @topprojectmanageratnodes or @kickassleaddeveloper for more info, or checkout http://www.nodes.com #ftw.", attributes: attributes)

        socialLabel.usernameHandler = { username in self.printToConsole("[Label] Username tapped: \(username)") }
        socialLabel.hashtagHandler = { hashtag in self.printToConsole("[Label] Hashtag tapped: \(hashtag)") }
        socialLabel.mentionHandler = { mention in self.printToConsole("[Label] Mention tapped: \(mention)") }
        socialLabel.linkHandler = { link in self.printToConsole("[Label] Link tapped: \(link)") }
    }

    func setupSocialTextView() {
        socialTextViewHolder.addSubview(socialTextView)
        socialTextView.translatesAutoresizingMaskIntoConstraints = false
        socialTextView.layer.cornerRadius = 2
        socialTextView.backgroundColor = UIColor(white: 0.0, alpha: 0.04)
        socialTextView.font = UIFont.systemFontOfSize(12)
        socialTextView.textColor = UIColor.blackColor()
        socialTextView.autocorrectionType = UITextAutocorrectionType.No
        socialTextView.spellCheckingType = UITextSpellCheckingType.No

        socialTextViewHolder.addConstraint(NSLayoutConstraint(item: socialTextView, attribute: .Leading, relatedBy: .Equal, toItem: socialTextViewHolder, attribute: .Leading, multiplier: 1.0, constant: 0))
        socialTextViewHolder.addConstraint(NSLayoutConstraint(item: socialTextView, attribute: .Trailing, relatedBy: .Equal, toItem: socialTextViewHolder, attribute: .Trailing, multiplier: 1.0, constant: 0))
        socialTextViewHolder.addConstraint(NSLayoutConstraint(item: socialTextView, attribute: .Top, relatedBy: .Equal, toItem: socialTextViewHolder, attribute: .Top, multiplier: 1.0, constant: 0))
        socialTextViewHolder.addConstraint(NSLayoutConstraint(item: socialTextView, attribute: .Bottom, relatedBy: .Equal, toItem: socialTextViewHolder, attribute: .Bottom, multiplier: 1.0, constant: 0))
    }

    // MARK: - Helpers -
    // MARK: Console

    let calendar = NSCalendar.currentCalendar()

    func clearConsole() {
        consoleTextView.text = ""
    }

    func printToConsole(string: String) {
        let components = calendar.components([.Hour, .Minute, .Second], fromDate: NSDate())
        let hour = components.hour
        let minutes = components.minute
        let seconds = components.second

        if consoleTextView.text.characters.count > 0 {
            consoleTextView.text = "\(hour):\(minutes):\(seconds) - " + string + "\n" + consoleTextView.text
        } else {
            consoleTextView.text = "\(hour):\(minutes):\(seconds) - " + string
        }
    }

    // MARK: - Easter Eggs -

    func showJoke() {
        let alert = UIAlertController(title: "Wild Yo Mama Joke Appeared", message: "Yo mama so stupid she went to the Apple Store to get a big mac.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Hahahaha, so funny!", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
}

