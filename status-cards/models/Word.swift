//
//  Word.swift
//  status-cards
//
//  Created by Sergey Khruschak on 4/6/15.
//  Copyright (c) 2015 Sergey Khruschak. All rights reserved.
//

import Foundation
import CoreData

@objc(Word)
class Word: NSManagedObject {

    @NSManaged var word: String
    @NSManaged var language: Language

    convenience init(word: String, lang: Language, context: NSManagedObjectContext) {
        self.init(entity: NSEntityDescription.entity(forEntityName: "Word", in: context)!, insertInto: context)
        self.word = word
        self.language = lang
    }
    
}
