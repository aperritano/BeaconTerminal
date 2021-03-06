//
//  RealmDataController.swift
//  BeaconTerminal
//
//  Created by Anthony Perritano on 6/13/16.
//  Copyright © 2016 aperritano@gmail.com. All rights reserved.
//

import Foundation
import RealmSwift
import Nutella

class RealmDataController {
    
    init() {
    }
    
    
    func getRealm(withRealmType realmType: RealmType? = nil) -> Realm {
        if let rt = realmType {
            switch rt {
            case .terminalDB:
                return terminalRealm!
            default:
                return realm!
            }
        } else {
            switch getAppDelegate().checkApplicationState() {
            case .placeTerminal:
                return terminalRealm!
            default:
                return realm!
            }
        }
    }
    
    
    // MARK: Group
    
    static func exportJson(withSpeciesObservation speciesObservation: SpeciesObservation, group: Group) -> String {
        
        let speciesObsJSON = JSON(speciesObservation.toDictionary())
        if let string = speciesObsJSON.rawString() {
            return string
        }
        
        return ""
    }
    
    // MARK: inviewTerminal actions
    
    func clearInViewTerminal(withCondition condition: String) {
        if let oldSpeciesIndex = realmDataController.getRealm(withRealmType: RealmType.terminalDB).runtimeSpeciesIndex(),let groupIndex = realmDataController.getRealm().runtimeGroupIndex() {
            realmDataController.saveNutellaCondition(withCondition: condition, withActionType: "exit", withGroupIndex: groupIndex, withSpeciesIndex: oldSpeciesIndex)
            
            realmDataController.deleteAllSpeciesObservations(withRealmType: RealmType.terminalDB)
            
            //clear the terminal if needed
            realmDataController.updateRuntime(withSpeciesIndex: Int(oldSpeciesIndex), withRealmType: RealmType.terminalDB, withAction: ActionType.exited.rawValue)
            
        }
    }
    
    func updateInViewTerminal(withSpeciesIndex speciesIndex: Int, withCondition condition: String, withPlace place: String) {
        realmDataController.updateRuntime(withSpeciesIndex: speciesIndex, withRealmType: RealmType.terminalDB, withAction: ActionType.entered.rawValue)
        
        if let groupIndex = realmDataController.getRealm().runtimeGroupIndex() {
            realmDataController.saveNutellaCondition(withCondition: condition, withActionType: "enter", withPlace: place, withGroupIndex: groupIndex, withSpeciesIndex: speciesIndex)
        }
    }
    
    // MARK: Nutella Queries
    
    func forceSync(withIndex index: Int) {
        if let nutella = nutella {
            let block = DispatchWorkItem {
                var json: JSON =  ["groupIndex": index]
                let jsonObject: Any = json.object
                nutella.net.publish("forceSync", message: jsonObject as AnyObject)
            }
            
            DispatchQueue.main.async(execute: block)
        }
    }
    
    func saveNutellaCondition(withCondition condition: String, withActionType type: String,  withPlace place: String = "", withGroupIndex groupIndex: Int, withSpeciesIndex speciesIndex: Int, withRealmType realmType: RealmType = RealmType.defaultDB) {
        
        if let nutella = nutella {
            let block = DispatchWorkItem {
                var json: JSON =  ["condition": condition, "type": type, "place": place, "groupIndex":groupIndex, "speciesIndex":speciesIndex, "timestamp": Date().timeIntervalSince1970]
                let jsonObject: Any = json.object
                nutella.net.asyncRequest("save_place", message: jsonObject as AnyObject, requestName: "save_place")
            }
            
            DispatchQueue.main.async(execute: block)
        }
    }
    
    // MARK: Refresh experiments
    
    func fetchExperiments() {
        self.queryNutella(withType: .getExperiments)
    }
    
    // MARK: General Nutella queries
    
    func queryNutella(withType type: NutellaQueryType) {
        switch type {
        case .currentRun:
            if let nutella = nutella {
                let block = DispatchWorkItem {
                    
                    var dict = [String:String]()
                    dict[""] = ""
                    let json = JSON(dict)
                    let jsonObject: Any = json.object
                    nutella.net.asyncRequest("get_current_run", message: jsonObject as AnyObject, requestName: "get_current_run")
                }
                
                DispatchQueue.main.async(execute: block)
            }
        case .speciesNames:
            if let nutella = nutella {
                let block = DispatchWorkItem {
                    
                    var dict = [String:String]()
                    dict[""] = ""
                    let json = JSON(dict)
                    let jsonObject: Any = json.object
                    nutella.net.asyncRequest("get_species_names", message: jsonObject as AnyObject, requestName: "get_species_names")
                }
                
                DispatchQueue.main.async(execute: block)
            }
        case .currentRoster:
            if let nutella = nutella {
                let block = DispatchWorkItem {
                    
                    var dict = [String:String]()
                    dict[""] = ""
                    let json = JSON(dict)
                    let jsonObject: Any = json.object
                    nutella.net.asyncRequest("roster", message: jsonObject as AnyObject, requestName: "roster")
                }
                
                DispatchQueue.main.async(execute: block)
            }
        case .currentChannelList:
            if let nutella = nutella, let activity = UserDefaults.standard.value(forKey: "activity") as? String {
                let block = DispatchWorkItem {
                    
                    var dict = [String:String]()
                    dict["activity"] = activity
                    dict["type"] = "group"
                    let json = JSON(dict)
                    let jsonObject: Any = json.object
                    nutella.net.asyncRequest("channel_list", message: jsonObject as AnyObject, requestName: "channel_list")
                }
                
                DispatchQueue.main.async(execute: block)
            }
        case .currentChannelNames:
            if let nutella = nutella {
                let block = DispatchWorkItem {
                    
                    var dict = [String:String]()
                    dict[""] = ""
                    let json = JSON(dict)
                    let jsonObject: Any = json.object
                    nutella.net.asyncRequest("channel_names", message: jsonObject as AnyObject, requestName: "channel_names")
                }
                DispatchQueue.main.async(execute: block)
            }
        case .currentActivityAndRoom:
            if let nutella = nutella {
                let block = DispatchWorkItem {
                    
                    var dict = [String:String]()
                    dict[""] = ""
                    let json = JSON(dict)
                    let jsonObject: Any = json.object
                    nutella.net.asyncRequest("currentActivityAndRoom", message: jsonObject as AnyObject, requestName: "currentActivityAndRoom")
                }
                
                DispatchQueue.main.async(execute: block)
            }
        case .getExperiments:
            if let nutella = nutella, let groupIndex = getRealm().runtimeGroupIndex()  {
                let block = DispatchWorkItem {
                    var json: JSON =  [groupIndex]
                    let jsonObject: Any = json.object
                    nutella.net.asyncRequest("get_experiments", message: jsonObject as AnyObject, requestName: "get_experiments")
                }
                
                DispatchQueue.main.async(execute: block)
            }
        case .getAllExperiments:
            if let nutella = nutella {
                let block = DispatchWorkItem {
                    var dict = [String:String]()
                    dict[""] = ""
                    let json = JSON(dict)
                    let jsonObject: Any = json.object
                    nutella.net.asyncRequest("get_all_experiments", message: jsonObject as AnyObject, requestName: "get_all_experiments")
                }
                
                DispatchQueue.main.async(execute: block)
            }
            //        case .questions:
            //            if let nutella = nutella {
            //                let block = DispatchWorkItem {
            //
            //                    var dict = [String:String]()
            //                    dict[""] = ""
            //                    let json = JSON(dict)
            //                    let jsonObject: Any = json.object
            //                    nutella.net.asyncRequest("get_questions", message: jsonObject as AnyObject, requestName: "get_questions")
            //                }
            //
            //                DispatchQueue.main.async(execute: block)
            //            }
            
        default:
            break
        }
    }
    // MARK: Nutella Queries
    
