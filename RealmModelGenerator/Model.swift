//
//  Schema.swift
//  RealmModelGenerator
//
//  Created by Brandon Erbschloe on 3/2/16.
//  Copyright © 2016 QuarkWorks. All rights reserved.
//

import Foundation

class Model {
    static let TAG = NSStringFromClass(Model)
    
    private(set) var version:String
    private(set) var entities:[Entity] = []
    var entitiesByName:[String:Entity] {
        get {
            var entitiesByName = [String:Entity](minimumCapacity:self.entities.count)
            for entity in self.entities {
                entitiesByName[entity.name] = entity
            }
            return entitiesByName
        }
    }
    
    internal init(version:String) {
        self.version = version
    }
    
    func createEntity(build:(Entity)->Void = {_ in}) -> Entity  {
        var name = "Entity"
        var count = 0;
        while entities.contains({$0.name == name}) {
            count++
            name = "Entity\(count)"
        }
        
        let entity = Entity(name:name, model:self)
        entities.append(entity)
        build(entity)
        return entity
    }
    
    func removeEntity(entity:Entity) {
        if let index = entities.indexOf({$0 === entity}) {
            entities.removeAtIndex(index)
        }
    }
    
    func setVersion(version:String) throws {
        self.version = version;
    }
    
}