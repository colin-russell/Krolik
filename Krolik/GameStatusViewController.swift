//
//  GameStatusViewController.swift
//  Krolik
//
//  Created by Colin Russell, Mike Cameron, and Mike Stoltman
//  Copyright © 2018 Krolik Team. All rights reserved.
//

import UIKit
import FirebaseStorage

class GameStatusViewController: UIViewController, UICollectionViewDataSource {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    let networkManager = NetworkManager()
    var currentGame: Game?
    var currentPlayers: [Player] = []
    let database = DatabaseManager()
    let game = GameLogic()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.backgroundColor = UIColor(patternImage: UIImage(named: "corktexture")!)
        
        database.read(gameID: UserDefaults.standard.string(forKey: Game.keys.id)!) { (game) in
            guard let game = game else {
                print("game read returned nil value")
                return
            }
            self.currentGame = game
            self.checkGameState()
            
            let players = Array(game.players.keys)
            
            self.currentPlayers = []
            
            for player in players {
                self.database.read(playerID: player, completion: { (player) in
                    self.currentPlayers.append(player!)
                    self.collectionView.reloadData()
                })
            }
        }
    }
    
    //MARK: UICollectionViewMethods
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentPlayers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "playerCell", for: indexPath)
        cell.contentView.layer.borderWidth = 2
        cell.contentView.layer.cornerRadius = 15
        cell.contentView.layer.borderColor = UIColor.black.cgColor
        cell.layer.masksToBounds = true
        
        let cellFrame = cell.contentView.frame
        let imageFrame = CGRect(x: cellFrame.origin.x+10, y: cellFrame.origin.y+10, width: cellFrame.width-20, height: cellFrame.height-20)
        let imageView = UIImageView(frame: imageFrame)
        imageView.contentMode = .scaleAspectFit
        
        // if player dies change cell look
        let player = currentPlayers[indexPath.row]
        guard let playerState = currentGame?.players[player.id] else { return  cell }
        if  playerState == Player.state.dead {
            cell.contentView.layer.borderColor = UIColor.red.cgColor
        }
        
        networkManager.getDataFromUrl(url: URL(string: player.photoURL)!) { (data, response, error) in
            guard let imageData = data else {
                print("bad data")
                return
            }
            guard let image = UIImage(data: imageData) else {
                print("error creating image from data")
                return
            }
            DispatchQueue.main.async {
                imageView.image = image
                self.collectionView.cellForItem(at: indexPath)?.contentView.addSubview(imageView)
                
                // create/add pushpin to cell
                let pushpinView = UIImageView(image: UIImage(named: "pushpin"))
                let centerX = (cell.contentView.frame.size.width / 2) - 5
                cell.contentView.insertSubview(pushpinView, aboveSubview: imageView)
                pushpinView.frame.origin.x = centerX
            }
        }
        
        // rotate cell by random amount up to 20 degrees
        let rotate = collectionView.layoutAttributesForItem(at: indexPath)?.transform.rotated(by: randomRotation())
        cell.transform = rotate!
        
        cell.backgroundColor = UIColor.white
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "gameLobbyHeader", for: indexPath)
        
        let startButton = header.viewWithTag(1) as! UIButton
        let gameNameLabel = header.viewWithTag(2) as! UILabel
        let gameIDLabel = header.viewWithTag(3) as! UILabel
        
        if UserDefaults.standard.bool(forKey: Player.keys.owner) && currentGame?.state == Game.state.pending {
            startButton.isHidden = false
        }else {
            startButton.isHidden = true
        }
        
        gameNameLabel.text = "Game: \(currentGame?.name ?? "")"
        gameIDLabel.text = "ID: \(currentGame?.id ?? "")"
        
        header.backgroundColor = UIColor.white
        
        return header
    }
    
    func randomRotation() -> CGFloat {
        // get random degrees value
        var random = Double(arc4random_uniform(20))
        // convert to negative by random
        if arc4random_uniform(2) == 0 {
            random = random * -1
        }
        // convert to radians for rotation
        let radians = convertToRadians(value: random)
        return radians
    }
    
    func convertToRadians(value: Double) -> CGFloat {
        let degrees = value
        let radians = degrees * (Double.pi / 180)
        let converted = CGFloat(radians)
        return converted
    }
    
    //MARK: Actions
    
    @IBAction func startGameButtonTapped(_ sender: UIButton) {
        print("start game button tapped")
        if currentGame?.players.count == 1 {
            sender.isEnabled = true
            let singlePlayerAlert = UIAlertController(title: "", message: "Comrade, please recruit more civilians for cause.", preferredStyle: .alert)
            singlePlayerAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(singlePlayerAlert, animated: true, completion: nil)
        }else{
            game.currentGame = currentGame
            game.startGame()
            sender.isEnabled = false
        }
    }
    
    //MARK: Game Status
    
    func checkGameState() {
        if currentGame?.state == Game.state.pending {
            if let tabBarItems = self.tabBarController?.tabBar.items as AnyObject as? NSArray,let tabBarItem = tabBarItems[1] as? UITabBarItem {
                tabBarItem.isEnabled = false
                
            }
            
        }else if currentGame?.state == Game.state.active {
            if let tabBarItems = self.tabBarController?.tabBar.items as AnyObject as? NSArray,let tabBarItem = tabBarItems[1] as? UITabBarItem {
                tabBarItem.isEnabled = true
                
            }
            
        }else if currentGame?.state == Game.state.ended {
            if let tabBarItems = self.tabBarController?.tabBar.items as AnyObject as? NSArray,let tabBarItem = tabBarItems[1] as? UITabBarItem {
                tabBarItem.isEnabled = false
                endGameScreen()
            }
            
        }
    }
    
    //MARK: View Changes based on game state
    
    func endGameScreen() {
        
        
    }
    
}