    func queryNutellaAllNotes(withType type: NutellaQueryType, withRealmType realmType: RealmType = RealmType.defaultDB) {
        switch type {
        case .group:
            if let index = getRealm(withRealmType: realmType).runtimeGroupIndex() {
                if let nutella = nutella {
                    let block = DispatchWorkItem {
                        
                        var dict = [String:Int]()
                        dict["groupIndex"] = index
                        let json = JSON(dict)
                        let jsonObject: Any = json.object
                        nutella.net.asyncRequest("all_notes_with_group", message: jsonObject as AnyObject, requestName: "all_notes_with_group")
                    }
                    
                    DispatchQueue.main.async(execute: block)
                }
            }
        case .species:
            if let index = getRealm(withRealmType: realmType).runtimeSpeciesIndex() {
                if let nutella = nutella {
                    let block = DispatchWorkItem {
                        
                        var dict = [String:Int]()
                        dict["speciesIndex"] = index
                        let json = JSON(dict)
                        let jsonObject: Any = json.object
                        nutella.net.asyncRequest("all_notes_with_species", message: jsonObject as AnyObject, requestName: "all_notes_with_species")
                    }
                    
                    DispatchQueue.main.async(execute: block)
                }
            }
        default:
            break
        }
    }
    
    // MARK: Sync Observations
    
    func syncSpeciesObservations(withSpeciesIndex speciesIndex: Int, withCondition condition: String, withActionType actionType: String, withPlace place: String, withRealmType realmType: RealmType = RealmType.defaultDB) {
        if let groupIndex = realmDataController.getRealm().runtimeGroupIndex(), let found = getRealm(withRealmType: realmType).speciesObservationCurrentSectionGroup(withFromSpeciesIndex: speciesIndex), let synced = found.isSynced.value {
            
            if synced == false {
                exportSpeciesObservation(speciesObservation: found)
            }
            
            realmDataController.saveNutellaCondition(withCondition: condition, withActionType: actionType, withPlace: place, withGroupIndex: groupIndex, withSpeciesIndex: speciesIndex)
        }
    }
    
    
    // MARK: Nutella updates
    
    func processNutellaUpdate(nutellaUpdate: NutellaUpdate) {
        //what condition are we in?
        guard let message = nutellaUpdate.message else {
            // need a message
            return
        }
        guard let channel = nutellaUpdate.channel else {
            // need a channel
            return
        }
        
        
        if let precheckChannel = NutellaChannelType(rawValue: channel) {
            switch precheckChannel {
            case .getCurrentRun:
                let sectionName = message as! String
                UserDefaults.standard.set(sectionName, forKey: "sectionName")
                UserDefaults.standard.synchronize()
                getAppDelegate().changeLoginStateTo(.currentSection)
                return
                
            case .getRoster:
                if let roster = handleRoster(withMessage: message) {
                    UserDefaults.standard.set(roster, forKey: "currentRoster")
                    UserDefaults.standard.synchronize()
                    getAppDelegate().changeLoginStateTo(.currentRoster)
                }
                return
            case .currentActivityAndRoom:
                let currentActivityAndRoom = handleCurrentActivity(withMessage: message)
                
                if let activity = currentActivityAndRoom.activity, let room = currentActivityAndRoom.room {
                    UserDefaults.standard.set(activity, forKey: "activity")
                    UserDefaults.standard.set(room, forKey: "room")
                    UserDefaults.standard.synchronize()
                    getAppDelegate().changeLoginStateTo(.currentChannelList)
                }
                return
            case .channelList:
                let channelList = handleChannelList(withMessage: message)
                UserDefaults.standard.set(channelList, forKey: "channelList")
                UserDefaults.standard.synchronize()
                return
            case .channelNames:
                let channelNames = handleChannelNames(withMessage: message)
                UserDefaults.standard.set(channelNames, forKey: "channelNames")
                UserDefaults.standard.synchronize()
                
                for c in channelNames {
                    
                    if let id = c["id"],
                        let name = c["name"], let channel = getRealm().channel(withId: id) {
                        try! getRealm().write {
                            channel.name = name
                            getRealm().add(channel, update: true)                            
                        }
                    }
                }
                
                return
            case .getExperiments:
                handleExperiments(withMessage: message)
            case .getAllExperiments:
                handleAllExperiments(withMessage: message)
            case .speciesNames:
                parseModelSpeciesNames(withMessage: message)
                return
            default: break
            }
        }
        
        
        switch getAppDelegate().checkApplicationState() {
            
        case .placeTerminal:
            handlePlaceTerminalMessages(withMessage: message, withChannel: channel)
            break
        case .placeGroup:
            handlePlaceGroupMessages(withMessage: message, withChannel: channel)
            break
        case .objectGroup,.cloudGroup:
            handleObjectGroupMessages(withMessage: message, withChannel: channel)
            break
        default:
            break
        }
    }
    
    // MARK: Experiments
    
    func handleAllExperiments(withMessage message: Any) {
        let json = JSON(message)
        guard let ecosystems = json["experiments"].array else {
            return
        }
        
        
        
        //for each ecosystem
        for (_,ecosystem) in ecosystems.enumerated() {
            
            //for each investigation/experiment
            
            if let experiments = ecosystem.array {
                
                for(_, experiment) in experiments.enumerated()  {
                    
                    if let versions = experiment.array {
                        
                        if let lastVersion = versions.last {
                            createExperiment(withJSON: lastVersion)

                        }
                    }
                    
                }
                
                
            }
            
            
        }
        
    }
    
    
    func handleExperiments(withMessage message: Any) {
        let json = JSON(message)
        guard let all = json.array else {
            return
        }
        
        
        
        for (_,item) in all.enumerated() {
            
            createExperiment(withJSON: item)
        }
        
        
    }
    
    func createExperiment(withJSON item: JSON) {
        try! getRealm().write {
            
            let experiment = Experiment()
            
            //strings
            if let conclusions = item["conclusions"].string {
                experiment.conclusions = conclusions
            }
            
            if let manipulations = item["manipulations"].string {
                experiment.manipulations = manipulations
            }
            
            if let question = item["question"].string {
                experiment.question = question
            }
            
            if let reasoning = item["reasoning"].string {
                experiment.reasoning = reasoning
            }
            
            if let results = item["results"].string {
                experiment.results = results
            }
            
            if let ecosystemIndex = item["ecosystem"].int, let ecosystem = getRealm().ecosystem(withIndex: ecosystemIndex) {
                experiment.ecosystem = ecosystem
            } else if let ecosystemIndex = item["ecosystem"].string, let ecosystem = getRealm().ecosystem(withIndex: Int(ecosystemIndex)!) {
                experiment.ecosystem = ecosystem
            }
            
            if let figures = item["figures"].array {
                
                var attachments = [String]()
                
                for(_,figure) in figures.enumerated() {
                    
                    if let attachment = figure.string {
                        attachments.append(attachment)
                    }
                }
                
                experiment.attachments = attachments.joined(separator: ",")
            }
            
            if let index = experiment.ecosystem?.index, let question = experiment.question {
                let id = "\(index)-\(question)"
                experiment.id = id
            }
            getRealm().add(experiment, update: true)
        }
        
    }
    
    
    func handleChannelNames(withMessage message: Any) -> [[String:String]] {
        var allChannelNames = [[String:String]]()
        
        let json = JSON(message)
        guard let all = json.array else {
            //no speciesIndex
            return allChannelNames
        }
        
        for (_,item) in all.enumerated() {
            
            var channel = [String:String]()
            
            if let name = item["name"].string {
                channel["id"] = name
            }
            
            if let pName = item["printName"].string {
                channel["name"] = pName
            }
            
            allChannelNames.append(channel)
        }
        
        
        return allChannelNames
    }
    
    //src="http://ltg.evl.uic.edu:57880/wallcology/6BM/runs/species-notes/index.html?broker=ltg.evl.uic.edu&app_id=wallcology&run_id=6BM&TYPE=group&INSTANCE=2"
    func handleChannelList(withMessage message: Any) -> [[String:String]] {
        
        //
        
        
        var allChannels = [[String:String]]()
        //var channels = [String:String]()
        
        let json = JSON(message)
        guard let all = json.array else {
            //no speciesIndex
            return allChannels
            
        }
        
        
        for (_,item) in all.enumerated() {
            
            if let name = item.string, name != "classaccount" {
                
                var channel = [String:String]()
                
                channel["name"] = name
                
                if let sectionName = UserDefaults.standard.value(forKey: "sectionName") as? String, let groupIndex = UserDefaults.standard.value(forKey: "groupIndex") as? Int {
                    
                    
                    let channelUrl = "http://\(CURRENT_HOST):57880/wallcology/\(sectionName)/runs/\(name)/index.html?broker=\(CURRENT_HOST)&app_id=wallcology&run_id=\(sectionName)&TYPE=group&INSTANCE=\(groupIndex)"
                    
                    channel["url"] = channelUrl
                    
                }
                
                allChannels.append(channel)
            }
        }
        
        
        return allChannels
    }
    
