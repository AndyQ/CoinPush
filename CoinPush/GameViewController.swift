//
//  GameViewController.swift
//  CoinPush
//
//  Created by Andy Qua on 03/07/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit


func join(s1: String, s2: String, joiner: String) -> String
{
    return s1 + joiner + s2
}

func degToRad( deg : Float ) -> Float
{
    return ((deg) / 180.0 * Float.pi)
}


class GameViewController: UIViewController, SCNSceneRendererDelegate, SCNPhysicsContactDelegate
{
    let cameraNode = SCNNode()
    var lastX : Float = 0
    var lastY : Float = 0
    var angle : Float = 0

    var pusher1 : SCNNode!
    var pusher2 : SCNNode!
    var coinGuard1 : SCNNode!
    var coinGuard2 : SCNNode!
    var coinRestrict : SCNNode!
    var sideWall1 : SCNNode!
    var sideWall2 : SCNNode!

    var lookAt : SCNNode!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        let scene = SCNScene()
        
        setupEnvironment( scene: scene )
        
        setupScene( scene: scene )
        
        
        // Make the camera look at the scene
        lookAt = SCNNode()
        lookAt.position = SCNVector3( x: 0, y: 0, z: 0 )
        let lookAtConstraint = SCNLookAtConstraint(target: lookAt)
        lookAtConstraint.isGimbalLockEnabled = true
        cameraNode.constraints = [lookAtConstraint]
    
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
        scene.physicsWorld.speed = 4
        scene.physicsWorld.contactDelegate = self
        scnView.isJitteringEnabled = true
        
        // show statistics such as fps and timing information
//        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.black
        scnView.delegate = self
        scnView.play(nil)
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(GameViewController.handleTap(_:)))
        let dragGesture = UIPanGestureRecognizer(target: self, action: #selector(GameViewController.handlePan(_:)))
        scnView.addGestureRecognizer(tapGesture)
        scnView.addGestureRecognizer(dragGesture)
        
        // Start the pushers
        animatePusher( pusher: pusher1, minX : -0.5, maxX : 0.5 )
        animatePusher( pusher: pusher2, minX : 1.5, maxX : 2.5 )
        
        angle = 90;
    }
    
    
    func setupEnvironment( scene: SCNScene )
    {
        // create and add a camera to the scene
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x:8, y: 6, z:-0 )
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        let light = SCNLight()
        light.type = SCNLight.LightType.omni  // SCNLightTypeSpot
        light.color = UIColor( white:1, alpha:1.0)
        light.castsShadow = true
        light.shadowColor = UIColor.black
        light.shadowRadius = 10.0
