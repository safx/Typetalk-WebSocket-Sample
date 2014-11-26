//
//  MasterViewController.swift
//  TypetalkKit+WebSocketSample
//
//  Created by Safx Developer on 2014/11/20.
//  Copyright (c) 2014年 Safx Developers. All rights reserved.
//

import UIKit
import TypetalkKit
import Starscream

class MasterViewController: UITableViewController, WebSocketDelegate {

    var detailViewController: DetailViewController? = nil
    var objects = NSMutableArray()
    var socket: WebSocket?

    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.clearsSelectionOnViewWillAppear = false
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //self.navigationItem.leftBarButtonItem = self.editButtonItem()

        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = controllers[controllers.count-1].topViewController as? DetailViewController
        }
        
        connectWebSocket()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func insertNewObject(obj: AnyObject) {
        objects.insertObject(obj, atIndex: 0)
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                let object = objects[indexPath.row]
                let controller = (segue.destinationViewController as UINavigationController).topViewController as DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell

        let object = objects[indexPath.row] as PostMessageResponse
        cell.textLabel!.text = object.post?.message
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            objects.removeObjectAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }

    // MARK: - WebSocket

    func connectWebSocket() {
        if Client.sharedClient.isSignedIn {
            let url = NSURL(scheme: "https", host: "typetalk.in", path: "/api/v1/streaming")!
            var socket = WebSocket(url: url)
            let token = Client.sharedClient.accessToken!
            socket.headers["Authorization"] = "Bearer \(token)"
            socket.delegate = self
            socket.connect()
            self.socket = socket
        } else {
            Client.sharedClient.authorize { (error) -> Void in
                if (error == nil) {
                    self.connectWebSocket()
                }
            }
        }
    }
    func websocketDidConnect() {
        println("connect")
    }
    func websocketDidDisconnect(error: NSError?) {
        if error?.domain == "Websocket" && error?.code == 1 {
            Client.sharedClient.requestRefreshToken { (err) -> Void in
                if err == nil {
                    self.connectWebSocket()
                }
            }
        }
        println("disconnect \(error)")
    }
    func websocketDidReceiveMessage(text: String) {
        println("message \(text)")
        let data = text.dataUsingEncoding(NSUnicodeStringEncoding)!
        let json = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as [String:AnyObject]
        let t = json["type"] as? String
        let d = json["data"] as? [String:AnyObject]
        if t != nil && d != nil {
            if t == "postMessage" {
                let res = PostMessageResponse(data: d!)
                self.insertNewObject(res)
                println(res)
            }
        }
    }
    func websocketDidReceiveData(data: NSData) {
        println("data \(data)")
    }
    func websocketDidWriteError(error: NSError?) {
        println("writeError \(error)")
    }
}

