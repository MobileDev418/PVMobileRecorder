# PVMobileRecorder

this is guideline for build and run PVMobileRecorder app from scratch.

## Goals:

  - Decide how to display the text on the page to make it easy for someone to read and speak.
  - Deicde how to display the audio data in some method
  - Determine when each work is spoken and indicate the current word on the screen.
  - Determine the reason for this application and how it may be used.
  
## How to build and run

  - Install the XCode 9.0.
  - Open the PVMobileRecorder.xcodeproj from XCode.
  
## How to detect when a word is ended and a new word is started

  - Framework: Speech
  
    import Speech
    
    ....
    ....
    ....
    
    recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
      var isFinal = false

      if result != nil {

          print("Result =====> %s", result?.bestTranscription.formattedString ?? "")

          self.playerButton.isHidden = false

          self.textView.text = result?.bestTranscription.formattedString

          let resultString = result?.bestTranscription.formattedString

          var lastString: String = ""
          for wordnode in (result?.bestTranscription.segments)! {

              let indexTo = resultString?.index((resultString?.startIndex)!, offsetBy: wordnode.substringRange.location)
              lastString = (resultString?.substring(from: indexTo!))!

              print("Each Word detected from results =====> %s", lastString)
          }
          isFinal = (result?.isFinal)!
       }
    }
    ...
    ...
    ...
        

  
  
  
