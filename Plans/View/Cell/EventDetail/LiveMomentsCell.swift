//
//  LiveMomentsCell.swift
//  Plans
//
//  Created by Plans Collective LLC on 5/31/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit

class LiveMomentsCell: BaseTableViewCell {

    // MARK: - IBOutlets
    @IBOutlet weak var colvLiveMoments: UICollectionView!
    @IBOutlet weak var viewShowAll: UIView!
    @IBOutlet weak var btnShowAll: UIButton!
    @IBOutlet weak var viewBottomSeparator: UIView!
    
    var eventModel: EventFeedModel?
    var isEnableAdd: Bool = false
    var liveMoments = [UserLiveMomentsModel]()
    var countEmptyCells = 3
    var cellAddLiveMoment: UIView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        layer.zPosition = 1
        
        colvLiveMoments.register(UINib(nibName: AddLiveMomentCell.className, bundle: nil), forCellWithReuseIdentifier: AddLiveMomentCell.className)
        colvLiveMoments.register(UINib(nibName: EventLiveMomentCell.className, bundle: nil), forCellWithReuseIdentifier: EventLiveMomentCell.className)
        colvLiveMoments.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "EmptyCell")

        colvLiveMoments.delegate = self
        colvLiveMoments.dataSource = self
        colvLiveMoments.contentInset = UIEdgeInsets(top: 0, left: 11.0, bottom: 0.0, right: 11.0)
        colvLiveMoments.layer.zPosition = 1

        btnShowAll.layer.borderColor = AppColor.grey_button_border.cgColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    // MARK: - User Actions
    @IBAction func actionShowAll(_ sender: Any) {
        APP_MANAGER.pushLiveMomentsVC(event: eventModel)
    }
    
    // MARK: - Public Methods
    func setupUI(event: EventFeedModel?, isHiddenSeparator: Bool = false){
        layer.zPosition = 1
        colvLiveMoments.layer.zPosition = 1
        
        eventModel = event
        viewBottomSeparator.isHidden = isHiddenSeparator
        isEnableAdd = event?.isEnableAddLiveMoment() ?? false
        liveMoments.removeAll()
        if let moments = event?.liveMoments, moments.count > 0 {
            liveMoments.append(contentsOf: moments)
        }
        viewShowAll.isHidden = !(liveMoments.count > 3)
        countEmptyCells = (isEnableAdd ? 3 : 4) - liveMoments.count
        countEmptyCells = countEmptyCells > 0 ? countEmptyCells : 0
        colvLiveMoments.reloadData()
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var result = super.point(inside: point, with: event)

        if isEnableAdd == true, USER_MANAGER.isShownPostTutorial == false  {
            let origin = colvLiveMoments.convert(CGPoint.zero, to: self)
            let framTapToPost = CGRect(origin: CGPoint(x: origin.x, y: origin.y + colvLiveMoments.bounds.height), size: CGSize(width: 154, height: 72))
            result = result || framTapToPost.contains(point)
        }

        return result
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        var result = super.hitTest(point, with: event)
        
        if isEnableAdd == true, USER_MANAGER.isShownPostTutorial == false  {
            let origin = colvLiveMoments.convert(CGPoint.zero, to: self)
            let framTapToPost = CGRect(origin: CGPoint(x: origin.x, y: origin.y + colvLiveMoments.bounds.height), size: CGSize(width: 154, height: 72))

            if framTapToPost.contains(point) == true {
                result = cellAddLiveMoment?.hitTest(CGPoint(x: 16, y: 175), with: event)
            }
        }

        return result
    }

    
    
}

// MARK: - UICollectionViewDataSource
extension LiveMomentsCell: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return isEnableAdd ? 1 : 0
        case 1:
            return liveMoments.count
        case 2:
            return countEmptyCells
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell?
        
        switch indexPath.section {
        case 0:
            if let addCell = collectionView.dequeueReusableCell(withReuseIdentifier: AddLiveMomentCell.className, for: indexPath) as? AddLiveMomentCell {
                addCell.lblAddLiveMoment.font = AppFont.regular.size(13.0)
                addCell.setupUI(event: eventModel)
                cell = addCell
                cellAddLiveMoment = cell
            }
            break
        case 1:
            if let momentCell = collectionView.dequeueReusableCell(withReuseIdentifier: EventLiveMomentCell.className, for: indexPath) as? EventLiveMomentCell {
                momentCell.setupUI(liveMoment: liveMoments[indexPath.row])
                cell = momentCell
            }
            break
        case 2:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmptyCell", for: indexPath)
            let view = UIView(frame: CGRect(x: 4, y: 2, width: 90, height: 165))
            view.layer.cornerRadius = 10.0
            view.backgroundColor = AppColor.grey_background_placeholder
            cell?.addSubview(view)
            cell?.backgroundColor = .clear
            break
        default:
            break
        }
        
        return cell ?? UICollectionViewCell()
    }
}

// MARK: - UICollectionViewDelegate

extension LiveMomentsCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            APP_MANAGER.pushLiveMomentCameraVC(event: eventModel)
            break
        case 1:
            APP_MANAGER.pushWatchLiveMomentsVC(event: eventModel,
                                               user: liveMoments[indexPath.row].user)
            break
        default:
            break
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension LiveMomentsCell : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize{
        return CGSize(width: 98, height: 169)
    }
    
}