    func handleCurrentActivity(withMessage message: Any) -> (activity: String?, room: String?) {
        
        let json = JSON(message)
        var activity: String?
        var room: String?
        
        if let a = json["activity"].string {
            activity = a
        }
        
        if let b = json["room"].string {
            room = b
        }
        
        return (activity: activity, room: room)
        
    }
    
    func handleRoster(withMessage message: Any) -> [String]? {
        
        let json = JSON(message)
        guard let all = json.array else {
            //no speciesIndex
            return nil
        }
        
        
        for (_,item) in all.enumerated() {
            
            if let type = item["type"].string {
                
                if type == "group" {
                    
                    let groups = item["printNames"].arrayValue.map({$0.stringValue})
                    return groups
                }
                
            }
        }
        
        
        return nil
    }
    
    func handlePlaceGroupMessages(withMessage message: Any, withChannel channel: String, withRealmType realmType: RealmType = RealmType.defaultDB) {
        
        if let channelType = NutellaChannelType(rawValue: channel) {
            _ = getRealm(withRealmType: realmType).runtimeSectionName()
            
            guard let currentGroupIndex = getRealm(withRealmType: realmType).runtimeGroupIndex() else {
                //need sectionName for this message
                return
            }
            
            switch channelType {
            case .noteChanges:
                let header = parseHeader(withMessage: message)
                if let speciesIndex = header?.speciesIndex, currentGroupIndex == header?.groupIndex {
                    
                    parseSyncFlag(withMessage: message, withSpeciesIndex: speciesIndex, withRealmType: realmType)
                }
                break
            case .allNotesWithGroup:
                let header = parseHeader(withMessage: message)
                if let groupIndex = header?.groupIndex {
                    if currentGroupIndex == groupIndex {
                        parseMessage(withMessage: message, withGroupIndex: groupIndex, withRealmType: realmType)
                    }
                }
                break
            default:
                break
            }
        }
    }
    
    func handleObjectGroupMessages(withMessage message: Any, withChannel channel: String, withRealmType realmType: RealmType = RealmType.defaultDB) {
        
        if let channelType = NutellaChannelType(rawValue: channel) {
            
            
            switch channelType {
            case .allNotesWithSpecies:
                guard let currentSpeciesIndex = getRealm(withRealmType: RealmType.terminalDB).runtimeSpeciesIndex() else {
                    //need species for this message
                    return
                }
                guard let currentSectionName = getRealm(withRealmType: RealmType.terminalDB).runtimeSectionName() else {
                    //need sectionName for this message
                    return
                }
                let header = parseHeader(withMessage: message)
                if let speciesIndex = header?.speciesIndex, speciesIndex == currentSpeciesIndex {
                    
                    // import the message
                    parseMessage(withMessage: message, withSpeciesIndex: currentSpeciesIndex, withSectionName: currentSectionName, withRealmType: RealmType.terminalDB)
                }
                break
            case .noteChanges:
                guard let currentGroupIndex = getRealm().runtimeGroupIndex() else {
                    //need sectionName for this message
                    return
                }
                
                let header = parseHeader(withMessage: message)
                if let speciesIndex = header?.speciesIndex, currentGroupIndex == header?.groupIndex {
                    
                    parseSyncFlag(withMessage: message, withSpeciesIndex: speciesIndex)
                }
                break
            case .allNotesWithGroup:
                
                guard let currentGroupIndex = getRealm(withRealmType: realmType).runtimeGroupIndex() else {
                    //need sectionName for this message
                    return
                }
                
                let header = parseHeader(withMessage: message)
                if let groupIndex = header?.groupIndex {
                    if currentGroupIndex == groupIndex {
                        parseMessage(withMessage: message, withGroupIndex: groupIndex, withRealmType: realmType)
                    }
                }
                break
            default:
                break
            }
        }
    }
    
    func handlePlaceTerminalMessages(withMessage message: Any, withChannel channel: String) {
        if let channelType = NutellaChannelType(rawValue: channel) {
            guard let currentSpeciesIndex = getRealm(withRealmType: RealmType.terminalDB).runtimeSpeciesIndex() else {
                //need species for this message
                return
            }
            guard let currentSectionName = getRealm(withRealmType: RealmType.terminalDB).runtimeSectionName() else {
                //need sectionName for this message
                return
            }
            switch channelType {
            case .allNotesWithSpecies:
                let header = parseHeader(withMessage: message)
                if let speciesIndex = header?.speciesIndex, speciesIndex == currentSpeciesIndex {
                    
                    // import the message
                    parseMessage(withMessage: message, withSpeciesIndex: currentSpeciesIndex, withSectionName: currentSectionName, withRealmType: RealmType.terminalDB)
                }
                break
            case .noteChanges:
                let header = parseHeader(withMessage: message)
                if let speciesIndex = header?.speciesIndex, speciesIndex == currentSpeciesIndex {
                    // import the message
                    parseMessage(withMessage: message, withSpeciesIndex: currentSpeciesIndex, withSectionName: currentSectionName,withRealmType: RealmType.terminalDB)
                }
                break
            default:
                break
            }
        }
    }
    
    //MARK: Handle Parsing
    
    func parseModelSpeciesNames(withMessage message: Any) {
        let json = JSON(message)
        
        guard let names = json.array else {
            //no speciesIndex
            return
        }
        
        var speciesNames = [String]()
        
        for name in names {
            speciesNames.append("\(name)")
        }
        
        switch  getAppDelegate().checkLoginState() {
        case .currentSection,.currentRun, .currentRun:
            break
        default:
            let r = realmDataController.getRealm()
            let species = r.species
            if !species.isEmpty {
                for (index,name) in speciesNames.enumerated() {
                    
                    try! r.write {
                        species[index].name = name
                        r.add(species, update: false)
                    }
                    
                }
            }
        }
        
        
        UserDefaults.standard.set(speciesNames, forKey: "speciesNames")
        UserDefaults.standard.synchronize()
        
        switch getAppDelegate().checkApplicationState() {
        case .cloudGroup, .objectGroup, .placeTerminal:
            let rdb = realmDataController.getRealm(withRealmType: RealmType.terminalDB)
            let species = rdb.species
            if !species.isEmpty {
                for (index,name) in speciesNames.enumerated() {
                    
                    try! rdb.write {
                        species[index].name = name
                        rdb.add(species, update: false)
                    }
                    
                }
            }
        default:
            break
        }
    }
    
    
    func parseHeader(withMessage message: Any) -> Header? {
        let json = JSON(message)
        guard let speciesIndex = json["header"]["speciesIndex"].int else {
            //no speciesIndex
            return nil
        }
        
        guard let groupIndex = json["header"]["groupIndex"].int else {
            //no speciesIndex
            return nil
        }
        
        var header = Header()
        header.speciesIndex = speciesIndex
        header.groupIndex = groupIndex
        return header
    }
    
    func parseMessage(withMessage message: Any, withGroupIndex groupIndex: Int,withRealmType realmType: RealmType = RealmType.defaultDB) {
        if let sectionName = getRealm(withRealmType: realmType).runtimeSectionName() {
            let json = JSON(message)
            if json == nil {
                //json is invalid
                return
            }
            guard json["notes"].array != nil else {
                //no notes param
                return
            }
            importJsonJSON(forSectionName: sectionName, withJson: json["notes"], withRealmType: realmType)
        }
    }
    
