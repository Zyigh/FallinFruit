//
//  ViewController.swift
//  FallinFruits
//
//  Created by Hugo Medina on 17/04/2020.
//  Copyright © 2020 Razeware. All rights reserved.
//

import UIKit

struct EndGameError: Error {}

class ViewController: UIViewController, UICollisionBehaviorDelegate {
    var animator: UIDynamicAnimator? = nil
    var fruits = [Fruit]()
    let fruitsPerLevel = 15
    let level = 5
    let gravity = UIGravityBehavior(items: [])
    let collision = UICollisionBehavior(items: [])
    var nbrOfFruits = 1
    var nbrMissed = 0
    var timer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collision.collisionDelegate = self
        
        animator = UIDynamicAnimator(referenceView: view)
        gravity.magnitude = 0.21
        animator!.addBehavior(gravity)
        // Do any additional setup after loading the view.
        UIGraphicsBeginImageContext(self.view.frame.size)
        UIImage(imageLiteralResourceName: "background").draw(in: self.view.bounds)
        let bg = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let image = bg else {
            return
        }
        
        view.backgroundColor = UIColor(patternImage: image)
        
        let fruit = makeFruit()
        fruits.append(fruit)
        startLoop()
    
        collision.addBoundary(
            withIdentifier: "bottom" as NSCopying,
            for: UIBezierPath(rect: CGRect(
                x: 0, y: view.bounds.maxY, width: view.bounds.maxX, height: 1
            ))
        )
        
        animator!.addBehavior(collision)
    }
    
    func startLoop(interval: Double = 3.0, gravity: CGFloat = 0.21) {
        timer =  Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { (timer) in
            self.nbrOfFruits += 1
            self.gravity.magnitude = gravity
            let fruit = self.makeFruit()
            self.fruits.append(fruit)
        }
    }
    
    func makeFruit() -> Fruit {
        let fruit = Fruit(id: UUID(), type: FruitType.pickRandom(chanceOfTrap: level))
        
        let dims = 32.0
    
        let maxX = Double(view.bounds.maxX)
        let x = Double.random(in: 32...(maxX - 32))
        
        let fruitImage = UIView(frame: CGRect(x: x, y: -42, width: dims, height: dims))
        fruitImage.accessibilityIdentifier = fruit.id.uuidString
        fruitImage.backgroundColor = UIColor(patternImage: fruit.type.getDisplay())
        fruitImage.layer.cornerRadius = CGFloat(dims / 2)

        view.addSubview(fruitImage)
        
        collision.addItem(fruitImage)
        gravity.addItem(fruitImage)
    
        return fruit
    }
    
    func collisionBehavior(_ behavior: UICollisionBehavior, endedContactFor item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?) {
        if let id = identifier as? String, id == "bottom" {
            nbrMissed += 1
            
        }
    }
}

enum FruitType: Int {
    case trap, orange, cherry, apple, strawberry, raspberry
    
    static func pickRandom(chanceOfTrap: Int = 1) -> FruitType {
        if Int.random(in: 0...100) <= chanceOfTrap {
            return .trap
        }
        
        return FruitType(rawValue: Int.random(in: 1...5))!
    }
    
    func getDisplay() -> UIImage {
        switch self {
        case .trap:
            return UIImage(imageLiteralResourceName: "donut")
        case .orange:
            return UIImage(imageLiteralResourceName: "orange")
        case .cherry:
            return UIImage(imageLiteralResourceName: "cherry")
        case .apple:
            return UIImage(imageLiteralResourceName: "apple")
        case .strawberry:
            return UIImage(imageLiteralResourceName: "strawberry")
        case .raspberry:
            return UIImage(imageLiteralResourceName: "raspberry")
        }
    }
    
    func getScore() throws -> Int  {
        switch self {
        case .trap:
            throw EndGameError()
        default:
            return self.rawValue
        }
    }
}

struct Fruit {
    let id: UUID
    let type: FruitType
}
