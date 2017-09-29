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
    
    func nextPair() -> Pair? {
        // Fetching
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Pair")
        let sortByViewDate = NSSortDescriptor(key: "lastShown", ascending: true)
        let sortByViews = NSSortDescriptor(key: "shownTimes", ascending: true)
        
        request.sortDescriptors = [sortByViewDate, sortByViews]
        request.fetchLimit = 1
        
        let result = try? self.managedContext.fetch(request)
        
        if let res = result {
            if res.count == 0 {
                print("No records found")
                return nil
            }
            
            let pair = res[0] as! Pair
            pair.shownTimes += 1
            pair.lastShown = Date().timeIntervalSince1970
            
            // TODO: do not save context on each read
            do {
                try managedContext.save()
            } catch {
                print("Error saving context \(error.localizedDescription)")
            }
            
            print("Got pair: \(pair.displayText())")
            
            return pair
        }
        
        return nil
    }
    
    func importFromURL(_ url: URL) throws {
        if url.scheme == "file" {
            try self.importFromFile(url.path, params: parseUrlParams(url))
        } else {
            print("URL is not supported Yet \(url)")
        }
    }
    
    func importFromFile(_ fileName: String, params: [String:String]) throws {
        print("Importing file: \(fileName)")
        
        let fileContents = try? NSString(contentsOfFile:fileName, encoding: String.Encoding.utf8.rawValue)
        
        if let contents = fileContents {
            let fileLines = contents.components(separatedBy: "\n")
            print("Got \(fileLines.count) lines in file")
            
            //let langLine = fileLines[0]
            
            //fromLang: Language, toLang: Language,
            let fromLang = try findOrAddLang(params["from"] ?? "en")
            let toLang = try findOrAddLang(params["to"] ?? "uk")
            
            let allowedDelimeters = CharacterSet(charactersIn:":–=—")
            let spaces = CharacterSet.whitespaces
            
            var importedCount = 0
            
            for line in fileLines {
                let pairsArray = line.components(separatedBy: allowedDelimeters as CharacterSet)
                
                if pairsArray.count == 2 {
                    let words = pairsArray[0].components(separatedBy: ",")
                    let translations = pairsArray[1].components(separatedBy: ",")
                    
                    for w in words {
                        for t in translations {
                            let trimmedWord1 = w.trimmingCharacters(in: spaces)
                            let trimmedWord2 = t.trimmingCharacters(in: spaces)
                            
                            do {
                                if try !trimmedWord1.isEmpty && !trimmedWord2.isEmpty && addPair(word1: trimmedWord1, lang1: fromLang, word2: trimmedWord2, lang2: toLang) {
                                    importedCount = importedCount + 1
                                }
                            } catch {
                                print("Error storing word pair: \(error.localizedDescription) for words '\(trimmedWord1)' – '\(trimmedWord2)'")
                            }
                        }
                    }
                } else {
                    // skip empty lines
                    if !line.trimmingCharacters(in: NSCharacterSet.whitespaces).isEmpty {
                        print("Ignored line: \(line) with pairs: \(pairsArray.count)")
                    }
                }
            }        
            
            print("Imported \(importedCount) of total \(fileLines.count) lines from file: \(fileName)")
        }
    }
    
    func importFromLingualeo(login: String, pass: String) throws {
        let url = URL(string: "https://api.lingualeo.com/api/login")
        let json = ["username":login, "password": pass]
        
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: json, options: [])
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request as URLRequest){ data, response, error in
            if error != nil {
                print(error?.localizedDescription)
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                
                if let parseJSON = json {
                    let resultValue:String = parseJSON["success"] as! String;
                    print("result: \(resultValue)")
                    print(parseJSON)
                }
            } catch let error as NSError {
                print(error)
            }
        }
        
        task.resume()
        
        /*
        NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue.main) {(response, data, error) in
            print(data!)
            
          //curl -X POST -H 'Content-Type: application/json' --data '{ "page": "1", "sortBy": "date", "filter": "all", "groupId": "dictionary"}' https://lingualeo.com/userdict/json
        }*/
        
    }
    
    func addPair(word1: String, lang1: Language, word2: String, lang2: Language) throws -> Bool {
        let word1Entity = try findWord(word: word1, lang: lang1) ?? Word(word: word1, lang: lang1, context: managedContext)
        let word2Entity = try findWord(word: word2, lang: lang2) ?? Word(word: word2, lang: lang2, context: managedContext)
        
        let existingPair = try findPair(word1: word1Entity, word2: word2Entity)

        if (existingPair != nil) {
            return false
        }
        
        _ = Pair(word1: word1Entity, word2: word2Entity, context: managedContext)
        
        try managedContext.save()
        
        return true
    }
    
    func findPair(word1: Word, word2: Word) throws -> Pair? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Pair")
        request.predicate = NSPredicate(format: "word1 == %@ AND word2 == %@", word1, word2)
        
        let pairRes = try managedContext.fetch(request)
        
        if pairRes.count == 0 {
            return nil
        }
        
        return pairRes[0] as? Pair
    }
    
    func findWord(word: String, lang: Language) throws -> Word? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Word")
        request.predicate = NSPredicate(format: "word == %@", word)
        
        let wordsRes = try managedContext.fetch(request)
        
        if wordsRes.count == 0 {
            return nil
        }
            
        return wordsRes[0] as? Word
    }
    
    func findOrAddLang(_ iso: String) throws -> Language {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Language")
        request.predicate = NSPredicate(format: "iso == %@", iso)
        
        let langRes = try? managedContext.fetch(request)
        
        if let result = langRes {
            if result.count > 0 {
                return result[0] as! Language
            }
        }
        
        let l = Language(iso: iso, context: managedContext)
        
        try managedContext.save()
        
        return l
    }
    
    func countAll() throws -> Int {
        return try managedContext.count(for: NSFetchRequest<NSFetchRequestResult>(entityName: "Word"))
    }
    
    func removeAll() throws {
        let allWords = NSFetchRequest<NSFetchRequestResult>(entityName: "Word")
        allWords.includesPropertyValues = false

        let pairs = try self.managedContext.fetch(allWords)
        
        for p in pairs {
           managedContext.delete(p as! NSManagedObject)
        }
        
        try managedContext.save()
    }
    
    fileprivate func parseUrlParams(_ url: URL) -> [String : String] {
        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let itemsOpt = urlComponents?.queryItems

        var dict = [String: String]()
        
        if let items = itemsOpt {
            for item in items {
                dict[item.name] = item.value
            }
        }
        
        return dict
    }
}
