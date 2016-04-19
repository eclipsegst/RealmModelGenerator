//
//  RelationshipsViewController.swift
//  RealmModelGenerator
//
//  Created by Zhaolong Zhong on 3/31/16.
//  Copyright © 2016 QuarkWorks. All rights reserved.
//

import Cocoa

protocol RelationshipsVCDelegate: class {
    func relationshipsVC(relationshipsVC: RelationshipsVC, selectedRelationshipDidChange relationship:Relationship?)
}

class RelationshipsVC: NSViewController, RelationshipsViewDelegate, RelationshipsViewDataSource, Observer {
    static let TAG = NSStringFromClass(RelationshipsVC)

    private var entityNameList:[String] = ["None"]
    
    @IBOutlet weak var relationshipsView: RelationshipsView! {
        didSet {
            self.relationshipsView.delegate = self
            self.relationshipsView.dataSource = self
        }
    }

    weak var selectedEntity: Entity? {
        didSet {
            if oldValue === self.selectedEntity { return }
            oldValue?.observable.removeObserver(self)
            self.selectedEntity?.observable.addObserver(self)
            selectedRelationship = nil
            self.invalidateViews()
        }
    }
    
    private weak var selectedRelationship: Relationship? {
        didSet {
            if oldValue === self.selectedRelationship { return }
            invalidateSelectedIndex()
            self.delegate?.relationshipsVC(self, selectedRelationshipDidChange: self.selectedRelationship)
        }
    }
    
    private var acending:Bool = true {
        didSet{ self.invalidateViews() }
    }
    
    private var isSortByDestination = false {
        didSet{ self.invalidateViews() }
    }
    
    private var isSortedByColumnHeader = false
    
    weak var delegate: RelationshipsVCDelegate?
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func onChange(observable: Observable) {
        self.invalidateViews()
    }
    
    func invalidateViews() {
        if !self.viewLoaded { return }
        updateDestinationList()
        updateItemOrder()
        self.relationshipsView.reloadData()
        invalidateSelectedIndex()
    }
    
    func invalidateSelectedIndex() {
        self.relationshipsView.selectedIndex = self.selectedEntity?.relationships.indexOf({$0 === self.selectedRelationship})
    }
    
    //MARK: - Update selected relationship after its detail changed
    func updateSelectedRelationship(selectedRelationship: Relationship) {
        self.selectedRelationship = selectedRelationship
        invalidateViews()
    }
    
    func updateDestinationList() {
        self.entityNameList = ["None"]
        self.selectedEntity?.model.entities.forEach{(e) in entityNameList.append(e.name)}
        self.relationshipsView.destinationNames = entityNameList
    }
    
    func updateItemOrder() {
        guard let selectedEntity = self.selectedEntity else {
            return
        }
        if !isSortedByColumnHeader { return }
        
        if acending {
            if isSortByDestination {
                selectedEntity.relationships.sortInPlace{ (e1, e2) -> Bool in
                    if let destination1 = e1.destination, destination2 = e2.destination {
                        return destination1.name < destination2.name
                    } else if let destination1 = e1.destination {
                        return destination1.name < entityNameList[0]
                    } else if let destination2 = e2.destination {
                        return entityNameList[0] < destination2.name
                    } else {
                        return true
                    }
                }
            } else {
                selectedEntity.relationships.sortInPlace{ (e1, e2) -> Bool in
                    return e1.name < e2.name
                }
            }
        } else {
            if isSortByDestination {
                selectedEntity.relationships.sortInPlace{ (e1, e2) -> Bool in
                    if let destination1 = e1.destination, destination2 = e2.destination {
                        return destination1.name > destination2.name
                    } else if let destination1 = e1.destination {
                        return destination1.name > entityNameList[0]
                    } else if let destination2 = e2.destination {
                        return entityNameList[0] > destination2.name
                    } else {
                        return true
                    }
                }
            } else {
                selectedEntity.relationships.sortInPlace{ (e1, e2) -> Bool in
                    return e1.name > e2.name
                }
            }
        }
    }
    
    //MARK: - RelationshipsViewDataSource
    func numberOfRowsInRelationshipsView(relationshipsView: RelationshipsView) -> Int {
        return self.selectedEntity == nil ? 0 : self.selectedEntity!.relationships.count
    }
    
    func relationshipsView(relationshipsView: RelationshipsView, titleForRelationshipAtIndex index: Int) -> String {
        return self.selectedEntity!.relationships[index].name
    }
    
    func relationshipsView(relationshipsView: RelationshipsView, destinationForRelationshipAtIndex index: Int) -> String {
        if let destination = self.selectedEntity?.relationships[index].destination {
            return destination.name
        } else {
            return entityNameList[0]
        }
    }
    
    //MAKR: - RelationshipsViewDelegate
    func addRelationshipInRelationshipsView(relationshipsView: RelationshipsView) {
        if self.selectedEntity != nil {
            let relationship = self.selectedEntity!.createRelationship()
            self.selectedRelationship = relationship
        }
    }
    
    func relationshipsView(relationshipsView: RelationshipsView, removeRelationshipAtIndex index: Int) {
        let relationship = self.selectedEntity!.relationships[index]
        if relationship === self.selectedRelationship {
            if self.selectedEntity?.relationships.count <= 1 {
                self.selectedRelationship = nil
            } else if index == self.selectedEntity!.relationships.count - 1 {
                self.selectedRelationship = self.selectedEntity?.relationships[index - 1]
            } else {
                self.selectedRelationship = self.selectedEntity?.relationships[index + 1]
            }
        }
        
        self.selectedEntity!.removeRelationship(relationship)
    }
    
    func relationshipsView(relationshipsView: RelationshipsView, selectedIndexDidChange index: Int?) {
        if let index = index {
            self.selectedRelationship = self.selectedEntity?.relationships[index]
        } else {
            self.selectedRelationship = nil
        }
    }
    
    func relationshipsView(relationshipsView: RelationshipsView, shouldChangeRelationshipName name: String, atIndex index: Int) -> Bool {
        let relationship = selectedEntity!.relationships[index]
        do {
            try relationship.setName(name)
        } catch {
            Tools.popupAllert("Error", buttonTitile: "OK", informativeText: "Unable to rename relationship: \(relationship.name) to: \(name). There is a relationship with the same name.")
            return false
        }
        return true
    }
    
    func relationshipsView(relationshipsView: RelationshipsView, atIndex index: Int, changeDestination destinationName: String) {
        let destination = selectedEntity?.model.entities.filter({$0.name == destinationName}).first
        self.selectedEntity?.relationships[index].destination = destination
    }
    
    func relationshipsView(relationshipsView: RelationshipsView, sortByColumnName name: String, ascending: Bool) {
        self.isSortedByColumnHeader = true
        self.acending = ascending
        self.isSortByDestination = name == RelationshipsView.DESTINATION_COLUMN ? true : false
    }
    
    func relationshipsView(relationshipsView: RelationshipsView, dragFromIndex: Int, dropToIndex: Int) {
        guard let selectedEntity = self.selectedEntity else {
            return
        }
        
        self.isSortedByColumnHeader = false
        let draggedAttribute = selectedEntity.relationships[dragFromIndex]
        selectedEntity.relationships.removeAtIndex(dragFromIndex)
        
        if dropToIndex >= self.selectedEntity?.relationships.count {
            selectedEntity.relationships.insert(draggedAttribute, atIndex: dropToIndex - 1)
        } else {
            selectedEntity.relationships.insert(draggedAttribute, atIndex: dropToIndex)
        }
        
        invalidateViews()
    }
}