//
//  TutorialVC.swift
//  Plans
//
//  Created by BrainMobi on 4/23/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit

class TutorialVC: BaseViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var imageCollection: UICollectionView!
    @IBOutlet weak var getstartedBtn: UIButton!
    @IBOutlet weak var pagecontrol: UIPageControl!
    
    // MARK: - Property
    
    internal var dataSource = [[String : String]]()
    
    // MARK: - View Life cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {
        pagecontrol.subviews.forEach {
            $0.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Private Methods
    override func initializeData() {
        dataSource =  [["image":"im_tutorial_organize", "title":"Organize","detail":"Create, schedule, and invite \nfriends to events."],
                       ["image":"im_tutorial_attend", "title":"Attend","detail":"Find an event you like \nand join your friends."],
                       ["image":"im_tutorial_share", "title":"Share","detail":"Capture live moments \nwith your friends."]]
    }
    
    override func setupUI(){
        getstartedBtn.isHidden = true
    }
    
    func manageBottomView(){
        if pagecontrol.currentPage == 2{
            getstartedBtn.isHidden = false
        }
        else{
            getstartedBtn.isHidden = true
        }
    }
    
    // MARK: - IBAction Methods
    
    @IBAction func pageControl(_ sender: UIPageControl) {
        let x = CGFloat(pagecontrol.currentPage) * imageCollection.frame.size.width
        imageCollection.setContentOffset(CGPoint(x:x, y:0), animated: true)
        manageBottomView()
    }
    
}

// MARK: - Collection View Data Sources

extension TutorialVC:UICollectionViewDataSource
{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TutorialCell", for: indexPath) as? TutorialCell else {
            return UICollectionViewCell()
        }
        let snapShot = dataSource[indexPath.item]
        cell.setupUI(dic: snapShot);
        return cell
    }
}

extension TutorialVC:UICollectionViewDelegate, UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize{
        return CGSize(width: collectionView.frame.size.width, height: collectionView.frame.size.height)
    }
}

// MARK: - Scroll View Delegates
extension TutorialVC:UIScrollViewDelegate{
    
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        let x = scrollView.contentOffset.x
        let w = scrollView.bounds.size.width
        
        pagecontrol.currentPage = Int(x/w)
        manageBottomView()
    }
}


