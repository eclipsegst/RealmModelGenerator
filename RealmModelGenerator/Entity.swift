//
//  Entity.swift
//  RealmModelGenerator
//
//  Created by Brandon Erbschloe on 3/2/16.
//  Copyright © 2016 QuarkWorks. All rights reserved.
//

import Foundation

class Entity {
    static let TAG = NSStringFromClass(Entity.self)
    
    private(set) var name:String
    internal(set) weak var model:Model!
    weak var superEntity: Entity? = nil
    var isBaseClass = false
    
    private(set) weak var primaryKey:Attribute?
    
    internal(set) var attributes:[Attribute] = []
    var attributesByName:[String:Attribute] {
        get {
            var attributesByName = [String:Attribute](minimumCapacity:self.attributes.count)
            for attribute in self.attributes {
                attributesByName[attribute.name] = attribute
            }
            return attributesByName
        }
    }
    
    internal(set) var relationships:[Relationship] = [] 
    var relationshipsByName:[String:Relationship] {
        get {
            var relationshipsByName = Dictionary<String, Relationship>(minimumCapacity:self.relationships.count)
            for relationship in self.relationships {
                relationshipsByName[relationship.name] = relationship
            }
            return relationshipsByName
        }
    }
    
    let observable:Observable
    
    internal init(name:String, model:Model) {
        self.name = name
        self.model = model
        self.observable = DeferredObservable(observable: model.observable)
    }
    
    func createAttribute() -> Attribute {
        return createAttribute(build: {_ in})
    }
    
    func createAttribute( build: (Attribute) throws -> Void) rethrows -> Attribute {
        var name = "Attribute"
        var count = 0
        while attributes.contains(where: {$0.name == name}) {
            count += 1
            name = "Attribute\(count)"
        }
        
        let attribute = Attribute(name:name, entity:self)
        defer {
            if !attributes.contains(where: {$0 === attribute}) {
                attribute.entity = nil
            }
        }
        try build(attribute)
        attributes.append(attribute)
        self.observable.notifyObservers()
        
        return attribute;
    }
    
    func setName(name:String) throws {
        if name.isEmpty {
            throw NSError(domain: Attribute.TAG, code: 0, userInfo: nil)
        }
        
        if model.entities.filter({$0.name == name && $0 !== self}).count > 0 {
            throw NSError(domain: Entity.TAG, code: 0, userInfo: nil)
        }
        
        self.name = name
        self.observable.notifyObservers()
    }
    
    func setPrimaryKey(primaryKey:Attribute?) throws {
        if primaryKey != nil {
            if !primaryKey!.type.canBePrimaryKey() || primaryKey!.entity !== self {
                throw NSError(domain: Entity.TAG, code: 0, userInfo:nil)
            }
        }
        
        self.primaryKey = primaryKey
        try! self.primaryKey?.setIndexed(isIndexed: true)
        self.observable.notifyObservers()
    }
    
    func removeAttribute(attribute:Attribute) {
        attribute.entity = nil
        if self.primaryKey  === attribute {
            self.primaryKey = nil
        }
        
        if let index = attributes.index(where: {$0 === attribute}) {
            attributes.remove(at: index)
        }
        
        self.observable.notifyObservers()
    }
    
    func createRelationship() -> Relationship {
        return createRelationship(build: {_ in})
    }
    
    func createRelationship( build: (Relationship) throws -> Void) rethrows -> Relationship {
        var name = "Relationship"
        var count = 0
        
        while relationships.contains(where: {$0.name == name}) {
            count += 1
            name = "Relationship\(count)"
        }
        
        let relationship = Relationship(name: name, entity: self)
        defer {
            if !relationships.contains(where: {$0 === relationship}) {
                relationship.entity = nil
            }
        }
        
        try build(relationship)
        relationships.append(relationship)
        self.observable.notifyObservers()
        
        return relationship
    }
    
    func removeRelationship(relationship:Relationship) {
        relationship.entity = nil
        relationship.destination = nil
        
        if let index = relationships.index(where: {$0 === relationship}) {
            relationships.remove(at: index)
        }
        
        self.observable.notifyObservers()
    }
    
    func removeFromModel() {
        self.model.removeEntity(entity: self)
        self.observable.notifyObservers()
    }
    
    func isDeleted() -> Bool {
        return self.model == nil
    }
}
