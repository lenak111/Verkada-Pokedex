//
//  ViewController.swift
//  Verkada Pokedex Project
//
//  Created by Lena  K on 8/28/22.
//

// response object from initial API call
struct Response: Decodable {
    let count: Int
    let next: String
    let results: [PokemonObj]
}

// Pokemon objects in response
struct PokemonObj: Hashable, Codable {
    let name: String
    let url: String
}

// contains info on Pokemon's sprites
struct PokemonInfo: Hashable, Codable {
    let sprites: Sprite
}

// contains url for Pokemon's "front_default" sprite
struct Sprite: Hashable, Codable {
    let front_default: String
}

// Pokemon object model
struct Pokemon: Hashable, Codable {
    let name: String
    let url: String // Pokemon Info URL
    let imgData: Data?
}

import UIKit
class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var offset: Int = 0 // offset increases as more Pokemon are retrieved
    let limit: Int = 20 // number of Pokemon retrieved always 20

    @IBOutlet weak var myCollectionView: UICollectionView!
    @IBOutlet weak var selectedPokemonLabel: UILabel!
    @IBOutlet weak var selectedPokemonImage: UIImageView!
    
    
    let reuseIdentifier = "cell"
    var pokemons = [Pokemon]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        selectedPokemonImage.layer.cornerRadius = 8.0
        selectedPokemonImage.clipsToBounds = true
        
        // fetch initial Pokemon on load
        fetch()
    }
    
    func fetch() {
        guard let url = URL(string: "https://pokeapi.co/api/v2/pokemon?limit=" + String(limit) + "&offset=" + String(offset)) else {
            return
        }
        
        // update offset to get the next 20 Pokemon
        offset += limit
        
        // Perform API call
        // Get JSON data from URL for Response
        let task = URLSession.shared.dataTask(with: url) { [weak
            self] data, _, error in
            // guard executes statement if false
            guard let data = data, error == nil else {
                return
            }
        
            // Convert JSON to Response
            do {
                let response = try JSONDecoder().decode(Response.self,
                    from: data)
                // loop through each Pokemon object, retrieve imgData
                response.results.forEach { pokemonObj in
                    guard let pokemonInfoUrl = URL(string: pokemonObj.url) else {
                        return
                    }
                    
                    // Get JSON data from URL for PokemonInfo
                    let imgRequest = URLSession.shared.dataTask(with: pokemonInfoUrl) { [weak
                        self] data, _, error in
                        guard let data = data, error == nil else {
                            return
                        }
                        
                        var imgUrl: String = ""
                        // Convert JSON to PokemonInfo
                        do {
                            let imgResponse = try JSONDecoder().decode(PokemonInfo.self,
                                from: data)
                            imgUrl = imgResponse.sprites.front_default
                        } catch {
                            print(error)
                        }
                        
                        guard let pokemonImageDataUrl = URL(string: imgUrl) else {
                            return
                        }
                        let imgDataRequest = URLSession.shared.dataTask(with: pokemonImageDataUrl) { [weak
                            self] data, _, error in
                            guard let data = data, error == nil else {
                                return
                            }
                            // want UI to be updated, so run on main thread
                            DispatchQueue.main.async {
                                self?.pokemons.append(Pokemon(name: pokemonObj.name.capitalized, url: pokemonObj.url, imgData: data))
                                self?.myCollectionView.reloadData()
                            }
                        }
                        // start the task
                        imgDataRequest.resume()
                    }
                    // start the task
                    imgRequest.resume()
                }
            } catch {
                print(error)
            }
        }
        // start the task
        task.resume()
    }
        
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.pokemons.count
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! MyCollectionViewCell
        
        // Use the outlet in our custom class to get a reference to the UILabel in the cell
        cell.pokemonNameLabel.text = self.pokemons[indexPath.row].name // The row value is the same as the index of the desired text within the array.
        
        if self.pokemons[indexPath.row].imgData != nil {
            cell.pokemonUIImageView.image = UIImage(data: self.pokemons[indexPath.row].imgData!)
            cell.selectedBackgroundView = UIImageView(image: UIImage(named: "pokemon_bg_selected.jpeg"))
            cell.backgroundView = UIImageView(image: UIImage(named: "pokemon_bg.jpeg"))

            // drop shadow
            cell.layer.shadowColor = UIColor.gray.cgColor
            cell.layer.shadowOffset = CGSize(width: 0, height: 3.0)
            cell.layer.shadowRadius = 7.0
            cell.layer.shadowOpacity = 1.0
            cell.layer.masksToBounds = false
            cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: 20).cgPath
        }
        
        // if we scroll all the way down, fetch more Pokemon
        if indexPath.row == pokemons.count - 1 {
            fetch()
        }
        
        return cell
    }
        
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // handle tap events
        selectedPokemonImage.image = UIImage(data: self.pokemons[indexPath.row].imgData!)
        selectedPokemonLabel.text = self.pokemons[indexPath.row].name
    }
}
