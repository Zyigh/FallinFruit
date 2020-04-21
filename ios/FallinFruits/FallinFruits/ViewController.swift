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
    var timer: Timer!
    
    var score = 0
    var lives = 3
    var nbrMissed = 0
    @IBOutlet var scoreLabel: UILabel!
    @IBOutlet var lifeLabel: UILabel!
    @IBOutlet var missedLabel: UILabel!
    
    enum CollisionType: String {
        case bottom, wicker
    }
    
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
            withIdentifier: CollisionType.bottom.rawValue as NSCopying,
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
    
    func addMissed() {
        nbrMissed += 1
        missedLabel.text = "Missed : \(nbrMissed)"
    }
    
    func handleCollision(collisionType: CollisionType, fruit: Fruit) {
        switch collisionType {
        case .bottom:
            switch fruit.type {
            case .trap:
                ()
            default:
                addMissed()
            }
        case .wicker:
            ()
        }
    }
    
    func collisionBehavior(_ behavior: UICollisionBehavior, endedContactFor item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?) {
        if let it = item as? UIView {
            if let fruitId = it.accessibilityIdentifier,
               let fruit = (fruits.filter{ $0.id.uuidString == fruitId }).first {
                
                it.removeFromSuperview()
                collision.removeItem(item)
                gravity.removeItem(item)
                
                if let collisionId = identifier as? String,
                    let id = CollisionType(rawValue: collisionId) {
                    handleCollision(collisionType: id, fruit: fruit)
                }
            }
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
