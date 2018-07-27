//
//  ViewController.swift
//  JustInAR
//
//  Created by Justin Zhang on 2018/7/15.
//  Copyright © 2018年 JustinZhang. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var diceArray = [SCNNode]()
    
    var planeArray = [SCNNode]()
    
    var anchorArray = [ARAnchor]()
    
    var planeNodesCounts = 0
    
    var isPlaneSelected = false
    
    var gridWidth : Float = 0.0
    
    var gridHeight : Float = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        
        // Set the view's delegate
        sceneView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        if ARWorldTrackingConfiguration.isSupported {
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = .horizontal
            print("Session is supported = \(ARWorldTrackingConfiguration.isSupported)")
            
            // Run the view's session
            sceneView.session.run(configuration)
        }
        
        else {
            print("Session is not supported! You are fucking poor guy... You cannot afford an IPhone within A9 chip")
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let touch = touches.first {
            let touchLocation = touch.location(in: sceneView)
            
            let results = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
            
            if let hitResult = results.first {
                
                let touchedPosX = hitResult.localTransform.columns.3.x
                
                let touchedPosY = hitResult.localTransform.columns.3.z
                
                print("touched the plane")
                
                if (0 < touchedPosX && touchedPosX < gridWidth) || (0 < touchedPosY && touchedPosY < gridHeight) {
                    print("You touched in grid!")
                    // Create a new scene
                    
                    addDice(atLocation: hitResult)
                    
                } else {
                    print("Out of the world!")
                }
                
            } else {
                print("touched somewhere else")
            }
        }
    }

    // MARK: - Roll Again methods
    
    @IBAction func RollAgain(_ sender: UIBarButtonItem) {
        rollAllDice()
    }
    
    //MARK: - Reset methods
    
    @IBAction func ReseButtonPressed(_ sender: UIBarButtonItem) {
        resetApp()
    }
    
    func resetApp() {
        
        isPlaneSelected = false
        planeNodesCounts = 0
        
        if !anchorArray.isEmpty
        {
            for index in 0...anchorArray.count - 1
            {
                sceneView.node(for: anchorArray[index])?.removeFromParentNode()
            }
            
            anchorArray.removeAll()
        }
        
        
        
        if !diceArray.isEmpty {
            for dice in diceArray {
                dice.removeFromParentNode()
            }
            
            anchorArray.removeAll()
        }
//
        if !planeArray.isEmpty {
            for plane in planeArray {
                plane.removeFromParentNode()
            }

            planeArray.removeAll()
        }
        
    }
    
    //MARK: - Dice Rendering Methods
    
    func addDice(atLocation location: ARHitTestResult) {
        let dicescene = SCNScene(named: "art.scnassets/diceCollada.scn")!
        if let diceNode = dicescene.rootNode.childNode(withName: "Dice", recursively: true) {
            
            //to make the dice be located above the plane
            let diceRadius = diceNode.boundingSphere.radius
            
            diceNode.position = SCNVector3(
                x: location.worldTransform.columns.3.x,
                y: location.worldTransform.columns.3.y + diceRadius,
                z: location.worldTransform.columns.3.z)
            
            // add diceNode to the diceArray
            diceArray.append(diceNode)
            
            // Set the scene to the view
            sceneView.scene.rootNode.addChildNode(diceNode)
            sceneView.autoenablesDefaultLighting = true
            
        }
    }
  
    func roll(dice : SCNNode) {
        // let dice randomly rotation
        
        let randomX = Float(arc4random_uniform(4) + 1) * (Float.pi / 2)
        let randomZ = Float(arc4random_uniform(4) + 1) * (Float.pi / 2)
        
        dice.runAction(SCNAction.rotateBy(
            x: CGFloat(randomX * 5),
            y: 0,
            z: CGFloat(randomZ * 5),
            duration: 2))
    }
    
    func rollAllDice() {
        if !diceArray.isEmpty {
            for dice in diceArray {
                roll(dice: dice)
            }
        }
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        rollAllDice()
    }
    
 
    // MARK: - ARSCNViewDelegateMethods
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard let planeAnchor = anchor as? ARPlaneAnchor  else { return }
        
        
        if !planeArray.isEmpty {
            
            for plane in planeArray {
                plane.removeFromParentNode()
            }
        }
        
        gridWidth = abs(planeAnchor.extent.x)
        gridHeight = abs(planeAnchor.extent.z)
        
        let planeNode = CreatPlane(with: planeAnchor)
        
        node.addChildNode(planeNode)
        planeArray.append(node)
        
        
    }
    
    //MARK: - Plane Rendering Methods
    
    func CreatePlaneNode(withPlaneAnchor planeAnchor: ARPlaneAnchor, withPlane plane: SCNPlane) -> SCNNode {
        
        let planeNode = SCNNode()
        
        planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
        
        let gridMaterial = SCNMaterial()
        
        gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png")
        
        plane.materials = [gridMaterial]
        
        planeNode.geometry = plane
        
        return planeNode
    }
    
    
    func CreatPlane(with planeAnchor:  ARPlaneAnchor) -> SCNNode {
        
        
        
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
    
        return CreatePlaneNode(withPlaneAnchor: planeAnchor, withPlane: plane)
    }
}

