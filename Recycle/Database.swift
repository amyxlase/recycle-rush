import Foundation

class Database {
    
    let recyclable = ["Bottle", "Packaged goods", "Bottled and jarred packaged goods"]
    
    
    let compostable = ["food"]
    
    
    func contains(_ item: String) -> Int {
        
        if (recyclable.contains(item)) {
            return 1
        }
        
        if (compostable.contains(item)) {
                   return 2
               }
        
        return 0
    }
    
    
    
}
