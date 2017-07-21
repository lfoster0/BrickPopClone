//
//  ViewController.swift
//  BrickPop
//
//  Created by Lee Foster on 2017-06-17.
//  Copyright © 2017 Lee Foster. All rights reserved.
//

import UIKit

class ViewController: UIViewController, BrickViewTappedDelegate {
    let numCols = 10.0
    let numRows = 10.0
    let marginSize = 5.0
    var brickSize = 200.0
    var currentLevel = 1
    var totalScore = 0
    
    var bricks = [[BrickView]]()
    
    @IBOutlet weak var brickAreaView: UIView!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var playAgainButton: UIButton!
    @IBOutlet weak var thatWasCloseLabel: UILabel!
    
    // MARK: Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.backgroundColor = UIColor.backGroundColor()
        self.loadBlocks(forLevel: 1)
    }
    
    func loadBlocks(forLevel: Int) {
        self.brickAreaView.subviews.forEach { (view) in
            view.removeFromSuperview()
        }
        
        var totalSizeNeeded = (brickSize * numCols) + (marginSize * numCols) + marginSize
        while (totalSizeNeeded > Double(self.view.frame.size.width)) {
            brickSize = brickSize - 1.0
            totalSizeNeeded = (brickSize * numCols) + (marginSize * numCols) + marginSize
        }
        
        var xPos = marginSize
        var yPos = marginSize
        bricks = [[BrickView]]()
        for _ in 0..<Int(numCols) {
            var col = [BrickView]()
            for _ in 0..<Int(numRows) {
                let brickFrame = CGRect(x: xPos, y: yPos, width: brickSize, height: brickSize)
                yPos += brickSize + marginSize
                let brickType = { () -> BrickType in 
                    switch forLevel {
                    case 1: return BrickType.randomLevel1()
                    case 2: return BrickType.randomLevel2()
                    case 3: return BrickType.randomLevel3()
                    default: return BrickType.randomLevel4()
                    }
                }()
                let brickView = BrickView(frame: brickFrame, brickType:brickType)
                brickView.tappedDelegate = self
                col.append(brickView)
                self.brickAreaView.addSubview(brickView)
            }
            bricks.append(col)
            xPos += marginSize + brickSize
            yPos = marginSize
        }
    }
    
    // MARK: IBOutlets
    @IBAction func playAgainButtonTapped(_ sender: Any) {
        currentLevel = 1;
        UIView.animate(withDuration: 0.5, animations: {
            self.thatWasCloseLabel.alpha = 0.0
            self.playAgainButton.alpha = 0.0
        }) { (completion) in
            self.thatWasCloseLabel.isHidden = true
            self.playAgainButton.isHidden = true
            self.thatWasCloseLabel.alpha = 1.0
            self.playAgainButton.alpha = 1.0
        }
        self.loadBlocks(forLevel: currentLevel)
    }
    
    // MARK: BrickViewTappedDelegate
    func tappedBrickView(tappedView: BrickView) {
        let brickView = getBrickViewAtPoint(point: tappedView.center)
        let touchingBricks = getBricksTouchingThisOne(brickView: brickView!)
        if touchingBricks.count == 1 {
            AudioManager.sharedInstance.playBadTapSound()
            return
        }

        AudioManager.sharedInstance.playBrickTappedSound()
        
        self.totalScore += Int(pow(Double(touchingBricks.count), 2.0))
        self.scoreLabel.text = String(self.totalScore)
        self.brickAreaView.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.3, animations: {
            for brickView in touchingBricks {
                brickView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            }
        }) { (completed) in
            for brickView in touchingBricks {
               brickView.isHidden = true
            }
            self.moveBricksDown(completion: {
                self.moveBricksLeft(completion: {
                    if self.bricks.count == 0 {
                        self.goToNextLevel()
                    } else if !self.checkIfAnyMovesLeft() {
                        self.showGameOver()
                    }
                    self.brickAreaView.isUserInteractionEnabled = true
                })
            })
        }
    }
    
    // MARK: Helpers
    func getBrickViewAtPoint(point: CGPoint) -> BrickView? {
        for view in self.brickAreaView.subviews {
            if view.frame.contains(point) && view is BrickView {
                return view as! BrickView
            }
        }
        return nil
    }
    
    func getBricksTouchingThisOne(brickView: BrickView) -> [BrickView] {
        var touching = [BrickView]()
        var toCheck: Set = [brickView]
        let goal = brickView.brickType
        
        while toCheck.count > 0 {
            let viewToCheck = toCheck.removeFirst()
            let center = viewToCheck.center
            let brickSize = CGFloat(self.brickSize)
            
            let directions = [
                CGPoint(x: center.x, y: center.y-brickSize), // TOP
                CGPoint(x: center.x-brickSize, y: center.y), // LEFT
                CGPoint(x: center.x+brickSize, y: center.y), // RIGHT
                CGPoint(x: center.x, y: center.y+brickSize)  // DOWN
            ]
            
            for point in directions {
                guard let brick = getBrickViewAtPoint(point: point),
                    brick.brickType == goal,
                    !touching.contains(brick) else {
                        continue
                }
                
                toCheck.insert(brick)
            }
            touching.append(viewToCheck)
        }
        
        return touching
    }
    
    func moveBricksDown(completion: @escaping (Void) -> Void) {
        var bricksToNewFrames = [(brickView:BrickView, newFrame:CGRect)]()
        
        for i in 0..<self.bricks.count {
            // sort each col so hidden ones are on top while keeping y order
            let sortedCol = self.bricks[i].sorted(by: { (a, b) -> Bool in
                if a.isHidden {
                    return true
                }
                
                if b.isHidden {
                    return false
                }
                return a.frame.origin.y < b.frame.origin.y
            })
            self.bricks[i] = sortedCol
            
            // go through each brick in the col and find the new frame for it
            for j in 0..<self.bricks[i].count {
                let adjustedOrigin = self.getScreenPositionFor(col: i, row: j)
                if !adjustedOrigin.equalTo(self.bricks[i][j].frame.origin) {
                    var newFrame = self.bricks[i][j].frame
                    newFrame.origin = adjustedOrigin
                    bricksToNewFrames.append((brickView: self.bricks[i][j], newFrame:newFrame))
                }
            }
        }
        
        var dictXToY: [CGFloat:CGFloat] = [:]
        // get the lowest brickviews in each col
        for tuple in bricksToNewFrames where !tuple.brickView.isHidden {
            let oldY = dictXToY.updateValue(tuple.newFrame.origin.y, forKey: tuple.newFrame.origin.x)
            if oldY != nil && oldY! > tuple.newFrame.origin.y {
                dictXToY.updateValue(oldY!, forKey: tuple.newFrame.origin.x)
            }
        }
        
        // animate the bricks to their new frame and play relevant sound
        for tuple in bricksToNewFrames {
            let brickViewToMove = tuple.brickView
            let newFrame = tuple.newFrame
            let diffY = newFrame.origin.y - brickViewToMove.frame.origin.y
            let numBlocksToMove = Double(diffY / CGFloat(brickSize+marginSize))
            let animScaleFactor = numBlocksToMove * 0.075
            let baseAnimationSpeed = 0.1
            UIView.animate(withDuration: baseAnimationSpeed + animScaleFactor, delay: 0.2, options: .curveEaseIn, animations: {
                brickViewToMove.frame = newFrame
                if let yPos = dictXToY[newFrame.origin.x], yPos == newFrame.origin.y {
                    AudioManager.sharedInstance.playBrickFallSound()
                }
            }, completion: { (completed) in
                if tuple.brickView == bricksToNewFrames.last!.brickView {
                    completion()
                }
            })
        }
    }
    
    func getScreenPositionFor(col:Int, row:Int) -> CGPoint {
        let xPos = marginSize + (brickSize + marginSize) * Double(col)
        let yPos = marginSize + (brickSize + marginSize) * Double(row)
        
        return CGPoint(x: xPos, y: yPos)
    }
    
    func moveBricksLeft(completion: @escaping (Void)->Void) {
        for i in (0..<self.bricks.count).reversed() {
            var allHidden = true
            for brickView in self.bricks[i] {
                if !brickView.isHidden {
                    allHidden = false
                    break
                }
            }
            if allHidden {
                self.bricks.remove(at: i)
            }
        }
        
        var bricksAndNewFrames = [(brickView:BrickView, newFrame:CGRect)]()
        for i in 0..<self.bricks.count {
            for j in 0..<self.bricks[i].count {
                let adjustedOrigin = self.getScreenPositionFor(col: i, row: j)
                if !adjustedOrigin.equalTo(self.bricks[i][j].frame.origin) {
                    var newFrame = self.bricks[i][j].frame
                    newFrame.origin = adjustedOrigin
                    bricksAndNewFrames.append((brickView: self.bricks[i][j], newFrame: newFrame))
                }
            }
        }
        
        if bricksAndNewFrames.count > 0 {
            AudioManager.sharedInstance.playBrickFallSound()
        }
        for tuple in bricksAndNewFrames {
            let brickViewToAnimate = tuple.brickView
            let newFrame = tuple.newFrame
            UIView.animate(withDuration: 0.2, delay: 0.3, options: .curveEaseOut, animations: {
                brickViewToAnimate.frame = newFrame
            }, completion: { (completed) in
                if tuple == bricksAndNewFrames.last! {
                    completion()
                }
            })
        }
        
        if bricksAndNewFrames.count == 0 {
            completion()
        }
    }
    
    func goToNextLevel() {
        currentLevel += 1
        self.loadBlocks(forLevel: currentLevel)
    }
    
    func checkIfAnyMovesLeft() -> Bool {
        for col in self.bricks {
            for brickView in col where !brickView.isHidden {
                let center = brickView.center
                let brickSize = CGFloat(self.brickSize)
                let directions = [
                    CGPoint(x: center.x, y: center.y-brickSize), // TOP
                    CGPoint(x: center.x-brickSize, y: center.y), // LEFT
                    CGPoint(x: center.x+brickSize, y: center.y), // RIGHT
                    CGPoint(x: center.x, y: center.y+brickSize)  // DOWN
                ]
                
                for point in directions {
                    if let brick = getBrickViewAtPoint(point: point) {
                        if brick.brickType == brickView.brickType &&
                            !brick.isHidden {
                            return true
                        }
                    }
                }
            }
        }
        return false
    }
    
    func showGameOver() {
        self.totalScore = 0
        self.thatWasCloseLabel.center = CGPoint(x: self.view.frame.width, y: self.thatWasCloseLabel.center.y)
        self.thatWasCloseLabel.isHidden = false
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.1, initialSpringVelocity: 5.0, options: .curveLinear, animations: {
            self.thatWasCloseLabel.center = self.view.center
        }, completion: { (completed) in
            self.playAgainButton.alpha = 0.0
            UIView.animate(withDuration: 0.5, animations: {
                self.playAgainButton.alpha = 1.0
                self.playAgainButton.isHidden = false
            })
        })
    }
    
}

