import UIKit
import Photos

class PhotoViewController: UIViewController {
    

    
    @IBOutlet var backButton: UIButton!
    @IBOutlet var saveButton: UIButton!
    @IBOutlet var imageView: UIImageView!
    var loadingView: UIView!
    
    var task:URLSessionDataTask!
        
     override var shouldAutorotate: Bool {
           return false
       } 

    
    @IBAction func back(_ sender: Any) {

        if let navController = self.navigationController {
            navController.popViewController(animated: true)
            navController.dismiss(animated: false, completion: nil)
        }
    }
    
    @IBAction func saveImage(_ sender: Any) {
        try? PHPhotoLibrary.shared().performChangesAndWait {
            PHAssetChangeRequest.creationRequestForAsset(from: self.imageView.image!)
       }
    }
    

    public override func loadView() {
        
        super.loadView()
        
        let loading = UIImage.gifImageWithName("owo")
        loadingView = UIImageView(image: loading)
        loadingView.frame = CGRect(x: view.center.x-80, y: view.center.y-70, width: 174, height: 141)
        view.addSubview(loadingView)
        view.sendSubviewToBack(imageView)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.task.cancel()
    }

}