    func parseSyncFlag(withMessage message: Any, withSpeciesIndex speciesIndex: Int, withRealmType realmType: RealmType = RealmType.defaultDB){
        let json = JSON(message)
        if json == nil {
            //json is invalid
            return
        }
        guard json["notes"].array != nil else {
            //no notes param
            return
        }
        
        if let speciesObservations = json["notes"].array {
            
            for (_,soJson) in speciesObservations.enumerated() {
                
                if let isSynced = soJson["isSynced"].bool {
                    
                    if let id = soJson["id"].string {
                        
                        
                        //first check if we can find it by id
                        if let foundSO = getRealm(withRealmType: realmType).speciesObservation(withId: id) {
                            try! getRealm(withRealmType: realmType).write {
                                foundSO.isSynced.value = isSynced
                                getRealm(withRealmType: realmType).add(foundSO, update: true)
                            }
                        }
                    } else {
                        
                        if let allspeciesobsforthisgroup = getRealm(withRealmType: realmType).allSpeciesObservationsForCurrentSectionAndGroup() {
                            if let foundSO = getRealm(withRealmType: realmType).speciesObservation(FromCollection: allspeciesobsforthisgroup, withSpeciesIndex: speciesIndex) {
                                try! getRealm(withRealmType: realmType).write {
                                    foundSO.isSynced.value = isSynced
                                    getRealm(withRealmType: realmType).add(foundSO, update: true)
                                }
                            }
                        }
                    }
                    
                    
                    
                }
            }
        }
        
    }
    
