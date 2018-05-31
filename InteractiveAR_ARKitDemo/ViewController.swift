//
//  ViewController.swift
//  InteractiveAR_ARKitDemo
//
//  Created by Hem Sharma on 29/05/18.
//  Copyright © 2018 Hem Sharma. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController
{
    @IBOutlet var sceneView: ARSCNView!
    var planeAnchor : ARPlaneAnchor? = nil
    var animations = [String: CAAnimation]()
    var idle:Bool = true
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        //self.createArissaIdle(at: SCNVector3(0, -4, -2))
    }
    
    func setupScene()
    {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        sceneView.session.run(configuration)
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        self.setupScene()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    func loadArissaAnimation(withKey: String, sceneName:String, animationIdentifier:String)
    {
        let sceneURL = Bundle.main.url(forResource: sceneName, withExtension: "dae")
        let sceneSource = SCNSceneSource(url: sceneURL!, options: nil)
        
        if let animationObject = sceneSource?.entryWithIdentifier(animationIdentifier, withClass: CAAnimation.self)
        {
            // The animation will only play once
            animationObject.repeatCount = 1
            // To create smooth transitions between animations
            animationObject.fadeInDuration = CGFloat(1)
            animationObject.fadeOutDuration = CGFloat(0.5)
            
            // Store the animation for later use
            animations[withKey] = animationObject
        }
    }
    
    func createArissaIdle(at position : SCNVector3)
    {
        // Create a new scene with idle/first animation
        let scene = SCNScene(named: "art.scnassets/arissa.dae")!
        let node = SCNNode()
        
        // Add all the child nodes to the parent node
        for child in scene.rootNode.childNodes
        {
            node.addChildNode(child)
        }
        
        // Set up some properties
        node.position = position
        node.scale = SCNVector3(0.002, 0.002, 0.002)
        
        // Add the node to the scene
        sceneView.scene.rootNode.addChildNode(node)
        self.loadArissaAnimation(withKey: "arissaDance", sceneName: "art.scnassets/arissaDance", animationIdentifier: "unnamed_animation__0")
    }
    
    func playAnimation(key: String)
    {
        // Add the animation to start playing it right away
        sceneView.scene.rootNode.addAnimation(animations[key]!, forKey: key)
    }
    
    func stopAnimation(key: String)
    {
        // Stop the animation with a smooth transition
        sceneView.scene.rootNode.removeAnimation(forKey: key, blendOutDuration: CGFloat(0.5))
    }
    
    func touchOn3DModel(location : CGPoint)
    {
        // Let's test if a 3D Object was touch
        if self.animations.isEmpty == true
        {
            return
        }
        
        var hitTestOptions = [SCNHitTestOption: Any]()
        hitTestOptions[SCNHitTestOption.boundingBoxOnly] = true
        
        let hitResults: [SCNHitTestResult]  = sceneView.hitTest(location, options: hitTestOptions)
        
        if hitResults.first != nil
        {
            if(idle)
            {
                playAnimation(key: "arissaDance")
            }
            else
            {
                stopAnimation(key: "arissaDance")
            }
            idle = !idle
            return
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        let location = touches.first!.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
        guard let hitTestResult = hitTestResults.first else
        {
            self.touchOn3DModel(location: location)
            return
        }
        if animations.isEmpty == true
        {
            let translation = hitTestResult.worldTransform.translation
            let x = translation.x
            let y = translation.y
            let z = translation.z
            self.createArissaIdle(at: SCNVector3(x,y,z))
        }
        else
        {
            self.touchOn3DModel(location: location)
        }
    }
}

extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

extension ViewController : ARSCNViewDelegate
{
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode?
    {
        if self.planeAnchor == nil
        {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return nil}
            self.planeAnchor = planeAnchor
            sceneView.debugOptions = []
            return SCNNode()
        }
        else
        {
            return nil
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor)
    {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)/2
        let plane = SCNPlane(width: width, height: height)
    
        plane.materials.first?.diffuse.contents = UIColor(red: 90/255, green: 200/255, blue: 250/255, alpha: 0.2)
        let planeNode = SCNNode(geometry: plane)
        
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
                
        node.addChildNode(planeNode)
    }
}
