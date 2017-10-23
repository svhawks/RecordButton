//
//  ViewController.swift
//  RecordButtonDemo
//
//  Created by Okaris 2017 on 24/09/2017.
//  Copyright © 2017 okaris. All rights reserved.
//

import UIKit
import RecordButton

class ViewController: UIViewController {

  @IBOutlet weak var recordButton: RecordButton!

  var progressTimer : Timer!
  var progress : CGFloat! = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
  }

  @IBAction func recordButtonTapped(button: RecordButton){
    print("Recording: ", button.buttonState == .recording)
    switch button.buttonState {
    case .recording:
      record()
    case .idle:
      stop()
    case .hidden:
      stop()
    }
  }

  func record() {
    self.progressTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(ViewController.updateProgress), userInfo: nil, repeats: true)
  }

  func updateProgress() {

    let maxDuration = CGFloat(5) // Max duration of the recordButton

    progress = progress + (CGFloat(0.05) / maxDuration)
    recordButton.setProgress(progress)
    if progress >= 1 {
      progressTimer.invalidate()
      stop()
    }

  }

  func stop() {
    self.progressTimer.invalidate()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

}