    //header = {'speciesIndex':1, 'groupIndex':2}
    //{ 'header': header, 'notes': parsedNotes});
    func parseMessage(withMessage message: Any, withSpeciesIndex currentSpeciesIndex:Int, withSectionName currentSectionName: String,withRealmType realmType: RealmType = RealmType.defaultDB) {
        let json = JSON(message)
        if json == nil {
            //json is invalid
            return
        }
        guard json["notes"].array != nil else {
            //no notes param
            return
        }
        importJsonJSON(forSectionName: currentSectionName, withJson: json["notes"], withRealmType: realmType)
    }
    
    
    //import from a file or from a string
    //expects array[speciesObservations]
    func importJsonJSON(forSectionName sectionName: String, withJson json: JSON,withRealmType realmType: RealmType = RealmType.defaultDB) {
        
        if let speciesObservations = json.array {
            
            for (_,soJson) in speciesObservations.enumerated() {
                
                var speciesObservation:SpeciesObservation?
                
                //first check to see if there is already one with a groupIndex ==
                
                if let id = soJson["id"].string {
                    
                    if let foundSO = getRealm(withRealmType: realmType).speciesObservation(withId: id) {
                        
                        try! getRealm(withRealmType: realmType).write {
                            speciesObservation = foundSO
                            
                            if let fromSpecies = realmDataController.parseSpeciesJSON(withJson: soJson, withRealmType: realmType)  {
                                speciesObservation?.fromSpecies = fromSpecies
                            }
                            
                            if let ecosystem = realmDataController.parseEcosystemJSON(withJson: json, withRealmType: realmType)  {
                                speciesObservation?.ecosystem = ecosystem
                            }
                            
                            speciesObservation?.update(withJson: soJson, shouldParseId: false)
                            
                            for relationship in foundSO.relationships {
                                getRealm(withRealmType: realmType).delete(relationship)
                            }
                            
                            
                            //process the relationships
                            if let relationshipsJson = soJson["relationships"].array {
                                importRelationshipJSON(withSpeciesObservation: speciesObservation!, withRelationshipsJson: relationshipsJson, withRealmType: realmType)
                            } else {
                                LOG.debug("FOUND NO RELATIONSHIPS SO: \(speciesObservation?.id)")
                            }
                            
                            for speciesPreference in foundSO.speciesPreferences {
                                getRealm(withRealmType: realmType).delete(speciesPreference)
                            }
                            
                            if let preferencesJson = soJson["speciesPreferences"].array {
                                importSpeciesPreferenceJSON(withSpeciesObservation: speciesObservation!, withSpeciesPreferenceJson: preferencesJson, withRealmType: realmType)
                            } else {
                                //found nothing
                                LOG.debug("FOUND NO species preferences SO: \(speciesObservation?.id)")
                            }
                            
                            getRealm(withRealmType: realmType).add(speciesObservation!, update: true)
                        }
                    } else {
                        
                        //new object
                        try! getRealm(withRealmType: realmType).write {
                            speciesObservation = SpeciesObservation()
                            speciesObservation?.update(withJson: soJson, shouldParseId: true)
                            
                            if let fromSpecies = realmDataController.parseSpeciesJSON(withJson: soJson, withRealmType: realmType)  {
                                speciesObservation?.fromSpecies = fromSpecies
                            }
                            
                            if let ecosystem = realmDataController.parseEcosystemJSON(withJson: json, withRealmType: realmType)  {
                                speciesObservation?.ecosystem = ecosystem
                            }
                            
                            
                            //lets double check to see if there isnt another species card like this
                            if let relationshipsJson = soJson["relationships"].array {
                                importRelationshipJSON(withSpeciesObservation: speciesObservation!, withRelationshipsJson: relationshipsJson, withRealmType: realmType)
                            } else {
                                //found nothing
                                LOG.debug("FOUND NO RELATIONSHIPS SO: \(speciesObservation?.id)")
                            }
                            
                            if let preferencesJson = soJson["speciesPreferences"].array {
                                importSpeciesPreferenceJSON(withSpeciesObservation: speciesObservation!, withSpeciesPreferenceJson: preferencesJson, withRealmType: realmType)
                                
                                
                            } else {
                                //found nothing
                                LOG.debug("FOUND NO species preferences SO: \(speciesObservation?.id)")
                            }
                            
                            //                            if let preferencesJson = soJson["preferences"].array {
                            //                                importPreferenceJSON(withSpeciesObservation: speciesObservation!, withPreferencesJson: preferencesJson, withRealmType: realmType)
                            //                            } else {
                            //                                //found nothing
                            //                                LOG.debug("FOUND NO PREFERENCES SO: \(speciesObservation?.id)")
                            //                            }
                            
                            getRealm(withRealmType: realmType).add(speciesObservation!, update: true)
                            //find its group
                            if let group = getRealm(withRealmType: realmType).group(withSectionName: sectionName, withGroupIndex: speciesObservation!.groupIndex) {
                                
                                if let fromSpecies = speciesObservation?.fromSpecies, let needToDelete = getRealm(withRealmType: realmType).speciesObservation(withGroup: group, withFromSpeciesIndex: fromSpecies.index) {
                                    //check timestamps
                                    LOG.debug("NEED TO DELETE \(needToDelete)")
                                    getRealm(withRealmType: realmType).delete(needToDelete)
                                    getRealm(withRealmType: realmType).add(speciesObservation!, update: true)
                                    group.speciesObservations.append(speciesObservation!)
                                    getRealm(withRealmType: realmType).add(group, update: true)
                                } else {
                                    group.speciesObservations.append(speciesObservation!)
                                    getRealm(withRealmType: realmType).add(group, update: true)
                                    
                                    
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    
    //in a write transaction
    func importRelationshipJSON(withSpeciesObservation speciesObservation:SpeciesObservation, withRelationshipsJson relationshipsJson: [JSON], withRealmType realmType: RealmType = RealmType.defaultDB) {
        for (_,rJson) in relationshipsJson.enumerated() {
            
            var relationship: Relationship?
            
            if let id = rJson["id"].string {
                //try to find an old one
                if let r = getRealm(withRealmType: realmType).relationship(withId: id) {
                    relationship = r
                    relationship?.update(withJson: rJson, shouldParseId: false)
                    
                    if let toSpecies = realmDataController.parseSpeciesJSON(withJson: rJson,withRealmType: realmType)  {
                        relationship?.toSpecies = toSpecies
                    }
                    
                    if let ecosystem = realmDataController.parseEcosystemJSON(withJson: rJson,withRealmType: realmType)  {
                        relationship?.ecosystem = ecosystem
                    }
                    
                    getRealm(withRealmType: realmType).add(relationship!, update: true)
                } else {
                    relationship = Relationship()
                    relationship?.update(withJson: rJson, shouldParseId: true)
                    
                    if let toSpecies = realmDataController.parseSpeciesJSON(withJson: rJson,withRealmType: realmType)  {
                        relationship?.toSpecies = toSpecies
                    }
                    
                    if let ecosystem = realmDataController.parseEcosystemJSON(withJson: rJson,withRealmType: realmType)  {
                        relationship?.ecosystem = ecosystem
                    }
                    
                    getRealm(withRealmType: realmType).add(relationship!, update: true)
                    speciesObservation.relationships.append(relationship!)
                }
            } else {
                relationship = Relationship()
                relationship?.update(withJson: rJson, shouldParseId: true)
                
                if let toSpecies = realmDataController.parseSpeciesJSON(withJson: rJson,withRealmType: realmType)  {
                    relationship?.toSpecies = toSpecies
                }
                
                if let ecosystem = realmDataController.parseEcosystemJSON(withJson: rJson,withRealmType: realmType)  {
                    relationship?.ecosystem = ecosystem
                }
                
                getRealm(withRealmType: realmType).add(relationship!, update: true)
                speciesObservation.relationships.append(relationship!)
            }
        }
    }
    
    //in a write transaction
    func importSpeciesPreferenceJSON(withSpeciesObservation speciesObservation:SpeciesObservation, withSpeciesPreferenceJson speciesPreferenceJson: [JSON], withRealmType realmType: RealmType = RealmType.defaultDB) {
        for (_,sJson) in speciesPreferenceJson.enumerated() {
            
            var speciesPreferences: SpeciesPreference?
            
            if let id = sJson["id"].string {
                //try to find an old one
                if let r = getRealm(withRealmType: realmType).speciesPreference(withId: id) {
                    speciesPreferences = r
                    speciesPreferences?.update(withJson: sJson, shouldParseId: false)
                    
                    if let habitat = realmDataController.parseHabitatJSON(withJson: sJson,withRealmType: realmType)  {
                        speciesPreferences?.habitat = habitat
                    }
                    
                    getRealm(withRealmType: realmType).add(speciesPreferences!, update: true)
                } else {
                    speciesPreferences = SpeciesPreference()
                    speciesPreferences?.update(withJson: sJson, shouldParseId: true)
                    
                    if let habitat = realmDataController.parseHabitatJSON(withJson: sJson,withRealmType: realmType)  {
                        speciesPreferences?.habitat = habitat
                    }
                    
                    getRealm(withRealmType: realmType).add(speciesPreferences!, update: true)
                    speciesObservation.speciesPreferences.append(speciesPreferences!)
                }
            } else {
                speciesPreferences = SpeciesPreference()
                speciesPreferences?.update(withJson: sJson, shouldParseId: true)
                
                if let habitat = realmDataController.parseHabitatJSON(withJson: sJson,withRealmType: realmType)  {
                    speciesPreferences?.habitat = habitat
                }
                
                getRealm(withRealmType: realmType).add(speciesPreferences!, update: true)
                speciesObservation.speciesPreferences.append(speciesPreferences!)
            }
        }
    }
    
    func parseHabitatJSON(withJson json: JSON, withRealmType realmType: RealmType = RealmType.defaultDB) -> Habitat? {
        if let habitatIndex = json["habitat"]["index"].int {
            return getRealm(withRealmType: realmType).habitat(withIndex: habitatIndex)
        }
        return nil
    }
    
    func parseSpeciesJSON(withJson json: JSON, withRealmType realmType: RealmType = RealmType.defaultDB) -> Species? {
        if let speciesIndex = json["fromSpecies"]["index"].int {
            return getRealm(withRealmType: realmType).speciesWithIndex(withIndex: speciesIndex)
        }
        
        if let speciesIndex = json["toSpecies"]["index"].int {
            return getRealm(withRealmType: realmType).speciesWithIndex(withIndex: speciesIndex)
        }
        return nil
    }
    
    func parseEcosystemJSON(withJson json: JSON, withRealmType realmType: RealmType = RealmType.defaultDB) -> Ecosystem? {
        if let ecoSystemIndex = json["ecosystem"]["index"].int {
            return getRealm(withRealmType: realmType).ecosystem(withIndex: ecoSystemIndex)
        }
        return nil
    }
    
    // MARK: LOG EVENT
    
    
    // MARK: UPDATE RUNTIME
    
    func updateRuntime(withSectionName sectionName: String? = nil, withSpeciesIndex speciesIndex: Int? = nil, withGroupIndex groupIndex: Int? = nil, withRealmType realmType: RealmType = RealmType.defaultDB, withAction action: String? = nil) {
        //get all the current runtimes
        
        var currentRuntime: Runtime?
        
        if let ct = getRealm(withRealmType: realmType).runtime() {
            currentRuntime = ct
        } else {
            currentRuntime = Runtime()
        }
        
        if let sectionName = sectionName {
            try! getRealm(withRealmType: realmType).write {
                currentRuntime?.currentSectionName = sectionName
                getRealm(withRealmType: realmType).add(currentRuntime!, update: true)
            }
        }
        
        if let speciesIndex = speciesIndex {
            try! getRealm(withRealmType: realmType).write {
                currentRuntime?.currentSpeciesIndex.value = speciesIndex
                getRealm(withRealmType: realmType).add(currentRuntime!, update: true)
            }
        }
        
        if let groupIndex = groupIndex {
            try! getRealm(withRealmType: realmType).write {
                currentRuntime?.currentGroupIndex.value = groupIndex
                getRealm(withRealmType: realmType).add(currentRuntime!, update: true)
            }
        }
        
        if let action = action, let ct = currentRuntime {
            try! getRealm(withRealmType: realmType).write {
                ct.currentAction = action
                getRealm(withRealmType: realmType).add(currentRuntime!, update: true)
            }
        }
    }
    
    func updateChannel(withId id: String?, url: String?, name: String?) {
        try! getRealm().write {
            
            if let channel = getRealm().channel(withId: id!) {
                
                if let n = name {
                    channel.name = n
                }
                
                if let u = url {
                    channel.url = u
                }
                
                getRealm().add(channel, update: true)
                
                
                
            } else {
                let channel = Channel()
                
                if let i = id {
                    channel.id = i
                }
                if let n = name {
                    channel.name = n
                }
                
                if let u = url {
                    channel.url = u
                }
                
                getRealm().add(channel, update: false)

//                if let rt = getRealm().runtime() {
//                    rt.channels.append(channel)
//                    getRealm().add(rt, update: true)
//                }
            }
        }
    }
    
    //MARK: UPDATE SPECIES OBSERVATION
    
    func delete(withSpeciesPreference speciesPreference: SpeciesPreference, withSpeciesIndex speciesIndex: Int,withRealmType realmType: RealmType = RealmType.defaultDB) {
        
        let r = getRealm(withRealmType: realmType)
        
        guard let speciesObservations = r.allSpeciesObservationsForCurrentSectionAndGroup() else {
            return
        }
        
        //couldn't find the species relationship
        guard let foundSO = r.speciesObservation(FromCollection: speciesObservations, withSpeciesIndex: speciesIndex) else {
            return
        }
        
        if let habitat = speciesPreference.habitat,
            let foundSpeciesPreference = r.speciesPreferences(withSpeciesObservation: foundSO, withHabitatIndex: habitat.index) {
            
            
            
            LOG.info( ["condition":getAppDelegate().checkApplicationState(), "activity":realmDataController.getActivity(),"timestamp": Date(),"event":"delete_preference","preferenceId":speciesPreference.id!,"soId":foundSO.id!,"groupIndex":foundSO.groupIndex,"speciesIndex":habitat.index,"sectionName":r.runtimeSectionName()!])
            
            try! r.write {
                r.delete(foundSpeciesPreference)
                foundSO.isSynced.value = false
                r.add(foundSO, update: true)
                
            }
        }
    }
    
    func delete(withRelationship relationship: Relationship, withSpeciesIndex speciesIndex: Int,withRealmType realmType: RealmType = RealmType.defaultDB) {
        
        guard let speciesObservations = getRealm(withRealmType: realmType).allSpeciesObservationsForCurrentSectionAndGroup() else {
            return
        }
        
        //couldn't find the species relationship
        guard let foundSO = getRealm(withRealmType: realmType).speciesObservation(FromCollection: speciesObservations, withSpeciesIndex: speciesIndex) else {
            return
        }
        
        if let toSpecies = relationship.toSpecies,
            let foundRelationship = getRealm(withRealmType: realmType).relationship(withSpeciesObservation: foundSO, withRelationshipType: relationship.relationshipType, forSpeciesIndex: toSpecies.index) {
            
            
            LOG.info( ["condition":getAppDelegate().checkApplicationState(), "activity":realmDataController.getActivity(),"timestamp": Date(),"event":"delete_relationship","relationshipId":relationship.id!,"soId":foundSO.id!,"groupIndex":foundSO.groupIndex,"speciesIndex":toSpecies.index,"sectionName":self.getRealm(withRealmType: realmType).runtimeSectionName()!])
            
            
            try! getRealm(withRealmType: realmType).write {
                getRealm(withRealmType: realmType).delete(foundRelationship)
                
                foundSO.isSynced.value = false
                getRealm(withRealmType: realmType).add(foundSO, update: true)
                
            }
        }
    }
    
    func add(withSpeciesPreference speciesPreference: SpeciesPreference, withSpeciesIndex speciesIndex: Int,withRealmType realmType: RealmType = RealmType.defaultDB) {
        
        let r = getRealm(withRealmType: realmType)
        //get all the observations for the context
        guard let speciesObservations = r.allSpeciesObservationsForCurrentSectionAndGroup() else {
            return
        }
        
        //couldn't find the species relationship
        guard let foundSO = r.speciesObservation(FromCollection: speciesObservations, withSpeciesIndex: speciesIndex) else {
            return
        }
        var id = ""
        if let habitat = speciesPreference.habitat, let foundSpeciesPreference = r.speciesPreferences(withSpeciesObservation: foundSO, withHabitatIndex: habitat.index) {
            speciesPreference.id = foundSpeciesPreference.id
            
            id = speciesPreference.id!
            
            try! r.write {
                r.add(speciesPreference, update: true)
                foundSO.isSynced.value = false
                r.add(foundSO, update: true)
            }
        } else {
            speciesPreference.generateId()
            
            id = speciesPreference.id!
            try! r.write {
                r.add(speciesPreference, update: true)
                foundSO.speciesPreferences.append(speciesPreference)
                foundSO.isSynced.value = false
                r.add(foundSO, update: true)
            }
        }
        
        LOG.info( ["condition":getAppDelegate().checkApplicationState(), "activity":realmDataController.getActivity(),"timestamp": Date(),"event":"add_preference","preferenceId":id,"soId":foundSO.id!,"groupIndex":foundSO.groupIndex,"habitatIndex":speciesPreference.habitat!.index,"sectionName":r.runtimeSectionName()!])
        
    }
    
    func add(withExperiment experiment: Experiment,withRealmType realmType: RealmType = RealmType.defaultDB) {
        //get all the observations for the context
        
        let r = getRealm(withRealmType: realmType)
        
   
            
            try! r.write {
                r.add(experiment, update: true)
            }
    
        var groupIndex = -1
        var experimentId = "null"
        
        if let id = experiment.id {
            experimentId = id
        }
        
        if let gi = r.runtime()?.currentGroupIndex.value {
            groupIndex = gi
        }
        
        LOG.info( ["condition":getAppDelegate().checkApplicationState(), "activity":realmDataController.getActivity(),"timestamp": Date(),"event":"edit_experiment","experimentId":experimentId,"groupIndex":groupIndex,"sectionName":r.runtimeSectionName()!])
        
        
        
        exportExperiment(withExperiment: experiment)
        
        
        
        
    }
    
    
    func add(withRelationship relationship: Relationship, withSpeciesIndex speciesIndex: Int, withRealmType realmType: RealmType = RealmType.defaultDB) {
        //get all the observations for the context
        
        let r = getRealm(withRealmType: realmType)
        
        
        guard let speciesObservations = r.allSpeciesObservationsForCurrentSectionAndGroup() else {
            return
        }
        
        //couldn't find the species relationship
        guard let foundSO = r.speciesObservation(FromCollection: speciesObservations, withSpeciesIndex: speciesIndex) else {
            return
        }
        
        
        
        var id = ""
        
        if let toSpecies = relationship.toSpecies,
            let foundRelationship = r.relationship(withSpeciesObservation: foundSO, withRelationshipType: relationship.relationshipType, forSpeciesIndex: toSpecies.index) {
            
            relationship.id = foundRelationship.id
            id = relationship.id!
            try! r.write {
                r.add(relationship, update: true)
                foundSO.isSynced.value = false
                r.add(foundSO, update: true)
            }
        } else {
            relationship.generateId()
            id = relationship.id!
            
            try! r.write {
                r.add(relationship, update: true)
                foundSO.relationships.append(relationship)
                foundSO.isSynced.value = false
                r.add(foundSO, update: true)
            }
        }
        
        LOG.info( ["condition":getAppDelegate().checkApplicationState(), "activity":realmDataController.getActivity(),"timestamp": Date(),"event":"add_relationship","relationshipId":id,"observationId":foundSO.id!,"groupIndex":foundSO.groupIndex,"speciesIndex":relationship.toSpecies!.index,"sectionName":r.runtimeSectionName()!])
    }
    
    func generateTestData(withRealmType realmType: RealmType = RealmType.defaultDB) {
        if let sysConfig = getRealm(withRealmType: realmType).systemConfiguration() {
            for section in sysConfig.sections {
                for group in section.groups {
                    populateWithSpeciesObservationTestData(forGroup: group, andSystemConfig: sysConfig)
                }
            }
        }
    }
    
//    { ecosystem: 0,
//    timestamp: 1479090865455,
//    question: 'question 3',
//    manipulations: 'lol',
//    reasoning: 'lol',
//    results: 'what ',
//    figures:
//    [ 'http://ltg.evl.uic.edu:57882/b06d9cffe1b074adf2219a7c787f1d88.png',
//    'http://ltg.evl.uic.edu:57882/4928e36c1c00217e0264963de9e39bfb.png',
//    'http://ltg.evl.uic.edu:57882/df52fb360c99397b4fbadb6d8a1fad9d.png' ],
//    conclusions: 'what' }
    
    func exportExperiment(withExperiment experiment:Experiment) {
        
        if let ecosystemIndex = experiment.ecosystem?.index {
            
            let figures = experiment.attachments?.components(separatedBy: ",") ?? []
            let message = ["question":experiment.question!, "manipulations":experiment.manipulations!,"timestamp": Date(),"reasoning":experiment.reasoning!,"ecosystem":ecosystemIndex,"results":experiment.results!,"conclusions":experiment.conclusions!,"figures":figures] as [String : Any]
            LOG.info("sending \(message)")
            
            if nutella != nil {
                let block = DispatchWorkItem {
                    let json = JSON(message)
                    let jsonObject: Any = json.object
                    nutella?.net.asyncRequest("update_experiment", message: jsonObject as AnyObject, requestName: "update_experiment")
                }
                DispatchQueue.main.async(execute: block)
            }
        }
        
        
    
    }
    
    func exportSection(withName name: String, andFilePath filePath: String, withRealmType realmType: RealmType = RealmType.defaultDB) {
        
        if let defaultSection = getRealm(withRealmType: realmType).section(withName: name){
            let dict = defaultSection.toDictionary()
            let json = JSON(dict)
            let str = json.string
            _ = str?.data(using: String.Encoding.utf8)!
            
            let url = URL(fileURLWithPath: filePath)
            do {
                try str?.write(to: url, atomically: false, encoding: String.Encoding.utf8)
            }
            catch {/* error handling here */}
            print("JSON: \(json)")
        }
        
    }
    
    func exportSpeciesObservation(speciesObservation: SpeciesObservation) {
        if nutella != nil {
            let block = DispatchWorkItem {
                let json = JSON(speciesObservation.toDictionary())
                let jsonObject: Any = json.object
                nutella?.net.asyncRequest("save_note", message: jsonObject as AnyObject, requestName: "save_note")
            }
            DispatchQueue.main.async(execute: block)
        }
    }
}

extension RealmDataController {
    
    // MARK: Mock data
    //populate speciesObservation with fake data
    func populateWithSpeciesObservationTestData(forGroup group: Group, andSystemConfig systemConfig: SystemConfiguration, withRealmType realmType: RealmType = RealmType.defaultDB) {
        
        getRealm(withRealmType: realmType).beginWrite()
        let simConfig = systemConfig.simulationConfiguration
        let allSpecies = simConfig?.species
        let allEcosystems = simConfig?.ecosystems
        
        for so in group.speciesObservations {
            so.lastModified = Date()
            so.groupIndex = group.index
            for i in 0...Randoms.randomInt(0, 4) {
                
                let relationship = Relationship()
                relationship.toSpecies = allSpecies?[Randoms.randomInt(0, 10)]
                relationship.note = Randoms.randomFakeConversation()
                relationship.attachments = Randoms.getRandomImage()
                relationship.ecosystem = allEcosystems?[Randoms.randomInt(0, 4)]
                
                
                switch i {
                    //            case 0:
                //                relationship.relationshipType = SpeciesRelationships.MUTUAL
                case 0:
                    relationship.relationshipType = RelationshipType.producer.rawValue
                case 1:
                    relationship.relationshipType = RelationshipType.consumer.rawValue
                case 3:
                    relationship.relationshipType = RelationshipType.competes.rawValue
                default:
                    relationship.relationshipType = RelationshipType.consumer.rawValue
                }
                
                so.relationships.append(relationship)
                
                getRealm(withRealmType: realmType).add(so, update: true)
                
            }
            
        }
        
        try! getRealm(withRealmType: realmType).commitWrite()
        
        
    }
    
    //update species relationship
    func updateSpeciesObservation(_ toSpecies: Species, speciesObservation: SpeciesObservation, relationshipType: String, withRealmType realmType: RealmType = RealmType.defaultDB){
        try! getRealm(withRealmType: realmType).write {
            let relationship = Relationship()
            relationship.id = NSUUID().uuidString
            relationship.toSpecies = toSpecies
            relationship.lastModified = NSDate() as Date
            relationship.note = Randoms.randomFakeConversation()
            relationship.attachments = Randoms.getRandomImage()
            relationship.ecosystem = speciesObservation.ecosystem
            relationship.relationshipType = relationshipType
            speciesObservation.relationships.append(relationship)
            getRealm(withRealmType: realmType).add(relationship, update: true)
        }
    }
    
    func createSpeciesObservation(_ fromSpecies: Species, allSpecies: List<Species>, allEcosystems: List<Ecosystem>) -> SpeciesObservation {
        let speciesObservation = SpeciesObservation()
        speciesObservation.id = UUID().uuidString
        speciesObservation.fromSpecies = fromSpecies
        speciesObservation.lastModified = Date()
        let ecosystem = allEcosystems[0]
        speciesObservation.ecosystem = ecosystem
        
        //create relationships
        
        for i in 0...3 {
            
            let relationship = Relationship()
            relationship.id = UUID().uuidString
            relationship.toSpecies = allSpecies[i+2]
            relationship.lastModified = Date()
            relationship.note = "hello"
            relationship.attachments = Randoms.getRandomImage()
            relationship.ecosystem = ecosystem
            
            
            switch i {
                //            case 0:
            //                relationship.relationshipType = SpeciesRelationships.MUTUAL
            case 0:
                relationship.relationshipType = RelationshipType.producer.rawValue
            case 1:
                relationship.relationshipType = RelationshipType.consumer.rawValue
            case 3:
                relationship.relationshipType = RelationshipType.competes.rawValue
            default:
                relationship.relationshipType = RelationshipType.consumer.rawValue
            }
            
            speciesObservation.relationships.append(relationship)
        }
        
        
        return speciesObservation
    }
    
    // MARK: ACTIVITY
    
    func getActivity() -> String {
        if let activity = UserDefaults.standard.value(forKey: "activity") as? String {
            return activity
        } else {
            return "not specified"
        }
    }
    
    
    // MARK: Species
    
    func findSpecies(withSpeciesIndex speciesIndex: Int, withRealmType realmType: RealmType = RealmType.defaultDB) -> Species? {
        let foundSpecies = getRealm(withRealmType: realmType).speciesWithIndex(withIndex: speciesIndex)
        return foundSpecies
    }
    
    // MARK Ecosytem
    
    func findEcosystem(withEcosystemIndex ecosystemIndex: Int, withRealmType realmType: RealmType = RealmType.defaultDB) -> Ecosystem? {
        let foundEcosystem = getRealm(withRealmType: realmType).ecosystem(withIndex: ecosystemIndex)
        return foundEcosystem
    }
    
    
    static func generateImageFileNameFromIndex(_ index: Int, isHighlighted: Bool) -> String {
        var imageName = ""
        
        var highlight = ""
        
        if !isHighlighted {
            highlight = "_0"
        }
        
        if index < 10 {
            imageName = "species_0\(index)\(highlight).png"
        } else {
            
            imageName = "species_\(index)\(highlight).png"
        }
        return imageName
    }
    
    static func generateImageForSpecies(_ index: Int, isHighlighted: Bool) -> UIImage? {
        let imageName = self.generateImageFileNameFromIndex(index, isHighlighted: isHighlighted)
        return UIImage(named: imageName)
    }
    
    static func generateImageForHabitat(_ index: Int, isHighlighted: Bool) -> UIImage? {
        let imageName = self.generateImageFileNameFromIndex(index, isHighlighted: isHighlighted)
        return UIImage(named: imageName)
    }
    
    // MARK: JSON Parsing
    
    func parseUserGroupConfigurationJson(withSimConfig simConfig: SimulationConfiguration, withPlaceHolders placeHolders: Bool = false, withSectionName sectionName: String = "default", withRealmType realmType: RealmType = RealmType.defaultDB) -> SystemConfiguration {
        
        let r = getRealm(withRealmType: realmType)
        
        r.beginWrite()
        
        let path = Bundle.main.path(forResource: "system_configuration", ofType: "json")
        let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path!))
        let json = JSON(data: jsonData!)
        
        let systemConfigruation = SystemConfiguration()
        systemConfigruation.simulationConfiguration = simConfig
        
        //self.systemConfiguration = systemConfigruation
        
        if let sections = json["sections"].array {
            
            for (_,sectionItem) in sections.enumerated() {
                let section = Section()
                
                if let name = sectionItem["name"].string {
                    section.name = name
                }
                
                if let teacher = sectionItem["teacher"].string {
                    section.teacher = teacher
                }
                
                if section.name == sectionName {
                    
                    r.add(section, update:true)
                    //add system config
                    systemConfigruation.sections.append(section)
                    
                    if let groups = sectionItem["groups"].array {
                        for (groupIndex,_) in groups.enumerated() {
                            
                            let g = Group()
                            
                            g.name = groupName(withIndex: groupIndex)
                            
                            
                            g.index = groupIndex
                            r.add(g)
                            
                            //add groups
                            section.groups.append(g)
                            
                            //create speciesObservation place holders for group
                            if placeHolders {
                                let allSpecies = r.species
                                //create a speciesObservation for each species
                                for fromSpecies in allSpecies {
                                    // var makeRelationship : (String, Group) -> List<SpeciesObservation>
                                    
                                    let speciesObservation = SpeciesObservation()
                                    speciesObservation.id = "\(g.index)-\(fromSpecies.index)"
                                    speciesObservation.fromSpecies = fromSpecies
                                    speciesObservation.groupIndex = g.index
                                    
                                    r.add(speciesObservation, update: true)
                                    
                                    
                                    g.speciesObservations.append(speciesObservation)
                                    r.add(g, update: true)
                                }
                            }
                        }
                    }
                }
                
            }
        }
        
        r.add(systemConfigruation)
        try! r.commitWrite()
        return systemConfigruation
    }
    
    func parseNutellaConfigurationJson(withRealmType realmType: RealmType = RealmType.defaultDB) -> NutellaConfig {
        
        let r = getRealm(withRealmType: realmType)
        
        
        r.beginWrite()
        
        let path = Bundle.main.path(forResource: "nutella_config", ofType: "json")
        let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path!))
        let json = JSON(data: jsonData!)
        
        let nutellaConfig = NutellaConfig()
        
        if let hosts = json["config"]["hosts"].array {
            for (_,item) in hosts.enumerated() {
                
                let host = Host()
                
                if let id = item["id"].string {
                    host.id = id
                }
                
                if let appId = item["appId"].string {
                    host.appId = appId
                }
                
                if let runId = item["runId"].string {
                    host.runId = runId
                }
                
                if let url = item["url"].string {
                    host.url = url
                }
                
                if let componentId = item["componentId"].string {
                    host.componentId = componentId
                }
                
                nutellaConfig.hosts.append(host)
            }
        }
        
        if let conditions = json["config"]["conditions"].array {
            for (_,item) in conditions.enumerated() {
                
                let condition = Condition()
                
                if let id = item["id"].string {
                    condition.id = id
                }
                
                if let subscribes = item["subscribes"].string {
                    condition.subscribes = subscribes
                }
                
                if let publishes = item["publishes"].string {
                    condition.publishes = publishes
                }
                
                condition.last_modified = Date()
                
                nutellaConfig.conditions.append(condition)
            }
        }
        
        r.add(nutellaConfig)
        try! r.commitWrite()
        
        return nutellaConfig
    }
    
    // MARK: Configuration
    
    func sectionName(withIndex index: Int) -> String {
        return sections()[index]
    }
    
    func sections() -> [String] {
        let sections = UserDefaults.standard.array(forKey: "sectionNames") ?? []
        
        if sections.isEmpty {
            return ["default", "6ADF", "6MT","6BM"]
        } else {
            return sections as! [String]
        }
    }
    
    
    
    func speciesName(withIndex index: Int) -> String {
        let speciesNames = UserDefaults.standard.array(forKey: "speciesNames") ?? []
        
        if !speciesNames.isEmpty && speciesNames.count >= index {
            return (speciesNames[index] as? String)!
        }
        
        return "\(index)"
    }
    
    func groups() -> [String] {
        let groups = UserDefaults.standard.array(forKey: "currentRoster") ?? []
        
        if groups.isEmpty {
            return ["Team 1", "Team 2", "Team 3","Team 4", "Team 5"]
        } else {
            return groups as! [String]
        }
    }
    
    func groupName(withIndex index: Int) -> String {
        return groups()[index]
    }
    
    
    func parseSpeciesConfigurationJson() -> [Species] {
        
        var allSpecies = [Species]()
        
        let path = Bundle.main.path(forResource: "wallcology_configuration", ofType: "json")
        let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path!))
        let json = JSON(data: jsonData!)
        
        
        if let foundSpecies = json["ecosystemItems"].array {
            for (index,item) in foundSpecies.enumerated() {
                
                let species = Species()
                
                
                if let index = item["index"].int {
                    species.index = index
                }
                
                if let color = item["color"].string {
                    species.color = color
                }
                
                if let imgUrl = item["imgUrl"].string {
                    species.imgUrl = imgUrl
                }
                
                species.name = speciesName(withIndex: index)
                
                allSpecies.append(species)
                
            }
            
        }
        
        return allSpecies
    }
    
    
    func parseSimulationConfigurationJson(withRealmType realmType: RealmType = RealmType.defaultDB) -> SimulationConfiguration {
        
        let r = getRealm(withRealmType: realmType)
        
        r.beginWrite()
        
        
        let path = Bundle.main.path(forResource: "wallcology_configuration", ofType: "json")
        let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path!))
        let json = JSON(data: jsonData!)
        
        let simulationConfiguration = SimulationConfiguration()
        
        if let ecosystem = json["ecosystems"].array {
            
            for (index,item) in ecosystem.enumerated() {
                let ecosystem = Ecosystem()
                ecosystem.index = index
                
                if let temp = item["temperature"].int {
                    ecosystem.temperature = temp
                }
                
                if let pl = item["pipelength"].int {
                    ecosystem.pipelength = pl
                }
                
                if let ba = item["brickarea"].int {
                    ecosystem.brickarea = ba
                }
                
                if let name = item["name"].string {
                    ecosystem.name = name
                }
                
                
                simulationConfiguration.ecosystems.append(ecosystem)
            }
        }
        
        if let allSpecies = json["ecosystemItems"].array {
            for (index,item) in allSpecies.enumerated() {
                
                let species = Species()
                
                
                if let index = item["index"].int {
                    species.index = index
                }
                
                if let color = item["color"].string {
                    species.color = color
                }
                
                if let imgUrl = item["imgUrl"].string {
                    species.imgUrl = imgUrl
                }
                
                species.name = speciesName(withIndex: index)
                
                
                simulationConfiguration.species.append(species)
                
            }
        }
        
        if let allHabitats = json["habitatItems"].array {
            for (_,item) in allHabitats.enumerated() {
                
                let habitat = Habitat()
                
                
                if let index = item["index"].int {
                    habitat.index = index
                }
                
                if let name = item["name"].string {
                    habitat.name = name
                }
                
                simulationConfiguration.habitats.append(habitat)
            }
        }
        
        r.add(simulationConfiguration)
        
        try! r.commitWrite()
        
        return simulationConfiguration
    }
    
