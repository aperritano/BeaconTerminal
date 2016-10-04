
//
//  SpeciesPageViewController.swift
//  BeaconTerminal
//
//  Created by Anthony Perritano on 9/9/16.
//  Copyright © 2016 aperritano@gmail.com. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift

class SpeciesPageContentController: UIViewController {
    
    var speciesIndex: Int?
    var speciesObservation: SpeciesObservation?
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var tabSegmentedControl: UISegmentedControl!
    @IBOutlet weak var speciesLabel: UILabel!
    @IBOutlet weak var speciesProfileImageView: UIImageView!
    @IBOutlet var subpageContainerViews: [UIView]!

    var speciesObservationResults: Results<SpeciesObservation>?
    var shouldSync: Results<SpeciesObservation>?

    var speciesObsNotificationToken: NotificationToken? = nil
    var syncNotificationToken: NotificationToken? = nil
    
    deinit {
        speciesObsNotificationToken?.stop()
        syncNotificationToken?.stop()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateHeader()
        prepareNotifications()
        
        switch getAppDelegate().checkApplicationState() {
            case .cloudGroup:
                prepareHeaderActions()
            default:
            break
        }

        
    }
    
   
    
    func prepareNotifications() {
        if let allSO = realm?.allSpeciesObservationsForCurrentSectionAndGroup(), let speciesIndex = speciesIndex{
            shouldSync = allSO.filter("fromSpecies.index = \(speciesIndex) AND isSynced = false")
            
            if let shouldSync = shouldSync {
                    syncNotificationToken = shouldSync.addNotificationBlock { [weak self] (changes: RealmCollectionChange) in
                
                    guard let controller = self else { return }
                    switch changes {
                    case .initial(let speciesObservationResults):
                        if !speciesObservationResults.isEmpty {
                            controller.colors(forSynced: false)
                        } else {
                            controller.colors(forSynced: true)
                        }
                        break
                    case .update( _, let deletions, _, _):
                        
                        if deletions.count > 0 {
                            controller.colors(forSynced: true)
                        } else {
                            controller.colors(forSynced: false)
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
        
    }
    
    func colors(forSynced synced: Bool) {
        if synced {
            contentView.borderColor = UIColor.speciesColor(forIndex: speciesIndex!, isLight: false)
            contentView.backgroundColor = UIColor.white
            speciesLabel.textColor = UIColor.black
        } else {
            contentView.borderColor = UIColor.red
            contentView.backgroundColor = #colorLiteral(red: 0.9994968772, green: 0.8941870332, blue: 0.962585628, alpha: 1)
            speciesLabel.textColor = UIColor.black
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let id = segue.identifier else {
            return
        }
        
        switch id {
        case "relationshipsViewSegue":
            if let srv = segue.destination as? SpeciesRelationshipContainerController {
                srv.speciesIndex = speciesIndex
            }
            break
        case "preferencesViewSegue":
            if let srv = segue.destination as? PreferencesViewController {
                
                // Fixes popover anchor centering issue in iOS 9
                if let popoverPresentationController = segue.destination.popoverPresentationController, let sourceView = sender as? UIView {
                    popoverPresentationController.sourceRect = sourceView.bounds
                }
                
                srv.speciesIndex = speciesIndex
            }
            break
        case "experimentsViewSegue":
            break
        default:
            break
        }
    }
    
    // Mark: Views
    
    func updateHeader() {
        if let speciesIndex = self.speciesIndex {
            speciesProfileImageView.image = RealmDataController.generateImageForSpecies(speciesIndex, isHighlighted: true)
            
            if let species = realm?.speciesWithIndex(withIndex: speciesIndex) {
                speciesLabel.text = species.name
            }
            contentView.borderColor = UIColor.speciesColor(forIndex: speciesIndex, isLight: false)
        } else {
            //no species image
        }
    
        //updateTimestamp()
    }
    
    func prepareHeaderActions() {
            speciesProfileImageView.isUserInteractionEnabled = true
            //now you need a tap gesture recognizer
            //note that target and action point to what happens when the action is recognized.
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(showTerminalForCurrentSpeciesAction))
            //Add the recognizer to your view.
            speciesProfileImageView.addGestureRecognizer(tapRecognizer)
    }
        
    func showTerminalForCurrentSpeciesAction(_ sender: UITapGestureRecognizer) {
            
            if let speciesIndex = self.speciesIndex {
                
                realmDataController.syncSpeciesObservations(withIndex: speciesIndex)

                realmDataController.clearInViewTerminal(withCondition: "cloud")
                realmDataController.updateInViewTerminal(withSpeciesIndex: speciesIndex, withCondition: "cloud", withPlace: "species:\(speciesIndex)")                
            }
        
    }
    
    // Mark: Actions

    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
}

