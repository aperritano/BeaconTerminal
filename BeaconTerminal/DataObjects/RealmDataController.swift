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
    
    func add(_ realmObject: Object, shouldUpdate: Bool) {
        try! realm?.write {
            realm?.add(realmObject, update: shouldUpdate)
        }
    }
    
    func delete(_ realmObject: Object) {
        try! realm?.write {
            realm?.delete(realmObject)
        }
    }
    
    // Mark: Group
    
    static func exportJson(withSpeciesObservation speciesObservation: SpeciesObservation, group: Group) -> String {
        
        let speciesObsJSON = JSON(speciesObservation.toDictionary())
        if let string = speciesObsJSON.rawString() {
            return string
        }
        
        return ""
    }
    
    
    // Mark: Nutella updates
    
    func processNutellaUpdate(nutellaUpdate: NutellaUpdate) {
        //what condition are we in?
        
        switch getAppDelegate().checkApplicationState() {
        case .placeTerminal:
            if let response = nutellaUpdate.response, let channel = nutellaUpdate.channel, nutellaUpdate.updateType == .response {
                switch channel {
                case NutellaChannelType.allNotesWithSpecies.rawValue:
                    
                    let json = JSON(response)
                    
                    if let runtime = realm?.allObjects(ofType: Runtime.self).first, let sectionName = runtime.currentSection?.name {
                        importJsonDB(forSectionName: sectionName, withJson: json, write: true)
                    }
                    break
                case NutellaChannelType.allNotes.rawValue:
                    break
                default:
                    break
                }
            }
            break
        default:
            break
        }
        
        
    }
    
    func checkEcosystmAndSpecies( so: SpeciesObservation, soItem: JSON) {
        if let speciesIndex = soItem["fromSpecies"]["index"].int {
            
            if let foundSpecies = realm?.speciesWithIndex(withIndex: speciesIndex) {
                so.fromSpecies = foundSpecies
            }
        }
        
        if let ecoSystemIndex = soItem["ecosystem"]["index"].int {
            if let foundEcosystem = realmDataController?.findEcosystem(withEcosystemIndex: ecoSystemIndex) {
                so.ecosystem = foundEcosystem
            }
        }
    }
    
    
    //import from a file or from a string
    func importJsonDB(forSectionName sectionName: String, withJson json: JSON, write: Bool) {
        
        var jsonDB: JSON?
        
        if json == nil {
            let path = Bundle.main.path(forResource: "species_note_test_db", ofType: "json")
            let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path!))
            jsonDB = JSON(data: jsonData!)
        } else {
            jsonDB = json
        }
        
        if let speciesObservations = jsonDB?.array {
            
            for (_,soItem) in speciesObservations.enumerated() {
                
                if let id = soItem["id"].string {
                    
                    if let foundSO = realm?.speciesObservation(withId: id) {
                        try! realm?.write {
                            foundSO.update(withJson: soItem, withId: false)
                            checkEcosystmAndSpecies(so: foundSO, soItem: soItem)
                            
                            //process the relationships
                            
                        }
                    } else {
                        //new object
                        try! realm?.write {
                            let newSO = SpeciesObservation()
                            newSO.update(withJson: soItem, withId: true)
                            checkEcosystmAndSpecies(so: newSO, soItem: soItem)
                            
                            //find its greoup
                            if let group = realm?.group(withSectionName: sectionName, withGroupIndex: newSO.groupIndex) {
                                if let needToMerge = realm?.speciesObservation(withGroup: group, withFromSpeciesIndex: newSO.fromSpecies!.index) {
                                    //check timestamps
                                    LOG.debug("NEED TO MERGE \(needToMerge)")
                                } else {
                                    group.speciesObservations.append(newSO)
                                }
                            }
                            
                            //lets double check to see if there isnt another species card like this
                            //add it to the group
                        }
                    }
                }
            }
        }
    }

    func importRelationshipDB(withSpeciesObservation speciesObservation:SpeciesObservation, withSpeciesObsJson SpeciesObsJson: JSON) {
        
    }

    
    // MARK: Update Methods
    
    func updateSpeciesObservation(forSpecies speciesIndex:Int, andSection section: Section, withJson json: JSON) {
        
        if json != nil {
            if let fromIndex = json["fromSpecies"]["index"].int {
                if speciesIndex == fromIndex {
                    
                    //does it exist?
                    if let soId = json["id"].string {
                        
                        //not terminal condition
                        if let foundSO = realm?.allObjects(ofType: SpeciesObservation.self).filter(using: "id = '\(soId)'").first {
                            //LOG.debug("IMPORT found previous SO: \(foundSO)")
                            
                        } else {
                            if let groupId = json["groupId"].int, let foundGroup = section.groups.filter(using: "index = \(groupId)").first {
                                
                                //terminal condition
                                //create a new one
                                try! realm?.write {
                                    let speciesObservation = SpeciesObservation()
                                    speciesObservation.update(withJson: json, withId: false)
                                    
                                    
                                    if let relationshipsJson = json["relationships"].array {
                                        for relationshipJson in relationshipsJson {
                                            let relationship = Relationship()
                                            relationship.update(withJson: relationshipJson)
                                            realm?.add(relationship)
                                            speciesObservation.relationships.append(relationship)
                                            
                                        }
                                        
                                    }
                                    
                                    
                                    realm?.add(speciesObservation)
                                    
                                    foundGroup.speciesObservations.append(speciesObservation)
                                    
                                    realm?.add(foundGroup)
                                }
                            }
                        }
                        
                        
                        
                    } else {
                        //print error
                        print(json["id"])
                        
                    }
                } else {
                    LOG.debug("Wrong Species Card!! fromSpecies: \(speciesIndex) id: \(json["id"].stringValue)")
                }
            }
        }
    }
    
    func updateUser(withGroup group: Group?, section: Section?) {
        if let g = group, let s = section {
            
            let runtimeObjs = realm?.allObjects(ofType: Runtime.self)
            for r in runtimeObjs! {
                LOG.debug("DELETE runtime obj \(r.id)")
            }
            //create a new one
            
            try! realm?.write {
                realm?.delete((realm?.allObjects(ofType: Runtime.self))!)
                
                let runtime = Runtime()
                runtime.id = UUID().uuidString
                runtime.currentGroup = g
                runtime.currentSection = s
                realm?.add(runtime)
                
                //update bottombar
                
                getAppDelegate().bottomNavigationController?.changeTitle(with: group, and: s)
            }
        }
        
        
    }
    
    func updateRuntimeSection(withSection section: Section?, andOrSpecies species:Species?) {
        //get all the current runtimes
        if let currentRuntime = realm?.allObjects(ofType: Runtime.self).first {
            if let s = section {
                try! realm?.write {
                    currentRuntime.currentSection = s
                    realm?.add(currentRuntime, update: true)
                }
            }
            
            if let s = species {
                try! realm?.write {
                    currentRuntime.currentSpecies = s
                    realm?.add(currentRuntime, update: true)
                }
            }
            
        } else {
            //create a new one
            let currentRuntime = Runtime()
            if let s = section {
                try! realm?.write {
                    currentRuntime.currentSection = s
                    realm?.add(currentRuntime, update: true)
                }
            }
            if let s = species {
                try! realm?.write {
                    currentRuntime.currentSpecies = s
                    realm?.add(currentRuntime, update: true)
                }
            }
        }
        
    }
    
    func generateTestData() {
        if let sysConfig = realm?.systemConfiguration() {
            for section in sysConfig.sections {
                for group in section.groups {
                    populateWithSpeciesObservationTestData(forGroup: group, andSystemConfig: sysConfig)
                }
            }
        }
    }
    
    
    
    func exportSection(withName name: String, andFilePath filePath: String) {
        
        if let defaultSection = realm?.section(withName: name){
            let dict = defaultSection.toDictionary()
            let json = JSON(dict)
            let str = json.string
            let data = str?.data(using: String.Encoding.utf8)!
            
            let url = URL(fileURLWithPath: filePath)
            do {
                try str?.write(to: url, atomically: false, encoding: String.Encoding.utf8)
            }
            catch {/* error handling here */}
            print("JSON: \(json)")
        }
        
    }
    
    func exportSpeciesObservation(withNutella nutella: Nutella, withSpeciesObservation speciesObservation: SpeciesObservation) {
        if nutella != nil {
            let block = DispatchWorkItem {
                let json = JSON(speciesObservation)
                let jsonObject: Any = json.object
                nutella.net.asyncRequest("save_note", message: jsonObject as AnyObject, requestName: "save_note")
            }
            DispatchQueue.main.async(execute: block)
        }
    }
}