    // MARK: Nutella
    
    func validateNutellaConfiguration(withRealmType realmType: RealmType = RealmType.defaultDB) -> Bool {
        
        let r = getRealm(withRealmType: realmType)
        
        let foundConfigs = r.objects(NutellaConfig.self)
        
        if foundConfigs.isEmpty {
            let nutellaConfig = parseNutellaConfigurationJson(withRealmType: realmType)
            
            
            try! r.write {
                r.add(nutellaConfig)
            }
            return false
        }
        if DEBUG {
            LOG.debug("Added Nutella Configs, not present")
        }
        
        return true
    }
    
    func deleteAllSpeciesObservations(withRealmType realmType: RealmType = RealmType.defaultDB) {
        let r = getRealm(withRealmType: realmType)
        
        try! r.write {
            r.delete(r.allRelationships())
            r.delete(r.allSpeciesPreference())
            r.delete(r.allSpeciesObservations())
        }
    }
    
    // MARK: DB functions
    
    func deleteAllConfigurationAndGroups(withRealmType realmType: RealmType = RealmType.defaultDB) {
        let r = getRealm(withRealmType: realmType)
        
        try! r.write {
            r.deleteAll()
        }
    }
    
    func deleteRelationships(withRealmType realmType: RealmType = RealmType.defaultDB) {
        let r = getRealm(withRealmType: realmType)
        
        try! r.write {
            r.delete(r.objects(Relationship.self))
        }
    }
    
