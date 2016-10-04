//
//  PreferenceTableViewController.swift
//  BeaconTerminal
//
//  Created by Anthony Perritano on 8/6/16.
//  Copyright © 2016 aperritano@gmail.com. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift

class TerminalPreferenceComparsionDetailController: UITableViewController {
    
    var speciesIndex: Int?
    var groupIndex: Int?
    
    var speciesObservation: SpeciesObservation?
    
    var speciesObservations: Results<SpeciesObservation>?
    
    var header: String?

    var speciesObsNotificationToken: NotificationToken? = nil

    
    @IBOutlet weak var headerLabel: UILabel!
    
    
    deinit {
        if let sp = self.speciesObsNotificationToken {
            sp.stop()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareNotification()
        
        if let groupIndex = self.groupIndex {
            headerLabel.text = "Group \(groupIndex)"
        }

    }

    func prepareNotification() {
        
        if let fromSpeciesIndex = self.speciesIndex, let sectionName = realmDataController.getRealm().runtimeSectionName(), let groupIndex = self.groupIndex {
            
            speciesObservations = realmDataController.getRealm().speciesObservations(withSectionName: sectionName, withGroupIndex: groupIndex, withSpeciesIndex: fromSpeciesIndex)
            
            speciesObsNotificationToken = speciesObservations?.addNotificationBlock { [weak self] (changes: RealmCollectionChange) in
                
                guard let controller = self else { return }
                switch changes {
                case .initial(let speciesObservationResults):
                    if let so = speciesObservationResults.first {
                        controller.update(speciesObservation: so)
                    }
                    break
                case .update(let speciesObservationResults, _, _, _):
                    if let so = speciesObservationResults.first {
                        controller.update(speciesObservation: so)
                    }
                    break
                case .error(let error):
                    // An error occurred while opening the Realm file on the background worker thread
                    fatalError("\(error)")
                    break
                }
                
            }
        }
    }
    
    func update(speciesObservation: SpeciesObservation) {
        self.speciesObservation = speciesObservation
        tableView.reloadData()
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = super.tableView(tableView, cellForRowAt: indexPath) as? PreferenceTableViewCell {
            if let preferenceType = cell.preferenceType, let preferences = speciesObservation?.preferences {
                
                let foundPreferences = preferences.filter("type = '\(preferenceType)'")
                
                if !foundPreferences.isEmpty {
                    let preference = foundPreferences[0]
                    
                    if cell.textLabel?.text == preference.value {
                        cell.accessoryType = .checkmark
                    } else {
                        cell.accessoryType = .none
                    }
                }
                
                return cell
            }
        }
        
        return PreferenceTableViewCell()
    }
    
    
    /// Select item at row in tableView.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        
        let numberOfRows = tableView.numberOfRows(inSection: section)
        
        for row in 0..<numberOfRows {
            let cell =  tableView.cellForRow(at: IndexPath(row: row, section: section))
            if cell != nil {
                cell?.accessoryType = row == indexPath.row ? .checkmark : .none
            }
        }
        
        if let cell = tableView.cellForRow(at: indexPath) as? PreferenceTableViewCell {
            if let preferenceType = cell.preferenceType, let so = speciesObservation, let preferences = speciesObservation?.preferences {
                
                let foundPreferences = preferences.filter("type = '\(preferenceType)'")
                
                if foundPreferences.count > 0 {
                    if let preference = foundPreferences.first {
                        
                        let r = realmDataController.getRealm()
                        
                        try! r.write {
                            preference.type = cell.preferenceType!
                            preference.value = cell.textLabel?.text
                            preference.lastModified = NSDate() as Date
                            r.add(preference, update: true)
                            
                            so.isSynced.value = false
                            r.add(so, update: true)
                            
                        }
                    }
                }
            }
            
        }

    }
    
}

