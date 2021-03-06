//
//  IO.swift
//  RealmModelGenerator
//
//  Created by Brandon Erbschloe on 3/18/16.
//  Copyright © 2016 QuarkWorks. All rights reserved.
//

import Foundation

extension Schema {
    static let NAME = "name"
    static let MODELS = "models";
    
    func toDictionary() -> [String:Any] {
        return [
            Schema.NAME:self.name,
            Schema.MODELS:self.models.map({$0.toDictionary()})
        ]
    }
    
    func map(dictionary:[String:Any]) throws {
        guard let name = dictionary[Schema.NAME] as? String else {
            throw NSError(domain: Schema.TAG, code: 0, userInfo: nil)
        }
        
        guard let modelDicts = dictionary[Schema.MODELS] as? [[String:Any]] else {
            throw NSError(domain: Schema.TAG, code: 0, userInfo: nil)
        }
        
        self.name = name
        
        for modelDict in modelDicts {
            let model = self.createModel()
            try model.map(dictionary: modelDict, increaseVersion: false)
        }
    }
}

extension Model {
    static let VERSION = "version"
    static let IS_MODIFIABLE = "isModifiable"
    static let ENTITIES = "entities"
    
    func toDictionary() -> [String:Any] {
        return [
            Model.VERSION:self.version,
            Model.IS_MODIFIABLE:self.isModifiable,
            Model.ENTITIES:self.entities.map({$0.toDictionary()})
        ]
    }
    
    func map(dictionary:[String:Any], increaseVersion:Bool) throws {
        guard let version = dictionary[Model.VERSION] as? String else {
            throw NSError(domain: Model.TAG, code: 0, userInfo: nil)
        }
        
        guard let isModifiable = dictionary[Model.IS_MODIFIABLE] as? Bool else {
            throw NSError(domain: Model.TAG, code: 0, userInfo: nil)
        }
        
        guard let entitiesDict = dictionary[Model.ENTITIES] as? [[String:Any]] else {
            throw NSError(domain: Model.TAG, code: 0, userInfo: nil)
        }
        
        if !increaseVersion {
            self.setVersion(version: version)
        }
        
        self.isModifiable = isModifiable
        
        var entityPairs:[(Entity, [String:Any])] = []
        entityPairs.reserveCapacity(entitiesDict.count)
        for entityDict in entitiesDict{
            let entity = self.createEntity();
            try entity.mapValuesAndAttributes(dictionary: entityDict);
            entityPairs.append((entity, entityDict))
        }
        
        for entityPair in entityPairs {
            try entityPair.0.mapRelationshipsAndSuperEntity(dictionary: entityPair.1)
        }
    }
    
}

extension Entity {
    
    static let NAME = "name"
    static let PRIMARY_KEY = "primaryKey"
    static let SUPER_ENTITY = "superEntity"
    static let IS_BASE_CLASS = "isBaseClass"
    static let ATTRIBUTES = "attributes"
    static let RELATIONSHIPS = "relationships"
    
    func toDictionary() -> [String:Any] {
        let superEntity:Any = self.superEntity?.name ?? NSNull()
        let primaryKey:Any = self.primaryKey?.name ?? NSNull()
        
        return [
            Entity.NAME:name,
            Entity.PRIMARY_KEY:primaryKey,
            Entity.SUPER_ENTITY:superEntity,
            Entity.IS_BASE_CLASS:self.isBaseClass,
            Entity.ATTRIBUTES:self.attributes.map({$0.toDictionary()}),
            Entity.RELATIONSHIPS:self.relationships.map({$0.toDictionary()})
        ]
    }
    
    func mapValuesAndAttributes(dictionary:[String:Any]) throws {
        guard let name = dictionary[Entity.NAME] as? String else {
            throw NSError(domain:Attribute.TAG, code: 0, userInfo: nil)
        }
        
        try self.setName(name: name)
        
        if let isBaseClass = dictionary[Entity.IS_BASE_CLASS] as? Bool {
            self.isBaseClass = isBaseClass
        }
        
        guard let attributes = dictionary[Entity.ATTRIBUTES] as? [[String:Any]] else {
            throw NSError(domain:Attribute.TAG, code: 0, userInfo: nil)
        }
        
        let primaryKey = dictionary[Entity.PRIMARY_KEY] as? String
        for attributeDict in attributes {
            let attribute = self.createAttribute()
            try attribute.map(dictionary: attributeDict)
            if primaryKey != nil && attribute.name == primaryKey {
                try self.setPrimaryKey(primaryKey: attribute)
            }
        }
    }
    
