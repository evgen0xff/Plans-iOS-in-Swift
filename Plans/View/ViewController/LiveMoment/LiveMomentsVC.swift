//
//  LiveMomentsVC.swift
//  Plans
//
//  Created by Star on 2/15/21.
//

import UIKit

class LiveMomentsVC: EventBaseVC {

    enum SectionType {
        case watchAll
        case addLiveMoment
        case liveMoment
        case empty
    }
    
    // MARK: - IBOutlets

    @IBOutlet weak var txtfSearch: UITextField!
    @IBOutlet weak var colvLiveMoments: LiveMomentsCollectionView!
    
    
    // MARK: - Properties
    var listUserMoments = [UserLiveMomentsModel]()
    var isEnableAdd: Bool = false
    var countEmptyCells = 0
    var totoalCellCount : Int {
        return (isEnableAdd ? 1 : 0) + listUserMoments.count + countEmptyCells
    }
    var cellSize = CGSize()

    // MARK: - ViewController Life Cycles

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func setupUI() {
        super.setupUI()
        
//        btnWatchAll.layer.borderColor = AppColor.grey_button_border.cgColor

        setupSearchTextView()
        setupCollectionView()
    }
    
    override func refreshAll(isShowLoader: Bool = false) {
        super.refreshAll(isShowLoader: isShowLoader)
       
        getEventDetails(eventID) { (success, event) in
            self.hideLoader()
            self.updateUI(self.txtfSearch)
        }
    }
    
    
    override func hideLoader() {
        super.hideLoader()
        colvLiveMoments.switchRefreshHeader(to: .normal(.success, 0.0))
        colvLiveMoments.switchRefreshFooter(to: .normal)
    }


    // MARK: - User Actions
    @IBAction func actionBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionWatchAll(_ sender: Any) {
        APP_MANAGER.pushWatchLiveMomentsVC(event: activeEvent, sender: self)
    }
    
    // MARK: - Private Methods
    private func setupSearchTextView() {
        txtfSearch.attributedPlaceholder = NSAttributedString(string: "Search",
                                                               attributes: [NSAttributedString.Key.foregroundColor: AppColor.whiteOpacity60])
        txtfSearch.delegate = self
        txtfSearch.addTarget(self, action: #selector(updateUI(_ :)), for: .editingChanged)

    }
    
    private func setupCollectionView() {
        colvLiveMoments.contentInset = UIEdgeInsets(top: 0, left: 11.0, bottom: 30.0, right: 11.0)
        cellSize.width = (MAIN_SCREEN_WIDTH - (colvLiveMoments.contentInset.left + colvLiveMoments.contentInset.right)) / 3.0
        cellSize.height = cellSize.width * (169.0 / 98.0)

        colvLiveMoments.register(UINib(nibName: AddLiveMomentCell.className, bundle: nil), forCellWithReuseIdentifier: AddLiveMomentCell.className)
        colvLiveMoments.register(UINib(nibName: EventLiveMomentCell.className, bundle: nil), forCellWithReuseIdentifier: EventLiveMomentCell.className)
        colvLiveMoments.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "EmptyCell")

        colvLiveMoments.delegate = self
        colvLiveMoments.dataSource = self
        
        colvLiveMoments.configRefreshHeader(with: refreshHeader, container:self) { [weak self] in
            self?.refreshAll()
        }
        colvLiveMoments.configRefreshFooter(with: refreshFooter, container:self) { [weak self] in
            APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 1) {
                self?.hideLoader()
            }
        }

    }
    

    @objc func updateUI(_ textfield:UITextField) {
        listUserMoments.removeAll()
        var search: [UserLiveMomentsModel]?
        if let text = textfield.text, text.count > 0 {
            search = activeEvent?.liveMoments?.filter { (momentModel) -> Bool in
                if momentModel.user?.fullName?.lowercased().contains(text.lowercased()) == true {
                    return true
                }else {
                    return false
                }
            }
        }
        
        if search != nil {
            self.listUserMoments.append(contentsOf: search!)
        }else if let moments = activeEvent?.liveMoments, moments.count > 0 {
            self.listUserMoments.append(contentsOf: moments)
        }
        
        isEnableAdd = activeEvent?.isEnableAddLiveMoment() ?? false
        colvLiveMoments.isEnableAdd = isEnableAdd
        
        colvLiveMoments.reloadData()
    }


    
    private func getSectionFrom(indexPath: IndexPath) -> (type:SectionType?, row:Int) {
        var type: SectionType?
        var row: Int = indexPath.row
        switch indexPath.section {
        case 0:
            type = .watchAll
            break
        case 1:
            let countAdd = isEnableAdd ? 1 : 0
            if indexPath.row < countAdd {
                type = .addLiveMoment
            }else if indexPath.row < (countAdd + listUserMoments.count) {
                type = .liveMoment
                row -= countAdd
            }else if indexPath.row < totoalCellCount {
                type = .empty
                row -= countAdd + listUserMoments.count
            }
            break
        default:
            break
        }
        return (type, row)
    }

}