    func deleteChannels(withRealmType realmType: RealmType = RealmType.defaultDB) {
        let r = getRealm(withRealmType: realmType)
        
        try! r.write {
            r.delete(r.objects(Channel.self))
        }
    }
    
    func deleteExperiments(withRealmType realmType: RealmType = RealmType.defaultDB) {
        let r = getRealm(withRealmType: realmType)
        
        try! r.write {
            r.delete(r.objects(Experiment.self))
        }
    }
    
    func deleteAllUserData(withRealmType realmType: RealmType = RealmType.defaultDB) {
        
        let r = getRealm(withRealmType: realmType)
        
        try! r.write {
            r.delete(r.objects(Experiment.self))
            r.delete(r.objects(Channel.self))
            r.delete(r.objects(Runtime.self))
            r.delete(r.objects(Section.self))
            r.delete(r.objects(Member.self))
            r.delete(r.objects(Group.self))
            r.delete(r.objects(Species.self))
            r.delete(r.objects(SpeciesObservation.self))
            r.delete(r.objects(SpeciesPreference.self))
            r.delete(r.objects(Relationship.self))
        }
    }
    
    // MARK: Reporting Metrics
    
    func saveMetric(withEventName eventName: String, withProperties properties: [String:String]) {
        
    }
    
    func saveMetric(withEventName eventName: String) {
        
    }
    
}
