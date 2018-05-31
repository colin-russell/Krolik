//
//  ViewController.swift
//  Krolik
//
//  Created by Mike Stoltman, Mike Cameron, and Colin Russell
//  Copyright © 2018 Krolik Team. All rights reserved.
//

import UIKit
import FirebaseDatabase

class ViewController: UIViewController {

    var databaseRef: DatabaseReference!
    var gameRef: DatabaseReference!
    var playerRef: DatabaseReference!
    var players = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        databaseRef = Database.database().reference()
        gameRef = Database.database().reference().child("games")
        playerRef = Database.database().reference().child("players")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

// MARK: Database functions

extension ViewController {
    
    func addPlayer() {
        let newPlayerKey = playerRef.childByAutoId().key
        
        var player = [String:Any?]()
        player["player_id"] = newPlayerKey
        player["target_id"] = "none"
        player["player_nickname"] = "Player Nickname"
        player["player_state"] = "alive"
        player["device_id"] = "INSERT DEVICE ID"
        player["photo_url"] = "INSERT URL"
        
        playerRef.child(newPlayerKey).setValue(player)
        players.append(newPlayerKey)
        
        print("player added with key \(newPlayerKey)")
    }
    
    func startGame() {
        let shuffledPlayers = players.shuffled()
        
        var targetsUpdate = [String:String]()
        
        for i in 0..<shuffledPlayers.count {
            if i == (shuffledPlayers.count - 1) {
                targetsUpdate["\(shuffledPlayers[i])/target_id/"] = shuffledPlayers[0]
            }else{
                targetsUpdate["\(shuffledPlayers[i])/target_id/"] = shuffledPlayers[i+1]
            }
        }
        
        playerRef.updateChildValues(targetsUpdate)
        
        let newGameKey = gameRef.childByAutoId().key
        var game = [String:Any?]()
        game["game_id"] = newGameKey
        game["game_name"] = "Odessa Chronicles"
        game["game_players"] = players
        gameRef.child(newGameKey).setValue(game)
    }
}

// MARK: Functions for shuffling

extension MutableCollection {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            // Change `Int` in the next line to `IndexDistance` in < Swift 4.1
            let d: Int = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            let i = index(firstUnshuffled, offsetBy: d)
            swapAt(firstUnshuffled, i)
        }
    }
}

extension Sequence {
    /// Returns an array with the contents of this sequence, shuffled.
    func shuffled() -> [Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}
