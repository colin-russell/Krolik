//
//  DatabaseManager.swift
//  Krolik
//
//  Created by Colin Russell, Mike Cameron, and Mike Stoltman
//  Copyright © 2018 Krolik Team. All rights reserved.
//

import Firebase

protocol DatabaseDelegate {
    func readGame(game: Game)
    func readPlayer(player: Player)
}

class DatabaseManager {
    
    // MARK: PROPERTIES
    
    var databaseRef: DatabaseReference!
    var delegate: DatabaseDelegate?
    
    // MARK: CREATE
    
    // CREATE GAME
    func create(game: Game) {
        // create reference to games root folder
        let gamesRef = databaseRef.child(Game.keys.root)
        
        // get random key for new game
        let newGameKey = gamesRef.childByAutoId().key
        
        // create gameData dictionary using game properties
        var gameData = [String:Any?]()
        gameData[Game.keys.id] = newGameKey
        gameData[Game.keys.name] = Game.generateGameName()
        gameData[Game.keys.players] = []
        
        // create the game on the firebase database
        gamesRef.child(newGameKey).setValue(gameData)
    }
    
    // CREATE PLAYER
    func create(player: Player, gameID: String) {
        // create reference to players root folder
        let playersRef = databaseRef.child(Player.keys.root)
        
        // get random key for new player
        let newPlayerKey = playersRef.childByAutoId().key
        
        // create playerData dictionary using player properties
        var playerData = [String:Any?]()
        playerData[Player.keys.id] = newPlayerKey
        playerData[Game.keys.id] = gameID
        playerData[Player.keys.target] = "***INSERT TARGET***"
        playerData[Player.keys.nickname] = Player.generatePlayerName()
        playerData[Player.keys.state] = Player.state.alive
        playerData[Player.keys.device] = "***INSERT DEVICE ID***"
        playerData[Player.keys.device] = "***INSERT URL***"
        
        // create the player on firebase database
        playersRef.child(newPlayerKey).setValue(player)
        
        // print statement to confirm addition of new player with unique key
        print("player added with key \(newPlayerKey)")
    }
    
    // MARK: READ
    
    // READ GAME
    func read(gameID: String) {
        // create reference to games root folder
        let gamesRef = databaseRef.child(Game.keys.root)
        
        // get data snapshot of database
        gamesRef.child(gameID).observe(.value) { [weak self] (snapshot) in
            // convert snapshot to dictionary
            guard let gameData = snapshot.value as? [String:Any] else {
                print("error converting game snapshot to dictionary")
                return
            }
            
            // create game object using data from dictionary
            let game = Game()
            
            game.name = gameData[Game.keys.name] as? String
            game.id = gameData[Game.keys.id] as? String
            game.players = gameData[Game.keys.players] as! [String]
            
            // pass created game to delegate
            guard let delegate = self?.delegate else {
                print("error, no delegate")
                return
            }
            delegate.readGame(game: game)
        }
    }
    
    // READ PLAYER
    func read(playerID: String) {
        // create reference to players root folder
        let playersRef = databaseRef.child(Player.keys.root)
        
        // get data snapshot of database
        playersRef.child(playerID).observe(.value) { [weak self] (snapshot) in
            // convert snapshot to dictionary
            guard let playerData = snapshot.value as? [String:Any?] else {
                print("error converting player snapshot to dictionary")
                return
            }
            
            // create player object using data from dictionary
            let player = Player()
            
            player.nickname = playerData[Player.keys.nickname] as? String
            player.id = playerData[Player.keys.id] as? String
            player.target = playerData[Player.keys.target] as? String
            player.state = playerData[Player.keys.state] as? String
            player.device = playerData[Player.keys.device] as? String
            
            // pass created player to delegate
            guard let delegate = self?.delegate else {
                print("error, no delegate")
                return
            }
            delegate.readPlayer(player: player)
        }
    }
    
    // READ GAME HISTORY
    func read(historicalID: String) {
        // create reference to games history root folder
        let historyRef = databaseRef.child(Game.keys.history)
        
        // get data snapshot of database
        historyRef.child(historicalID).observe(.value) { [weak self] (snapshot) in
            // convert snapshot to dictionary
            guard let historyData = snapshot.value as? [String:Any] else {
                print("error converting game history snapshot to dictionary")
                return
            }
            
            // create game object using data from dictionary
            let game = Game()
            
            game.name = historyData[Game.keys.name] as? String
            game.id = historyData[Game.keys.id] as? String
            game.players = historyData[Game.keys.players] as! [String]
            game.created = historyData[Game.keys.created] as? Date
            game.ended = historyData[Game.keys.ended] as? Date
            
            // pass created game to delegate
            guard let delegate = self?.delegate else {
                print("error, no delegate")
                return
            }
            delegate.readGame(game: game)
        }
    }
    
    // MARK: UPDATE
    
    // UPDATE GAME
    func update(gameID: String, update: Dictionary<String, Any>) {
        // create reference to games root folder
        let gamesRef = databaseRef.child(Game.keys.root)
        
        // create reference to specific game via ID
        let gameRef = gamesRef.child(gameID)
        
        // update values based on dictionary
        gameRef.updateChildValues(update)
    }
    
    // UPDATE PLAYER
    func update(playerID: String, update: Dictionary<String, Any>) {
        // create reference to players root folder
        let playersRef = databaseRef.child(Player.keys.root)
        
        // create reference to specific player via ID
        let playerRef = playersRef.child(playerID)
        
        // update values based on dictionary
        playerRef.updateChildValues(update)
    }
    
    // MARK: DELETE
    
    // DELETE GAME
    func delete(gameID: String) {
        // create reference to games root folder
        let gamesRef = databaseRef.child(Game.keys.root)
        
        // get data snapshot of database
        gamesRef.child(gameID).observe(.value) { [weak self] (snapshot) in
            // convert snapshot to dictionary
            guard let gameData = snapshot.value as? [String:Any] else {
                print("error converting game snapshot to dictionary")
                return
            }
            
            // read players list from game
            let players = gameData[Game.keys.players] as! [String]
            
            // delete all players that were created for the game
            for player in players {
                self?.delete(playerID: player)
            }
            
            // delete all values associated to specified game from database
            gamesRef.child(gameID).removeValue()
        }
    }
    
    // DELETE PLAYER
    func delete(playerID: String) {
        // create reference to players root folder
        let playersRef = databaseRef.child(Player.keys.root)
        
        // delete all values associated to specified player from database
        playersRef.child(playerID).removeValue()
    }
    
    // MARK: BACKUP HISTORY
    
    func backupData(gameID: String) {
        // create reference to games root folder
        let gamesRef = databaseRef.child(Game.keys.root)
        
        // get data snapshot of database
        gamesRef.child(gameID).observe(.value) { [weak self] (snapshot) in
            // convert snapshot to dictionary
            guard let gameData = snapshot.value as? [String:Any] else {
                print("error converting game snapshot to dictionary")
                return
            }
           
            let historyRef = self?.databaseRef.child(Game.keys.history)
            historyRef?.setValuesForKeys(gameData)
        
        }
    }
}