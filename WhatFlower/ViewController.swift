//
//  ViewController.swift
//  Seafood
//
//  Created by Venkatesh on 6/5/18.
//  Copyright © 2018 venkatesh. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage
class ViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"

    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    let imagePicker = UIImagePickerController()
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
    }
    func detect(image:CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("unable to load model")
        }
        
        let request = VNCoreMLRequest(model: model, completionHandler: { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("unable to fetch results")
            }
            if let firstResult = results.first {
                let flowerName = firstResult.identifier.capitalized
                self.navigationItem.title = flowerName
                self.fetchFlowerInfo(flowerName: flowerName)
            }
        })
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        }
        catch{
            print(error)
        }
        
        
    }
    @IBAction func CameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let userPickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            guard let ciimage = CIImage(image: userPickedImage) else {
                fatalError("Couldnot convert uiimage to ciimage")
            }
            detect(image: ciimage)
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func fetchFlowerInfo(flowerName: String) {
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize": "500"
            ]

        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if(response.result.isSuccess) {
                let flowerJson = JSON(response.result.value!)
                let pageid = flowerJson["query"]["pageids"][0].stringValue
                let flowerdescription = flowerJson["query"]["pages"][pageid]["extract"].stringValue
                let imageUrl = flowerJson["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                self.imageView.sd_setImage(with: URL(string: imageUrl))
                self.descriptionTextView.text = flowerdescription
            }
        }
    }
}


