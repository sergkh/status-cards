//
//  Language.swift
//  status-cards
//
//  Created by Sergey Khruschak on 4/6/15.
//  Copyright (c) 2015 Sergey Khruschak. All rights reserved.
//

import Foundation
import CoreData

@objc(Language)
class Language: NSManagedObject {

    @NSManaged var iso: String
    @NSManaged var native: Bool
    @NSManaged var pairs: NSSet
    
    convenience init(iso: String, context: NSManagedObjectContext!) {
        self.init(entity: NSEntityDescription.entity(forEntityName: "Language", in: context)!, insertInto: context)
        self.iso = iso
    }
}
