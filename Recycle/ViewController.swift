import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var capturePreviewView: UIView!
    @IBOutlet var captureButton: UIButton!
    
    let cameraController = CameraController()
    let database = Database()
    var vc:PhotoViewController!

    let blue = UIColor(red: 126/255, green: 201/255, blue: 231/255, alpha: 1)
    let green = UIColor(red: 126/255, green: 231/255, blue: 149/255, alpha: 1)

    let session = URLSession.shared
    var googleAPIKey = "nope"
    var googleURL: URL {
        return URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(googleAPIKey)")!
    }
       
    var results:JSON!
    var handoff:UIImage!
    
    override var shouldAutorotate: Bool {
        return false
    } 

    

    override func viewDidLoad() {
        
        
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: view.frame.width / 2, y: captureButton.center.y - 83), radius: CGFloat(40), startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)

           let shapeLayer = CAShapeLayer()
           shapeLayer.path = circlePath.cgPath
           shapeLayer.fillColor = UIColor.clear.cgColor
           shapeLayer.strokeColor = UIColor.white.cgColor
           shapeLayer.lineWidth = 5.0

           view.layer.addSublayer(shapeLayer)
        
        
            cameraController.prepare {(error) in
                if let error = error {
                    print(error)
                }
                
                try? self.cameraController.displayPreview(on: self.capturePreviewView)
            }
        
    }



    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      
        if let vc = segue.destination as? PhotoViewController {
            cameraController.captureImage {(image, error) in
                              guard let image = image else {
                                  print(error ?? "Image capture error")
                                  return
                       }
                
                self.vc = vc
                                       
               /* let croppedCGImage = image.cgImage?.cropping(to: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
                let croppedImage = UIImage(cgImage: croppedCGImage!) */
                let imageData = self.base64EncodeImage(image)
                self.createRequest(with: imageData)
            
            }
        }
    }
  
    
    func base64EncodeImage(_ image: UIImage) -> String {

        var imagedata = image.pngData()
    
            imagedata = resizeImage(image: image)
        
        
        return imagedata!.base64EncodedString(options: .endLineWithCarriageReturn)
    }
    
    func resizeImage(image: UIImage) -> Data {
        
        let newSize = CGSize(width: UIScreen.main.nativeBounds.width, height: UIScreen.main.nativeBounds.height)
        UIGraphicsBeginImageContext(newSize)
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        let resizedImage = newImage!.pngData()
        
        UIGraphicsEndImageContext()
        
        self.handoff = newImage


        return resizedImage!
    }
    
    func createRequest(with imageBase64: String) {
        
        var request = URLRequest(url: googleURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Bundle.main.bundleIdentifier ?? "", forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        
        // Build our API request
        let jsonRequest = [
            "requests": [
                "image": [
                    "content": imageBase64
                ],
                "features": [
                    [
                        "type": "OBJECT_LOCALIZATION",
                        "maxResults": 10
                    ],
                ]
            ]
        ]
        let jsonObject = JSON(jsonRequest)
        
        // Serialize the JSON
        guard let data = try? jsonObject.rawData() else {
            return
        }
        
        request.httpBody = data
        
        // Run the request on a background thread
      DispatchQueue.global().async { self.runRequestOnBackgroundThread(request) }
    }
    
    func runRequestOnBackgroundThread(_ request: URLRequest) {
        // run the request
        
        self.vc.task = session.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "")
                return
            }
            
            self.analyzeResults(data)
        }
        
        self.vc.task.resume()
    }
    
    func analyzeResults(_ dataToParse: Data) {
          
          
          // Update UI on the main thread
          DispatchQueue.main.async(execute: {
              
              
              // Use SwiftyJSON to parse results
              let json = JSON(data: dataToParse)
              let errorObj: JSON = json["error"]
              
              // Check for errors
              if (errorObj.dictionaryValue != [:]) {
                  print("Error code \(errorObj["code"]): \(errorObj["message"])");
              } else {
                  // Parse the response
                  let responses: JSON = json["responses"][0]
                  self.results = responses["localizedObjectAnnotations"]
                 
                  
              
              }
            
            
        
            UIGraphicsBeginImageContext(self.handoff.size)
            
            print(self.handoff.size)
            
            self.handoff.draw(at: CGPoint(x: 0, y: 0))
            let context = UIGraphicsGetCurrentContext()!
            context.setStrokeColor(UIColor.green.cgColor)
            context.setAlpha(0.5)
            context.setLineWidth(5.0)
            
            
            for (_, result) in self.results {
                
                let item = result["name"].string!
                let rect = self.boundingPoly(result)
                print(item)
                let status = 1// self.database.contains(item);

                var todo:NSString = ""
                let textFont:UIFont = UIFont(name: "RobotoCondensed-Regular", size: 36)!
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .right
                context.setAlpha(1.0)
                
                let lineWidth = 5.0
                let path = UIBezierPath(roundedRect: rect.insetBy(dx: CGFloat(lineWidth/2), dy: CGFloat(lineWidth/2)), cornerRadius: 15)
                path.lineWidth = CGFloat(lineWidth)
                let att:[NSAttributedString.Key : Any]
        
                if (status > 0) {
                    
                    if (status == 1) {
                        self.blue.setStroke()
                        todo = "recycle\t"
                        
                        
                         att = [NSAttributedString.Key.font: textFont,
                                NSAttributedString.Key.foregroundColor: self.blue,
                                NSAttributedString.Key.paragraphStyle: paragraphStyle]

                    } else  {
                        
                        self.green.setStroke()
                        todo = "compost\t"
                        
                        att = [NSAttributedString.Key.font: textFont,
                               NSAttributedString.Key.foregroundColor: self.green,
                               NSAttributedString.Key.paragraphStyle: paragraphStyle]
                    }

                    todo.draw(in: rect, withAttributes: att)
                    path.stroke()
                }
            }
            
            
            let myImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            self.vc.imageView.image  = myImage!
            self.vc.loadingView.isHidden = true
            self.vc.saveButton.isEnabled = true
            self.vc.backButton.tintColor = UIColor.white



              
          })
          
      }
    
    func boundingPoly(_ result: JSON) -> CGRect {
        
        
        let imgWidth:CGFloat = self.handoff.size.width
        let imgHeight:CGFloat = self.handoff.size.height
        

        let xMultiplier = result["boundingPoly"]["normalizedVertices"][0]["x"].float ?? 0
        let yMultiplier = result["boundingPoly"]["normalizedVertices"][0]["y"].float ?? 0
        
        let boxWidthMultiplier = result["boundingPoly"]["normalizedVertices"][2]["x"].float ?? 0
        let boxHeightMultiplier = result["boundingPoly"]["normalizedVertices"][2]["y"].float ?? 0
        
        var x = CGFloat(xMultiplier) * imgWidth
        var y = CGFloat(yMultiplier) * imgHeight
        var width = CGFloat(boxWidthMultiplier - xMultiplier) * imgWidth
        var height = CGFloat(boxHeightMultiplier - yMultiplier) * imgHeight
        
       
        //exceptions:
        //under teh camera thingy
        
        let keyWindow =  UIApplication.shared.windows.first { $0.isKeyWindow }!

        if (y < ( keyWindow.safeAreaInsets.top)) {
            y =  keyWindow.safeAreaInsets.top
            let difference = keyWindow.safeAreaInsets.top - y
            height = height - difference
        }
        
        //too small
        if (width < 20 || height < 20) {
            width = 0
            height = 0
        } 
        
        return CGRect(x: x, y: y, width: width, height: height)
        
    }
}