extension RealmDataController {
    
    // Mark: Mock data
    //populate speciesObservation with fake data
    func populateWithSpeciesObservationTestData(forGroup group: Group, andSystemConfig systemConfig: SystemConfiguration) {
        
        realm!.beginWrite()
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
                
                realm?.add(so, update: true)
                
            }
            
        }
        
        try! realm?.commitWrite()
        
        
    }
    
    
    //update species relationship
    func updateSpeciesObservation(_ toSpecies: Species, speciesObservation: SpeciesObservation, relationshipType: String){
        try! realm?.write {
            let relationship = Relationship()
            relationship.id = NSUUID().uuidString
            relationship.toSpecies = toSpecies
            relationship.lastModified = NSDate() as Date
            relationship.note = Randoms.randomFakeConversation()
            relationship.attachments = Randoms.getRandomImage()
            relationship.ecosystem = speciesObservation.ecosystem
            relationship.relationshipType = relationshipType
            speciesObservation.relationships.append(relationship)
            realm?.add(relationship, update: true)
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

    // Mark: Species
    
    func findSpecies(withSpeciesIndex speciesIndex: Int) -> Species? {
        let foundSpecies = realm!.speciesWithIndex(withIndex: speciesIndex)
        return foundSpecies
    }
    
    // Mark Ecosytem
    
    func findEcosystem(withEcosystemIndex ecosystemIndex: Int) -> Ecosystem? {
        let foundEcosystem = realm!.ecosystem(withIndex: ecosystemIndex)
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
    
    // Mark: JSON Parsing
    
    func parseUserGroupConfigurationJson(withSimConfig simConfig: SimulationConfiguration) -> SystemConfiguration {
        realm!.beginWrite()
        
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
                
                //add system config
                systemConfigruation.sections.append(section)
                
                if let groups = sectionItem["groups"].array {
                    for (groupIndex,groupItem) in groups.enumerated() {
                        
                        let group = Group()
                        
                        if let name = groupItem["name"].string {
                            group.name = name
                        }
                        
                        group.index = groupIndex
                        
                        //add groups
                        section.groups.append(group)
                        
                        if let groupMembers = groupItem["members"].array {
                            for (_,memberItem) in groupMembers.enumerated() {
                                
                                let member = Member()
                                member.name = memberItem.string
                                
                                //add members
                                group.members.append(member)
                                section.members.append(member)
                            }
                        }
                        
                        //create speciesObservation place holders for group
                        //prepareSpeciesObservations(for: group, simConfig: simConfig)
                    }
                }
                
            }
        }
        
        realm?.add(systemConfigruation)
        try! realm?.commitWrite()
        return systemConfigruation
    }
    
    func prepareSpeciesObservations(for group: Group, simConfig: SimulationConfiguration) {
        let allSpecies = simConfig.species
        
        //create a speciesObservation for each species
        for fromSpecies in allSpecies {
            // var makeRelationship : (String, Group) -> List<SpeciesObservation>
            
            let speciesObservation = SpeciesObservation()
            speciesObservation.fromSpecies = fromSpecies
            speciesObservation.groupIndex = group.index
            
            preparePreferences(for: speciesObservation)
            
            group.speciesObservations.append(speciesObservation)
        }
    }
    
    //step 3. prepare preferences
    func preparePreferences(for speciesObservation: SpeciesObservation) {
        //create preferences
        let initalPreference = "Not ready to report"
        
        let trophicLevelPreference = Preference()
        trophicLevelPreference.configure(type: Preferences.trophicLevel, value: initalPreference)
        speciesObservation.preferences.append(trophicLevelPreference)
        
        let behavorsPreference = Preference()
        behavorsPreference.configure(type: Preferences.behaviors, value: initalPreference)
        speciesObservation.preferences.append(behavorsPreference)
        
        let predationPreference = Preference()
        predationPreference.configure(type: Preferences.predationResistance, value: initalPreference)
        speciesObservation.preferences.append(predationPreference)
        
        let heatSensitivityPreference = Preference()
        heatSensitivityPreference.configure(type: Preferences.heatSensitivity, value: initalPreference)
        speciesObservation.preferences.append(heatSensitivityPreference)
        
        let humiditySensistivityPreference = Preference()
        humiditySensistivityPreference.configure(type: Preferences.humditiySensitivity, value: initalPreference)
        speciesObservation.preferences.append(humiditySensistivityPreference)
        
        let habitatPreference = Preference()
        habitatPreference.configure(type: Preferences.habitatPreference, value: "")
        
        speciesObservation.preferences.append(habitatPreference)
    }
    
    func parseNutellaConfigurationJson() -> NutellaConfig {
        realm!.beginWrite()
        
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
                
                if let resourceId = item["resourceId"].string {
                    host.resourceId = resourceId
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
        
        realm?.add(nutellaConfig)
        try! realm?.commitWrite()
        
        return nutellaConfig
    }
    
    // Mark: Configuration
    
    func parseSimulationConfigurationJson() -> SimulationConfiguration {
        realm!.beginWrite()
        
        
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
                
                species.name = Randoms.creatureNames()[index]
                
                simulationConfiguration.species.append(species)
                
            }
            
        }
        
        realm?.add(simulationConfiguration)
        
        try! realm?.commitWrite()
        
        return simulationConfiguration
    }
    
    // Mark: Nutella
    
    func validateNutellaConfiguration() -> Bool {
        let foundConfigs = realm!.allObjects(ofType: NutellaConfig.self)
        
        if foundConfigs.isEmpty {
            let nutellaConfig = parseNutellaConfigurationJson()
            add(nutellaConfig, shouldUpdate: false)
            return false
        }
        if DEBUG {
            LOG.debug("Added Nutella Configs, not present")
        }
        
        return true
    }
    
    func deleteAllConfigurationAndGroups() {
        try! realm?.write {
            realm?.deleteAllObjects()
        }
        
    }
    func deleteAllUserData() {        
        try! realm?.write {
            realm?.delete((realm?.allObjects(ofType: Runtime.self))!)
            realm?.delete((realm?.allObjects(ofType: Section.self))!)
            realm?.delete((realm?.allObjects(ofType: Member.self))!)
            realm?.delete((realm?.allObjects(ofType: Group.self))!)
            realm?.delete((realm?.allObjects(ofType: SpeciesObservation.self))!)
        }
    }
    
}
