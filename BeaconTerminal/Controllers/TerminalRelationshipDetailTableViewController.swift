//
//  TerminalRelationshipDetailTableViewController.swift
//  BeaconTerminal
//
//  Created by Anthony Perritano on 8/6/16.
//  Copyright © 2016 aperritano@gmail.com. All rights reserved.
//

import Foundation
import UIKit

class TerminalRelationshipDetailTableViewController: UITableViewController {
    
    
    var relationship: Relationship?
    var group: Group?
    
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var ecosystemSegmentedControl: UISegmentedControl!
    @IBOutlet weak var reasoningTextView: UITextView!
    @IBOutlet weak var evidenceImageView: UIImageView!
    
    var showAlternate = false {
        didSet {
            if showAlternate {
                let cells = tableView.visibleCells
                
                for cell in cells{
                    cell.contentView.backgroundColor = UIColor.white
                }
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // Mark: View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    func prepareView() {
        if let group = self.group {
            groupNameLabel.text = group.name
        }
        
        if let relationship = self.relationship {
            if let ecosystemIndex = relationship.ecosystem?.ecosystemNumber {
                ecosystemSegmentedControl.selectedSegmentIndex = ecosystemIndex
            }
            
            if let note = relationship.note {
                reasoningTextView.text = note
            } else {
                reasoningTextView.text = "no reason"
            }
        } else {
            
        }
    }
}
