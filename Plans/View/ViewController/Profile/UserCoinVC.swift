//
//  UserCoinVC.swift
//  Plans
//
//  Created by Star on 2/22/21.
//

import UIKit

class UserCoinVC: UserBaseVC {

    // MARK: - IBOutlets

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleName: UILabel!

    // MARK: - Properties
    let numberOfCoins = 18

    // MARK: - ViewController Life Cycel

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func initializeData() {
        super.initializeData()
    }
    
    override func setupUI() {
        super.setupUI()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset = UIEdgeInsets(top: 6, left: 5, bottom: 6, right: 5)
        updateUI(user: activeUser)
    }
    
    override func refreshAll(isShowLoader: Bool = false) {
        super.refreshAll(isShowLoader: isShowLoader)
        getProfile(isShowLoader: isShowLoader){
            user in
            self.updateUI(user: user)
        }
    }

    // MARK: User Actions
    @IBAction func actionBackBtn(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Private Methods
    private func updateUI(user: UserModel?) {
        guard let user = user else { return }
        
        titleName.text = "\(user.firstName ?? "")"
        titleName.text! += user.lastName != nil ? " \(user.lastName ?? "")" : ""
        titleName.text! += "'s Badges"
        collectionView.reloadData()
    }
    
}

extension UserCoinVC: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfCoins
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CoinCell", for: indexPath)
        let coinNum = activeUser?.coinNumber ?? 0
        (cell.viewWithTag(1) as? UIImageView)?.image = indexPath.row < coinNum ? UIImage(named: "ic_star_\(indexPath.row + 1)_large") : UIImage(named: "ic_lock_circle_green_lagre")
        return cell
    }
}

extension UserCoinVC : UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize{
        let width = (MAIN_SCREEN_WIDTH - 10.0) / 3.0
        return CGSize(width: width, height: width)
    }
}


