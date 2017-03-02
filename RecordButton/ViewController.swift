//
//  ViewController.swift
//  RecordButtonTest
//
//  Created by Mark Alldritt on 2016-12-19.
//  Copyright © 2016 Late Night Software Ltd. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var recordButton: RecordButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func toggleRecording(_ sender: RecordButton) {
        print(recordButton.isRecording ? "Recording Started" : "Recording Ended")
    }
}

