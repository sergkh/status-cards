//
//  DictionaryManager.swift
//  status-cards
//
//  Created by Sergey Khruschak on 4/2/15.
//  Copyright (c) 2015 Sergey Khruschak. All rights reserved.
//

import Cocoa

class DictionaryManager {
    let managedContext: NSManagedObjectContext;
    
    init(context: NSManagedObjectContext) {
        self.managedContext = context
    }
    
    func nextPair() -> Word? {
        // Fetching
        let request = NSFetchRequest(entityName: "Word")
        let sortByViewDate = NSSortDescriptor(key: "lastShown", ascending: true)
        let sortByViews = NSSortDescriptor(key: "shownTimes", ascending: true)
        
        request.sortDescriptors = [sortByViewDate, sortByViews]
        request.fetchLimit = 1
        
        var error: NSError?
        
        let result = self.managedContext.executeFetchRequest(request, error: &error)
        
        if let err = error {
            println("Error fetching data \(err) \(err.localizedDescription)")
            return nil
        }
        
        if let res = result {
            if res.count == 0 {
                println("No records found")
                return nil
            }
            
            let word = res[0] as! Word
            word.shownTimes += 1
            word.lastShown = NSDate().timeIntervalSince1970
            
            managedContext.save(&error)

            if let err = error {
                println("Unable to update managed object context \(err): \(err.localizedDescription)")
            }
            
            println("Got word: \(word.word)")
            
            return word;
        }
        
        return nil
    }
    
    func importFromURL(url: NSURL, error: NSErrorPointer) {
        if url.scheme == "file" {
            self.importFromFile(url.path!, params: parseUrlParams(url), error: error)
        } else {
            println("URL is not supported Yet \(url)")
        }
    }
    
    func importFromFile(fileName: String, params: [String:String], error: NSErrorPointer) {
        println("Importing file: \(fileName)")
    
        let fileContents = NSString(contentsOfFile:fileName, encoding: NSUTF8StringEncoding, error:error)
        
        if let err = error.memory {
            println("Error reading file: \(fileName), error \(err) : \(err.localizedDescription)")
        }

        if let contents = fileContents {
            let fileLines = contents.componentsSeparatedByString("\n")
            println("Got \(fileLines.count) lines in file")
            
            //let langLine = fileLines[0]
            
            //fromLang: Language, toLang: Language,
            let fromLang = findOrAddLang(params["from"] ?? "en")
            let toLang = findOrAddLang(params["to"] ?? "uk")
            
            let allowedDelimeters = NSCharacterSet(charactersInString:":–=—")
            let spaces = NSCharacterSet.whitespaceCharacterSet()
            
            var importedCount = 0
            
            for line in fileLines {
                let pairsArray = line.componentsSeparatedByCharactersInSet(allowedDelimeters) as! Array<String>
                
                if pairsArray.count == 2 {
                    let words = pairsArray[0].componentsSeparatedByString(",")
                    let translations = pairsArray[1].componentsSeparatedByString(",")
                    
                    for w in words {
                        for t in translations {
                            let word = Word(word: w.stringByTrimmingCharactersInSet(spaces), lang: fromLang, context: managedContext)
                            let translation = Word(word: t.stringByTrimmingCharactersInSet(spaces), lang: toLang, context: managedContext)
                            
                            if addPair(word, translation: translation, error:error) {
                                importedCount++;
                            }
                        }
                    }
                } else {
                    // skip empty lines
                    if !line.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).isEmpty {
                        println("Ignored line: \(line) with pairs: \(pairsArray.count)")
                    }
                }
            }
            
            println("Imported \(importedCount) of total \(fileLines.count) lines from file: \(fileName)")
        }
    }
    
    func addPair(word: Word, translation: Word, error: NSErrorPointer) -> Bool {
        let storedWord = findWord(word.word, lang: word.language)
        let translationRecord = findWord(translation.word, lang: translation.language) ?? translation
        
        (storedWord ?? word).translation.addObject(translationRecord)

        managedContext.save(error);
        
        return (storedWord == nil)
    }
    
    func findWord(word: String, lang: Language) -> Word? {
        let request = NSFetchRequest(entityName: "Word")
        request.predicate = NSPredicate(format: "word=%@", argumentArray: [word])
        
        let wordsRes = managedContext.executeFetchRequest(request, error: nil);
        
        if let result = wordsRes {
            if result.count == 0 {
                return nil
            }
            
            return result[0] as? Word
        }
        
        return nil;
    }
    
    func findOrAddLang(iso: String) -> Language {
        let request = NSFetchRequest(entityName: "Language")
        request.predicate = NSPredicate(format: "iso=%@", argumentArray: [iso])
        
        let langRes = managedContext.executeFetchRequest(request, error: nil);
        
        if let result = langRes {
            if result.count > 0 {
                return result[0] as! Language
            }
        }
        
        let l = Language(iso: iso, context: managedContext)
        
        managedContext.save(nil)
        
        return l
    }
    
    func removeAll() {
        let allWords = NSFetchRequest(entityName: "Word")
        allWords.includesPropertyValues = false

        var error: NSError? = nil
        let pairs = self.managedContext.executeFetchRequest(allWords, error: &error)
        
        for p in pairs! {
            managedContext.deleteObject(p as! NSManagedObject)
        }
        
        managedContext.save(&error)
    }
    
    private func parseUrlParams(url: NSURL) -> [String : String] {
        let urlComponents = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)
        let itemsOpt = urlComponents?.queryItems as? [NSURLQueryItem]

        var dict = [String: String]()
        
        if let items = itemsOpt {
            for item in items {
                dict[item.name] = item.value()
            }
        }
        
        return dict
    }
}
