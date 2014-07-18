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


func join(s1: String, s2: String, joiner: String) -> String {
    return s1 + joiner + s2
}

func degToRad( deg : Float ) -> Float
{
    return ((deg) / 180.0 * Float(M_PI))
}


class GameViewController: UIViewController, SCNSceneRendererDelegate, SCNPhysicsContactDelegate
{
    let cameraNode = SCNNode()
    var lastX : Float = 0
    var angle : Float = 0

    var pusher1 : SCNNode!
    var pusher2 : SCNNode!
    var coinGuard1 : SCNNode!
    var coinGuard2 : SCNNode!
    var coinRestrict : SCNNode!
    var sideWall1 : SCNNode!
    var sideWall2 : SCNNode!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        let scene = SCNScene()
        
        setupEnvironment( scene );
        
        setupScene( scene );
        
        
        // Make the camera look at the scene
        let lookAt = SCNNode()
        lookAt.position = SCNVector3( x: 0, y: 0, z: 0 )
        let lookAtConstraint = SCNLookAtConstraint(target: lookAt);
        lookAtConstraint.gimbalLockEnabled = true;
        cameraNode.constraints = [lookAtConstraint];

        // retrieve the SCNView
        let scnView = self.view as SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
        scnView.scene.physicsWorld.speed = 3;
        scnView.scene.physicsWorld.contactDelegate = self;
        scnView.jitteringEnabled = true;
        
