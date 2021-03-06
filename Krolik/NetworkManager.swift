//
//  NetworkManager.swift
//  Krolik
//
//  Created by Colin on 2018-06-01.
//  Copyright © 2018 Mike Stoltman. All rights reserved.
//

import UIKit
import FirebaseStorage

class NetworkManager {
    
    func getDataFromUrl(url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            completion(data, response, error)
            }.resume()
    }
    
    func uploadPhoto(photo: UIImage, path: String, completion: @escaping (_ photoURL: URL, Error?) -> ()) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        guard let photoData = UIImageJPEGRepresentation(photo, 1.0) else {
            print("photo data conversion ERROR")
            return
        }
        
        let photoRef = storageRef.child(path)
        let _ = photoRef.putData(photoData, metadata: nil) { (metadata, error) in
            photoRef.downloadURL(completion: { (url, error) in
                guard let downloadURL = url else {
                    print("ERROR getting photo url from Firebase")
                    return
                }
                completion(downloadURL, error)
            })
        }
    }
    
    func checkPhotoFace(photoURL: String, completion: @escaping (_ isFace: Bool, _ multipleFaces: Bool) -> ()) {
        guard let url = URL(string: "https://api.kairos.com/detect") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("48f9a54e", forHTTPHeaderField: "app_id")
        request.addValue("f9da2200327fdab7f1848c77ced880df", forHTTPHeaderField: "app_key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let data = ["image" : photoURL]
        let jsonData = try? JSONSerialization.data(withJSONObject: data)
        request.httpBody = jsonData
        let dataTask = URLSession(configuration: URLSessionConfiguration.default).dataTask(with: request) { (data, urlResponse, error) in
            
            guard let responseData = data else {
                print(error as? String ?? "no error")
                completion(false, false)
                return
            }
            guard let results = try? JSONSerialization.jsonObject(with: responseData, options: []) else {
                print("JSON results ERROR")
                completion(false, false)
                return
            }
            guard let resultsDict = results as? [String : Any] ?? nil else { return }
            print(results)
            guard let imagesArray = resultsDict["images"] as? [[String : Any]] ?? nil else {
                return
                
            }
            guard let facesArray = imagesArray[0]["faces"]  as? [Any] ?? nil else { return }
            //let facesArray = [0,2]
            if facesArray.count > 1  {
                completion(false, false)
            } else if resultsDict["Errors"] != nil
            {
                completion(false, true)
            }else {
                completion(true, false)
            }
        }
        dataTask.resume()
    }
    
    func enrollFace(player: Player, completion: @escaping (_ isEnrolled: Bool) -> ()) {
        guard let url = URL(string: "https://api.kairos.com/enroll") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("48f9a54e", forHTTPHeaderField: "app_id")
        request.addValue("f9da2200327fdab7f1848c77ced880df", forHTTPHeaderField: "app_key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let data = ["image" : player.photoURL, "subject_id" : "player", "gallery_name" : player.id]
        let jsonData = try? JSONSerialization.data(withJSONObject: data)
        request.httpBody = jsonData
        
        let dataTask = URLSession(configuration: URLSessionConfiguration.default).dataTask(with: request) { (data, urlResponse, error) in
            
            guard let responseData = data else {
                print(error as? String ?? "no error")
                completion(false)
                return
            }
            guard let results = try? JSONSerialization.jsonObject(with: responseData, options: []) else {
                print("JSON results ERROR")
                completion(false)
                return
            }
            guard let resultsDict = results as? [String : Any] ?? nil else { return }
            print(results)
            if resultsDict["Errors"] != nil {
                completion(false)
            } else {
                completion(true)
            }
        }
        dataTask.resume()
    }
    
    func compareFaces(target: Player, photoURL: String, completion: @escaping (_ isAMatch: Bool) -> ()) {
        guard let url = URL(string: "https://api.kairos.com/verify") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("48f9a54e", forHTTPHeaderField: "app_id")
        request.addValue("f9da2200327fdab7f1848c77ced880df", forHTTPHeaderField: "app_key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let data = ["image" : photoURL, "subject_id" : "player", "gallery_name" : target.id]
        let jsonData = try? JSONSerialization.data(withJSONObject: data)
        request.httpBody = jsonData
        
        let dataTask = URLSession(configuration: URLSessionConfiguration.default).dataTask(with: request) { (data, urlResponse, error) in
            
            guard let responseData = data else {
                print(error as? String ?? "no error")
                completion(false)
                return
            }
            guard let results = try? JSONSerialization.jsonObject(with: responseData, options: []) else {
                print("JSON results ERROR")
                completion(false)
                return
            }
            guard let resultsDict = results as? [String : [[String : Any]]] ?? nil else { return }
            print(results)
            if resultsDict["Errors"] != nil {
                completion(false)
            } else {
                let resultsArr = resultsDict["images"]
                let imageDict = resultsArr![0]["transaction"] as! [String:Any]
                if imageDict["confidence"] as! Double > 0.6 {
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
        dataTask.resume()
    }
    
}