//        lightNode.transform = SCNMatrix4MakeRotation( degToRad(180), 0, 0, 1)
        lightNode.light = light
        lightNode.position = SCNVector3(x: 1, y: 10, z: 0)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        let amblight = SCNLight()
        amblight.type = SCNLight.LightType.ambient
        amblight.color = UIColor.darkGray
        ambientLightNode.light = amblight
        scene.rootNode.addChildNode(ambientLightNode)
    }
    
    
    func setupScene( scene: SCNScene )
    {
        // Create a plane
        createFloor( scene: scene )
        createCoinFloor( scene: scene, x:0, y: 0.1, z:-2.5, width : 2, height: 2.9, length : 5 )
        createCoinFloor( scene: scene, x:2, y: 0.1, z:-2.5, width : 2, height: 1.9, length : 5 )
        createCoinFloor( scene: scene, x:-1.9, y: 3.5, z:-2.5, width : 2, height:2, length : 5 )
        createCoinFloor( scene: scene, x:-1.9, y: 0.1, z:-2.5, width : 1.9, height:3.5, length : 5 )

        pusher1 = createPusher( scene: scene, x: -0.5, y: 3, z:-2.5, length:5 )
        pusher2 = createPusher( scene: scene, x:  1.5, y: 2, z:-2.5, length:5 )
//        coinGuard1 = createCoinGuard( scene, x: 0, y: 3.5, z: -2.5, height: 1, color: UIColor.whiteColor() )
//        coinGuard2 = createCoinGuard( scene, x: 2, y: 2.5, z: -2.5, height: 0.5, color: UIColor.whiteColor() )
        coinRestrict = createCoinGuard( scene: scene, x: 0.3, y: 3.9, z: -2.5, height:4, color: UIColor( red: 1, green: 0, blue: 0, alpha: 0.3 ) )
        sideWall1 = createSideWall( scene: scene, x: 0, y: 0, z: -2.6, width:5, height:4.5 )
        sideWall2 = createSideWall( scene: scene, x: 0, y: 0, z: 2.52, width:5, height:4.5 )
        
        createPins( scene: scene )
    }
    
    
    func createFloor( scene: SCNScene )
    {
        let geom = SCNFloor()
        geom.reflectivity = 0
        
        let body = SCNPhysicsBody.static()
        body.friction = 4
        
        // create and configure a material
        let material = SCNMaterial()
        material.diffuse.contents = "wood2.png"
        material.diffuse.contentsTransform = SCNMatrix4Rotate(SCNMatrix4MakeScale(20, 20, 0.1), degToRad(deg: 90), 0, 0, 1)
        material.locksAmbientWithDiffuse = true
        material.diffuse.wrapS = SCNWrapMode.repeat
        material.diffuse.wrapT = SCNWrapMode.repeat
        material.diffuse.mipFilter = SCNFilterMode.linear

        // set the material to the 3d object geometry
        geom.firstMaterial = material
        
        let floorNode = SCNNode( geometry: geom )
        floorNode.physicsBody = body
        floorNode.name = "Floor"
        scene.rootNode.addChildNode(floorNode)

    }
    
    func createCoinFloor( scene: SCNScene, x: Float, y: Float, z: Float, width: Float, height: Float, length : Float )   {
        let node = createBlock( x: x, y: y, z: z, width: width, height: height, length: length, color: UIColor.white )
        scene.rootNode.addChildNode(node)
        
        node.physicsBody = SCNPhysicsBody.static()
        node.physicsBody!.friction = 4
    }
    
    func createPusher( scene : SCNScene, x : Float, y : Float, z: Float, length: Float ) -> SCNNode
    {
        let node = createBlock( x: x, y: y, z: z+0.01, width: 1, height: 0.5, length: length - 0.02, color: UIColor.gray )
        node.physicsBody = SCNPhysicsBody.kinematic()
        node.physicsBody!.friction = 1
        
        node.geometry!.firstMaterial!.shininess = 1.0;
        node.geometry!.firstMaterial!.shininess = 1.0;
        node.geometry!.firstMaterial!.specular.contents = UIColor.white
        scene.rootNode.addChildNode(node)

        return node
    }
    
    func createCoinGuard( scene : SCNScene, x: Float, y: Float, z: Float, height: Float, color: UIColor ) -> SCNNode
    {
        // Add slicer (the bit that stops the coin going backwards)
        let node = createBlock( x: x, y: y, z: z, width: 0.1, height: height, length: 5, color: color )
        node.physicsBody = SCNPhysicsBody.static()
        scene.rootNode.addChildNode(node)

        
        return node
    }
    
    func createSideWall( scene : SCNScene, x: Float, y: Float, z : Float, width: Float, height: Float ) -> SCNNode
    {
        // Add slicer (the bit that stops the coin going backwards)
        let node = createBlock( x: x, y: y, z: z, width: width, height: height, length: 0.1, color: UIColor( white:1, alpha: 0.4) )
        node.physicsBody = SCNPhysicsBody.static()
        scene.rootNode.addChildNode(node)

        return node
    }
    
    func createPins( scene : SCNScene )
    {
        let cylinder = SCNCylinder(radius: 0.01, height: 0.2)
        cylinder.radialSegmentCount = 5
        
        let pin = SCNNode( geometry: cylinder )
        pin.position = SCNVector3( x: 0.2, y: 4, z: 0 )
        pin.rotation = SCNVector4( x: 0, y: 0, z: 1, w: degToRad(deg: 90))
        
        pin.physicsBody = SCNPhysicsBody.static()
        
        // create and configure a material
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.black
        material.locksAmbientWithDiffuse = true
        
        // set the material to the 3d object geometry
        pin.geometry!.firstMaterial = material
        
        scene.rootNode.addChildNode(pin)

    }
    
    func createBlock( x: Float, y: Float, z: Float, width : Float, height : Float, length: Float, color: UIColor? ) -> SCNNode
    {
        let node = SCNNode()
        node.geometry = SCNBox(width: CGFloat(width), height: CGFloat(height), length: CGFloat(length), chamferRadius: 0)
        
        node.position = SCNVector3( x: x + width/2.0, y: y + height/2.0, z: z + length/2.0 )
        
        if let c = color
        {
            let material = SCNMaterial()
            material.diffuse.contents = c
            material.locksAmbientWithDiffuse = true
            
            // set the material to the 3d object geometry
            node.geometry!.firstMaterial = material
        }
        
        return node
    }
    
    func animatePusher( pusher : SCNNode, minX : Float, maxX : Float )
    {
        let animation: CAKeyframeAnimation = CAKeyframeAnimation(keyPath: "position.x")
        animation.values = [Float(minX),
            Float(maxX),
            Float(minX)]

        animation.duration = 3
        animation.repeatCount = MAXFLOAT //repeat forever
        pusher.addAnimation(animation, forKey: nil)
    }
    
    func addCoin( scene : SCNScene )
    {
        let val = (Float(arc4random()) / 0x100000000)

        // Add a little randomness so it doesn't quite fall in the center (otherwise it sticks on the pin
        var z :Float = 0.05
        if ( val < 0.5 )
        {
            z = -0.05
        }
        
        let coin = SCNNode()
        
        let cylinder = SCNCylinder(radius: 0.2, height: 0.09)
        cylinder.radialSegmentCount = 10
        
        coin.geometry = cylinder
        coin.position = SCNVector3( x: 0.15, y: 5, z: z )
        coin.rotation = SCNVector4( x: 0, y: 0, z: 1, w: degToRad(deg: 90))
        scene.rootNode.addChildNode(coin)
        
        coin.physicsBody = SCNPhysicsBody.dynamic()
        coin.physicsBody!.mass = 5
        coin.physicsBody!.friction = 0.7
        coin.physicsBody!.restitution = 0.2
        coin.name = "Coin"
        
        // create and configure a material
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.yellow
        material.locksAmbientWithDiffuse = true

        // set the material to the 3d object geometry
        coin.geometry!.firstMaterial = material

    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact)
    {
        // If coin collided with floor then remove the coin after fading it out
        if let nameA = contact.nodeA.name
        {
            if let nameB = contact.nodeB.name
            {
                if (nameA == "Coin" && nameB == "Floor") || (nameB == "Coin" && nameA == "Floor")
                {
                    let node = nameA == "Coin" ? contact.nodeA : contact.nodeB
                    
                    // Note we go to -1 just so the coin fades out properly rather that just disappearing
                    node.runAction(SCNAction.sequence([SCNAction.fadeOpacity(to: -0.2, duration: 2), SCNAction.removeFromParentNode()]))
                }
            }
            
        }
    }
    
    @objc func handleTap(_ gestureRecognizer: UIGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        addCoin( scene: scnView.scene!)
    }
    
    @objc func handlePan(_ gestureRecognizer: UIGestureRecognizer)
    {
        let point = gestureRecognizer.location(in: self.view)
        if ( gestureRecognizer.state == UIGestureRecognizer.State.began )
        {
            self.lastX = Float(point.x)
            self.lastY = Float(point.y)
        }

        let currX = Float(point.x)
        let currY = Float(point.y)
        if ( gestureRecognizer.numberOfTouches == 2 )
        {
            let dy = currY - lastY
            self.lookAt.position.y += -dy
        }
        
        let dx = currX - lastX

        angle += dx
        
        updateViewPosition()
        self.lastX = currX
        self.lastY = currY
    }
    
    func updateViewPosition()
    {
        let newX : Float = 8 * sin(degToRad(deg: angle))
        let newZ : Float = 8 * cos(degToRad(deg: angle))
        
        NSLog( "Angle - \(angle), newX - \(newX), newZ - \(newZ)" )
        cameraNode.position = SCNVector3( x:newX, y:6, z:newZ )
    }
}
