//
//  ViewController.swift
//  PVMobileRecorder
//
//  Created by Ma Huateng on 11/6/17.
//  Copyright © 2017 Ma Huateng. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
	
	@IBOutlet weak var textView: UITextView!
	@IBOutlet weak var recorderButton: UIButton!
    @IBOutlet weak var playerButton: UIButton!
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var audioPlayer: AVAudioPlayer?
    var audioRecorder: AVAudioRecorder?
    
	override func viewDidLoad() {
        super.viewDidLoad()
        
        speechRecognizer.delegate = self
        
        recorderButton.isEnabled = false
        playerButton.isHidden = true
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            var isButtonEnabled = false
            
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                self.recorderButton.isEnabled = isButtonEnabled
            }
        }
        
        let fileMgr = FileManager.default
        
        let dirPaths = fileMgr.urls(for: .documentDirectory, in: .userDomainMask )
        
        let soundFileURL = dirPaths[0].appendingPathComponent("sound.caf")
        
        let recordingSetting = [AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
                                AVEncoderBitRateKey: 16,
                                AVNumberOfChannelsKey: 2,
                                AVSampleRateKey: 44100.0] as [String : Any]
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            //            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        do {
            try audioRecorder = AVAudioRecorder(url: soundFileURL, settings: recordingSetting as [String : AnyObject])
            audioRecorder?.prepareToRecord()
        } catch let error as NSError {
            print("audioSession error: \(error.localizedDescription)")
        }
	}

    // MARK: ------- Action -------
	@IBAction func onClickRecordandStop(_ sender: AnyObject) {
        if audioEngine.isRunning {
            audioEngine.stop()
            
            audioRecorder?.stop()
            
            recognitionRequest?.endAudio()
            recorderButton.isEnabled = false
            playerButton.isHidden = true
            recorderButton.setImage(#imageLiteral(resourceName: "record-start"), for: .normal)
        } else {
            startRecording()
            playerButton.isHidden = false
            playerButton.isEnabled = false
            recorderButton.setImage(#imageLiteral(resourceName: "record-stop"), for: .normal)
        }
	}
    
    @IBAction func onClickPlayandPause(_ sender: Any) {
        
        if audioRecorder?.isRecording == false {
            playerButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
            
            do {
                try audioPlayer = AVAudioPlayer(contentsOf: (audioRecorder?.url)!)
                
                audioPlayer?.delegate = self
                audioPlayer?.prepareToPlay()
                audioPlayer?.volume = 80
                audioPlayer?.play()
                
                recognizeFile(url: (audioRecorder?.url)!)
            } catch let error as NSError {
                print("audioPlayer error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: ------ AVAudioPlayerDelegate ------
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playerButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Audio Play Decode Error")
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("Audio Record Encode Error")
    }
    
    func startRecording() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        ///
        audioRecorder?.record()
        ///
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                print("Result =====> %s", result?.bestTranscription.formattedString ?? "")
                
                self.playerButton.isHidden = false
//
//                self.textView.text = result?.bestTranscription.formattedString
//
//                let resultString = result?.bestTranscription.formattedString
//
//                var lastString: String = ""
//                for wordnode in (result?.bestTranscription.segments)! {
//                    let indexTo = resultString?.index((resultString?.startIndex)!, offsetBy: wordnode.substringRange.location)
//                    lastString = (resultString?.substring(from: indexTo!))!
//
//                    print("Each Word detected from results =====> %s", lastString)
//                }
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.playerButton.isEnabled = true
                self.recorderButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        textView.text = "Please recode your voice."
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recorderButton.isEnabled = true
            playerButton.isEnabled = true
        } else {
            recorderButton.isEnabled = false
            playerButton.isEnabled = false
        }
    }
    
    func recognizeFile(url: URL) {
        guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else {
            return
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        recognizer.recognitionTask(with: request) { result, error in
            guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else {
                return
            }
            if let result = result {
                self.textView.text = result.bestTranscription.formattedString
//                if result.isFinal {
//                    self.searchFlight(number: result.bestTranscription.formattedString)
//                }
            } else if let error = error {
                print(error)
            }
        }
    }
}

