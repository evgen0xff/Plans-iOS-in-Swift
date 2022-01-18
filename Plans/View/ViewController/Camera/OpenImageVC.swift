//
//  OpenImageVC.swift
//  Plans
//
//  Created by Anmol's Macbook Air on 07/12/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit
import AlamofireImage

class OpenImageVC: EventBaseVC {

    // MARK: - IBOutlets
    
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var titleName: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var viewBackground: UIView!
    // MARK: - Properties
    
    var eventName: String?
    var imageStr: String?
    var image : UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setUp()
    }
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    // MARK: - Set Up View
    
    private func setUp() {
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.zoomScale = 1.0
        scrollView.delegate = self

        self.titleName.text = eventName
        if let imageStr = imageStr, let url = URL(string: imageStr) {
            imgView.setImage_Plans(url: url)
        }else {
            imgView.image = image
        }
    }
    
    // MARK: - Back Button Method
    
    @IBAction func backMehtod() {
        navigationController?.popViewController(animated: true)
    }
}

extension OpenImageVC : UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return viewBackground
    }
}