    func mapRelationshipsAndSuperEntity(dictionary:[String:Any]) throws {
        let superEntityName = dictionary[Entity.SUPER_ENTITY] as? String
        var superEntity:Entity? = nil;
        if superEntityName != nil && !superEntityName!.isEmpty {
            superEntity = self.model.entitiesByName[superEntityName!]
            if superEntity == nil {
                throw NSError(domain: Entity.TAG, code: 0, userInfo: nil)
            }
        }
        
        self.superEntity = superEntity;
        
        if let relationshipsArrayDict = dictionary[Entity.RELATIONSHIPS] as? [[String:Any]] {
            for relationshipDict in relationshipsArrayDict {
                let relationship = self.createRelationship()
                try relationship.map(dictionary: relationshipDict)
            }
        }
        
    }
}

extension Attribute {
    
    static let NAME = "name"
    static let IS_IGNORED = "isIgnored"
    static let IS_INDEXED = "isIndexed"
    static let IS_REQUIRED = "isRequired"
    static let HAS_DEFAULT = "hasDefault"
    static let DEFAULT_VALUE = "defaultValue"
    static let TYPE = "type"
    
    func toDictionary() -> [String:Any] {
        return [
            Attribute.NAME:name,
            Attribute.IS_IGNORED:isIgnored,
            Attribute.IS_INDEXED:isIndexed,
            Attribute.IS_REQUIRED:isRequired,
            Attribute.HAS_DEFAULT:hasDefault,
            Attribute.DEFAULT_VALUE:defaultValue,
            Attribute.TYPE:type.rawValue
        ]
    }
    
    func map(dictionary:[String:Any]) throws {
        guard let name = dictionary[Attribute.NAME] as? String else {
            throw NSError(domain:Attribute.TAG, code: 0, userInfo: nil)
        }
        
        try self.setName(name: name)
        
        if let rawType = dictionary[Attribute.TYPE] as? String {
            self.type = AttributeType(rawValueSafe: rawType)
        }
        
        if let isIgnored = dictionary[Attribute.IS_IGNORED] as? Bool {
            self.isIgnored = isIgnored
        }
        
        if let isIndexed = dictionary[Attribute.IS_INDEXED] as? Bool {
            do {
                try self.setIndexed(isIndexed: isIndexed)
            } catch {
                self.removeIndexed()
            }
        }
        
        if let isRequired = dictionary[Attribute.IS_REQUIRED] as? Bool {
            self.isRequired = isRequired
        }
        
        if let hasDefault = dictionary[Attribute.HAS_DEFAULT] as? Bool {
            self.hasDefault = hasDefault
        }
        
        if let defaultValue = dictionary[Attribute.DEFAULT_VALUE] as? String {
            self.defaultValue = defaultValue
        }
    }
}

extension Relationship {
    static let NAME = "name"
    static let DESTINATION = "destination"
    static let IS_MANY = "isMany"
    
    func toDictionary() -> [String:Any] {
        let destinationName:Any = (self.destination != nil ? self.destination!.name : NSNull())
        return [
            Relationship.NAME:self.name,
            Relationship.DESTINATION:destinationName,
            Relationship.IS_MANY:self.isMany
        ]
    }
    
    func map(dictionary:[String:Any]) throws {
        guard let name = dictionary[Relationship.NAME] as? String else {
            throw NSError(domain: Relationship.TAG, code: 0, userInfo: nil)
        }
        try self.setName(name: name)
        
        if let isMany = dictionary[Relationship.IS_MANY] as? Bool {
            self.isMany = isMany
        }
        
        // EDITMARK  don't know about this.
        if let destinationName = dictionary[Relationship.DESTINATION] as? String {
                self.destination = self.entity.model.entitiesByName[destinationName]
        } else {
            destination = nil
        }
    }
}