// MARK: - UITextFieldDelegate
extension LiveMomentsVC : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
}

// MARK: - LiveMomentsCollectionView
class LiveMomentsCollectionView : UICollectionView {
    
    var isEnableAdd = false
    var cellAddLiveMoment: UIView?
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        var result = super.hitTest(point, with: event)
        
        if isEnableAdd == true,
           USER_MANAGER.isShownPostTutorial == false,
           let cell = cellAddLiveMoment {
            
            let origin = cell.convert(CGPoint.zero, to: self)
            let framTapToPost = CGRect(origin: CGPoint(x: origin.x, y: origin.y + cell.bounds.height), size: CGSize(width: 154, height: 72))

            if framTapToPost.contains(point) == true {
                result = cellAddLiveMoment?.hitTest(CGPoint(x: 16, y: cell.bounds.height + 5), with: event)
            }
        }

        return result
    }

}


// MARK: - UICollectionViewDataSource
extension LiveMomentsVC : UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 1:
            return totoalCellCount
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        var cell: UICollectionViewCell?

        let section = getSectionFrom(indexPath: indexPath)
        switch section.type {
        case .addLiveMoment:
            if let addCell = collectionView.dequeueReusableCell(withReuseIdentifier: AddLiveMomentCell.className, for: indexPath) as? AddLiveMomentCell {
                addCell.lblAddLiveMoment.font = AppFont.regular.size(17.0)
                addCell.setupUI(event: activeEvent)
                cell = addCell
                colvLiveMoments.cellAddLiveMoment = cell
            }
            break
        case .liveMoment:
            if let momentCell = collectionView.dequeueReusableCell(withReuseIdentifier: EventLiveMomentCell.className, for: indexPath) as? EventLiveMomentCell {
                momentCell.setupUI(liveMoment: listUserMoments[section.row])
                cell = momentCell
            }
            break
        case .empty:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmptyCell", for: indexPath)
            let view = UIView(frame: CGRect(x: 4, y: 2, width: (cellSize.width - 8), height: cellSize.height - 4))
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
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderWatchAll", for: indexPath)
        header.viewWithTag(100)?.layer.borderColor = AppColor.grey_button_border.cgColor
        
        return header
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension LiveMomentsVC: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch section {
        case 0: return CGSize(width: 0, height: 61)
        default: return CGSize(width: 0, height: 0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize{
        return cellSize
    }

}

// MARK: - UICollectionViewDelegate
extension LiveMomentsVC : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = getSectionFrom(indexPath: indexPath)
        switch section.type {
        case .addLiveMoment:
            APP_MANAGER.pushLiveMomentCameraVC(event: activeEvent, sender: self)
            break
        case .liveMoment:
            APP_MANAGER.pushWatchLiveMomentsVC(event:  activeEvent,
                                               user:   listUserMoments[section.row].user,
                                               sender: self)
            break
        default:
            break
        }
    }


}