        // show statistics such as fps and timing information
//        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.blackColor()
        scnView.delegate = self;
        scnView.play(nil);
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: "handleTap:")
        let dragGesture = UIPanGestureRecognizer(target: self, action: "handlePan:")
        scnView.addGestureRecognizer(tapGesture)
        scnView.addGestureRecognizer(dragGesture)
        
        // Start the pushers
        animatePusher( pusher1, minX : -0.5, maxX : 0.5 )
        animatePusher( pusher2, minX : 1.5, maxX : 2.5 )
    }
    
    
    func setupEnvironment( scene: SCNScene )
    {
        // create and add a camera to the scene
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 2, y: 6, z: 8)
        
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light.type = SCNLightTypeOmni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light.type = SCNLightTypeAmbient
        ambientLightNode.light.color = UIColor.darkGrayColor()
        scene.rootNode.addChildNode(ambientLightNode)
    }
    
    
    func setupScene( scene: SCNScene )
    {
        // Create a plane
        createFloor( scene )
        createCoinFloor( scene, x:0, y: 2.9, z:-2.5, width : 2, length : 5 );
        createCoinFloor( scene, x:2, y: 1.9, z:-2.5, width : 2, length : 5 );
        
        pusher1 = createPusher( scene, x: -0.5, y: 3, z:-2.5, length:5 )
        pusher2 = createPusher( scene, x:  1.5, y: 2, z:-2.5, length:5 )
        coinGuard1 = createCoinGuard( scene, x: 0, y: 3.5, z: -2.5, height: 1, color: UIColor.whiteColor() );
        coinGuard2 = createCoinGuard( scene, x: 2, y: 2.5, z: -2.5, height: 0.5, color: UIColor.whiteColor() );
        coinRestrict = createCoinGuard( scene, x: 0.2, y: 3.9, z: -2.5, height:0.6, color: UIColor.clearColor() ) //( white: 1, alpha: 0.2) );
        sideWall1 = createSideWall( scene, x: 0, y: 0, z: -2.52, width:5, height:4.5 )
        sideWall2 = createSideWall( scene, x: 0, y: 0, z: 2.52, width:5, height:4.5 )
        
        createPins( scene )
    }
    
    
    func createFloor( scene: SCNScene )
    {
        var geom = SCNFloor()
        geom.reflectivity = 0
        
        let floorNode = SCNNode( geometry: geom );
        scene.rootNode.addChildNode(floorNode);
        
        var physBody = SCNPhysicsShape(geometry: floorNode.geometry, options: nil)
        floorNode.physicsBody = SCNPhysicsBody(type: .Static, shape: physBody)
        floorNode.physicsBody.friction = 4;
        floorNode.name = "Floor"
        
        // create and configure a material
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.redColor()
        
        // set the material to the 3d object geometry
        floorNode.geometry.firstMaterial = material
    }
    
    func createCoinFloor( scene: SCNScene, x: Float, y: Float, z: Float, width: Float, length : Float ) -> SCNNode
    {
        var node = createBlock( x, y: y, z: z, width: width, height: 0.1, length: length, color: UIColor.whiteColor() )
        scene.rootNode.addChildNode(node);
        
        node.physicsBody = SCNPhysicsBody.staticBody()
        node.physicsBody.friction = 4;
        
        return node
    }
    
    func createPusher( scene : SCNScene, x : Float, y : Float, z: Float, length: Float ) -> SCNNode
    {
        var node = createBlock( x, y: y, z: z, width: 1, height: 0.5, length: length, color: UIColor.grayColor() )
        node.physicsBody = SCNPhysicsBody.kinematicBody()
        node.physicsBody.friction = 1
        scene.rootNode.addChildNode(node);

        return node
    }
    
    func createCoinGuard( scene : SCNScene, x: Float, y: Float, z: Float, height: Float, color: UIColor ) -> SCNNode
    {
        // Add slicer (the bit that stops the coin going backwards)
        var node = createBlock( x, y: y, z: z, width: 0.1, height: height, length: 5, color: color )
        node.physicsBody = SCNPhysicsBody.staticBody()
        scene.rootNode.addChildNode(node)

        
        return node
    }
    
    func createSideWall( scene : SCNScene, x: Float, y: Float, z : Float, width: Float, height: Float ) -> SCNNode
    {
        // Add slicer (the bit that stops the coin going backwards)
        var node = createBlock( x, y: y, z: z, width: width, height: height, length: 0.1, color: UIColor( white:1, alpha: 0.4) )
        node.physicsBody = SCNPhysicsBody.staticBody()
        scene.rootNode.addChildNode(node)

        return node
    }
    
    func createPins( scene : SCNScene )
    {
        let cylinder = SCNCylinder(radius: 0.01, height: 0.2)
        cylinder.radialSegmentCount = 5
        
        var pin = SCNNode( geometry: cylinder )
        pin.position = SCNVector3( x: 0.2, y: 4, z: 0 );
        pin.rotation = SCNVector4( x: 0, y: 0, z: 1, w: degToRad(90))
        
        pin.physicsBody = SCNPhysicsBody.staticBody()
        
        // create and configure a material
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.blackColor()
        material.locksAmbientWithDiffuse = true
        
        // set the material to the 3d object geometry
        pin.geometry.firstMaterial = material
        
        scene.rootNode.addChildNode(pin)

    }
    
    func createBlock( x: Float, y: Float, z: Float, width : Float, height : Float, length: Float, color: UIColor? ) -> SCNNode
    {
        var node = SCNNode()
        node.geometry = SCNBox(width: CGFloat(width), height: CGFloat(height), length: CGFloat(length), chamferRadius: 0)
        
        node.position = SCNVector3( x: x + width/2.0, y: y + height/2.0, z: z + length/2.0 )
        
        if let c = color
        {
            let material = SCNMaterial()
            material.diffuse.contents = c
            material.locksAmbientWithDiffuse = true
            
            // set the material to the 3d object geometry
            node.geometry.firstMaterial = material
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
        let val = (Float(arc4random()) / 0x100000000);

        // Add a little randomness so it doesn't quite fall in the center (otherwise it sticks on the pin
        var z :Float = 0.05
        if ( val < 0.5 )
        {
            z = -0.05
        }
        
        var coin = SCNNode()
        
        let cylinder = SCNCylinder(radius: 0.2, height: 0.09)
        cylinder.radialSegmentCount = 10
        
        coin.geometry = cylinder
        coin.position = SCNVector3( x: 0.15, y: 5, z: z );
        coin.rotation = SCNVector4( x: 0, y: 0, z: 1, w: degToRad(90))
        scene.rootNode.addChildNode(coin)
        
        var physBody = SCNPhysicsShape(geometry: coin.geometry, options: nil)
        coin.physicsBody = SCNPhysicsBody.dynamicBody() //(type: .Dynamic, shape: physBody)
        coin.physicsBody.mass = 5
        coin.physicsBody.friction = 0.7
        coin.physicsBody.restitution = 0.2
        coin.name = "Coin"
        
        // create and configure a material
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.yellowColor()
        material.locksAmbientWithDiffuse = true

        // set the material to the 3d object geometry
        coin.geometry.firstMaterial = material

    }
    
    func physicsWorld(world: SCNPhysicsWorld!, didBeginContact contact: SCNPhysicsContact!)
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
                    node.runAction(SCNAction.sequence([SCNAction.fadeOpacityTo(-0.2, duration: 2), SCNAction.removeFromParentNode()]))
                }
            }
            
        }
    }
    
    func handleTap(gestureRecognizer: UIGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as SCNView
        
        addCoin( scnView.scene)
    }
    
    func handlePan(gestureRecognizer: UIGestureRecognizer)
    {
        if ( gestureRecognizer.state == UIGestureRecognizerState.Began )
        {
            self.lastX = Float(gestureRecognizer.locationInView(self.view).x);
        }

        let currX = Float(gestureRecognizer.locationInView(self.view).x);
        
        let dx = currX - lastX
        angle += dx;
        
        var newX : Float = 8 * sin(degToRad(angle));
        var newZ : Float = 8 * cos(degToRad(angle));
        
        cameraNode.position = SCNVector3( x:newX, y:6, z:newZ )
        self.lastX = currX
        // retrieve the SCNView
        let scnView = self.view as SCNView
        
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> Int {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return Int(UIInterfaceOrientationMask.AllButUpsideDown.toRaw())
        } else {
            return Int(UIInterfaceOrientationMask.All.toRaw())
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}
