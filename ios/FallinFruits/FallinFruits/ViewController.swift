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
    var level = 5
    let gravity = UIGravityBehavior(items: [])
    let collision = UICollisionBehavior(items: [])
    var nbrOfFruits = 1
    var timer: Timer?
    var dragging = false
    var basket: UIView?
    var fruitsCaught = 0
    
    var score = 0
    var lives = 4
    var nbrMissed = 0
    @IBOutlet var scoreLabel: UILabel!
    @IBOutlet var lifeLabel: UILabel!
    @IBOutlet var missedLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collision.collisionDelegate = self
        
        animator = UIDynamicAnimator(referenceView: view)
        gravity.magnitude = 0.21
        animator!.addBehavior(gravity)
        
        UIGraphicsBeginImageContext(self.view.frame.size)
        UIImage(imageLiteralResourceName: "background").draw(in: self.view.bounds)
        let bg = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let image = bg else {
            return
        }
        
        addScore()
        removeLife()
        displayMissed()
        view.backgroundColor = UIColor(patternImage: image)
        timer = startLoop()
    
        makeBasket()
        
        collision.addBoundary(
            withIdentifier: "bottom" as NSCopying,
            for: UIBezierPath(rect: CGRect(
                // Somewhere around the middle of the basket
                x: 0, y: view.frame.maxY - 60, width: view.bounds.maxX, height: 1
            ))
        )
        
        animator!.addBehavior(collision)
    }
    
    func startLoop() -> Timer {
        let levelFactor = 0.04 * Double(level)
        self.gravity.magnitude = CGFloat(levelFactor)
        let fruit = makeFruit()
        fruits.append(fruit)
        // 4.0 for level 5, 0.24 for level 99
        let interval = -levelFactor + 4.2
        
        return Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { (timer) in
            self.nbrOfFruits += 1
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
    
    func makeBasket() {
        basket = UIView(frame: CGRect(x: 50, y: view.frame.maxY - 120, width: 64, height: 64))
        basket!.backgroundColor = UIColor(patternImage: UIImage(imageLiteralResourceName: "basket"))
        basket!.layer.zPosition = 2
        
        view.addSubview(basket!)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        let touch = event?.allTouches?.first
        let touchPoint = touch?.location(in: view)
        
        if let touchPoint = touchPoint,
           let isInBasket = basket?.frame.contains(touchPoint) {
            if isInBasket {
                dragging = true
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = event?.allTouches?.first
        let touchPoint = touch?.location(in: view)

        if dragging {
            if let x = touchPoint?.x,
                let y = basket?.center.y {
                basket?.center = CGPoint(x: x, y: y)
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        dragging = false
    }
    
    func changeLevel(to newLevel: Int) {
        fruitsCaught = 0
        // Level between 5 and 99
        level = min(max(5, newLevel), 99)
        
        print(level)
        
        timer?.invalidate()
        timer = startLoop()
    }
    
    func addScore(_ increment: Int = 0) {
        score += increment
        fruitsCaught += 1
        scoreLabel.text = "Score : \(score)"
        
        if fruitsCaught % level == 0 {
            changeLevel(to: level + 1)
        }
    }
    
    func displayMissed() {
        missedLabel.text = "Missed : \(nbrMissed)"
    }
    
    func addMissed() {
        nbrMissed += 1
        if nbrMissed % level == 0 {
            changeLevel(to: level - 1)
        }
        displayMissed()
    }
    
    private func isInBasket(_ fruit: UIView) -> Bool {
        guard let basket = basket else { return false }
        return fruit.center.x > basket.frame.minX &&
            fruit.center.x < basket.frame.maxX
    }
    
    func removeLife() {
        lives -= 1
        let t: String
        if lives > 1 {
            t = "Lives"
        } else {
            t = "Life"
        }
        lifeLabel.text = "\(t) : \(lives)"
    }
    
    func handleCollision(for fruitView: UIView, fruit: Fruit) {
        do {
            if isInBasket(fruitView) {
                let scoreIncrement = try fruit.type.getScore()
                addScore(scoreIncrement)
            } else {
                switch fruit.type {
                case .trap:
                    ()
                default:
                    addMissed()
                }
            }
        } catch _ {
            removeLife()
        }
    }
    
    func collisionBehavior(_ behavior: UICollisionBehavior, endedContactFor item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?) {
        if let itemView = item as? UIView {
            if let fruitId = itemView.accessibilityIdentifier,
               let fruit = (fruits.filter{ $0.id.uuidString == fruitId }).first {
                
                if let collisionIdentifier = identifier as? String,
                   collisionIdentifier == "bottom" {
                    
                    handleCollision(for: itemView, fruit: fruit)
                }
            }
            
            itemView.removeFromSuperview()
            collision.removeItem(item)
            gravity.removeItem(item)
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
