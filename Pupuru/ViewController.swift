//
//  ViewController.swift
//  Pupuru
//
//  Created by chelsea on 7/11/21.
//

import UIKit
import RealityKit
import Combine

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    var firstCard: Entity?
    var secondCard: Entity?
    var score = 0;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let anchor = AnchorEntity(plane: .horizontal, minimumBounds: [0.2, 0.2])
        arView.scene.addAnchor(anchor)
        
        var cards: [Entity] = []
        for _ in 1...16 {
            let box = MeshResource.generateBox(width: 0.04, height: 0.002, depth: 0.04)
            let material = SimpleMaterial.init(color: UIColor.red, isMetallic: false)
            let model = ModelEntity(mesh: box, materials: [material])
            
            model.generateCollisionShapes(recursive: true)
            
            cards.append(model)
        }
        
        for (index, card) in cards.enumerated() {
            let x = Float(index % 4)
            let z = Float(index / 4)
            
            card.position = [x * 0.1, 0, z * 0.1]
            card.name = "card_\(index)"
            anchor.addChild(card)
        }
        
        let boxSize: Float = 1.5
        let occlusionBoxMesh = MeshResource.generateBox(size: boxSize)
        let occlusionBox = ModelEntity(mesh: occlusionBoxMesh, materials: [OcclusionMaterial()])
        occlusionBox.position.y = -boxSize/2
        anchor.addChild(occlusionBox)
        
        let scales : [Float] = [
            0.0015,
            0.002,
            0.002,
            0.002,
            0.0005,
            0.008,
            0.0025,
            0.0005
        ]
        let centeredAnchorIndexes = [
            0,
            1,
            5,
            6
        ]
        let maoriWords = [
            "karaka",
            "pēre",
            "kaputī",
            "waka rererangi",
            "kitā",
            "uka",
            "hautai",
            "pouaka whakaata"
        ]
        var cancellable: AnyCancellable? = nil
        cancellable = ModelEntity.loadModelAsync(named: "01")
            .append(ModelEntity.loadModelAsync(named: "02"))
            .append(ModelEntity.loadModelAsync(named: "03"))
            .append(ModelEntity.loadModelAsync(named: "04"))
            .append(ModelEntity.loadModelAsync(named: "05"))
            .append(ModelEntity.loadModelAsync(named: "06"))
            .append(ModelEntity.loadModelAsync(named: "07"))
            .append(ModelEntity.loadModelAsync(named: "08"))
            .collect()
            .sink(receiveCompletion: { error in
                print("Error: \(error)")
                cancellable?.cancel()
            }, receiveValue: { entities in
                var objects: [ModelEntity] = []
                for (index, entity) in entities.enumerated() {
                    let centeredAnchor = centeredAnchorIndexes.contains(index)
                    let scale = scales[index]
                    entity.setScale([scale, scale, scale], relativeTo: anchor)
                    entity.generateCollisionShapes(recursive: true)
                    objects.append(entity);
                    entity.name = String(index)
                    
                    let wordMesh = MeshResource.generateText(maoriWords[index], extrusionDepth: 0.001, font: .systemFont(ofSize: 0.01))
                    let wordMaterial = SimpleMaterial.init(color: .black, isMetallic: false)
                    let wordEntity = ModelEntity(mesh: wordMesh, materials: [wordMaterial])
                    let min = wordMesh.bounds.min
                    let max = wordMesh.bounds.max
                    wordEntity.position = [-max.x/2, entity.position.y, entity.position.z]
                    wordEntity.name = String("word_\(index)")
                    
                    objects.append(wordEntity)
                    
                    if (centeredAnchor) {
                        let min = entity.model?.mesh.bounds.min
                        let max = entity.model?.mesh.bounds.max
                        entity.position = [entity.position.x, max!.y * scale + 0.002, entity.position.z]
                    }
                }
                
                objects.shuffle()
                
                for (index, object) in objects.enumerated() {
                    cards[index].addChild(object)
                    cards[index].transform.rotation = simd_quatf(angle: .pi, axis: [1, 0, 0])
                }
                
                cancellable?.cancel()
            })
    }
    
    
    @IBAction func onTap(_ sender: UITapGestureRecognizer) {
        if firstCard != nil && secondCard != nil {
            let firstCardIndex = getCardIndex(card: firstCard!.children[0])
            let secondCardIndex = getCardIndex(card: secondCard!.children[0])
            if (firstCardIndex == secondCardIndex) {
                // Matching cards, can remove these and increase score
                score += 1
                firstCard?.removeFromParent()
                secondCard?.removeFromParent()
            } else {
                flipCardDown(card: firstCard!)
                flipCardDown(card: secondCard!)
            }
            
            firstCard = nil
            secondCard = nil
        } else {
            let tapLocation = sender.location(in: arView)
            if let card = arView.entity(at: tapLocation) {
                if (card.name.starts(with: "card_")) {
                    if (firstCard == nil) {
                        firstCard = card
                        flipCardUp(card: card)
                    } else if (firstCard?.name != card.name) {
                        secondCard = card
                        flipCardUp(card: card)
                    }
                }
            }
        }
    }
    
    func getCardIndex(card: Entity) -> String {
        return card.name.replacingOccurrences(of: "word_", with: "")
    }
    
    func flipCardUp(card: Entity) {
        var flipDownTransform = card.transform;
        flipDownTransform.rotation = simd_quatf(angle: 0, axis: [1, 0, 0])
        card.move(to: flipDownTransform, relativeTo: card.parent, duration: 0.25, timingFunction: .easeInOut)
    }
    
    func flipCardDown(card: Entity) {
        var flipUpTransform = card.transform;
        flipUpTransform.rotation = simd_quatf(angle: .pi, axis: [1, 0, 0])
        card.move(to: flipUpTransform, relativeTo: card.parent, duration: 0.25, timingFunction: .easeInOut)
    }
}
