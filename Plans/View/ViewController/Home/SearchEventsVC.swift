//
//  SearchEventsVC.swift
//  Plans
//
//  Created by Star on 7/2/20.
//  Copyright © 2020 Brainmobi. All rights reserved.
//

import UIKit

class SearchEventsVC: PlansContentBaseVC {

    // MARK: - IBOutlets
    @IBOutlet weak var txtSearch: UITextField!
    @IBOutlet weak var colviewEventTypes: UICollectionView!
    @IBOutlet weak var tblviewEvents: UITableView!
    @IBOutlet weak var viewEmpty: UIView!
    
    // MARK: - Properties
    override var screenName: String? { "SearchEvent_Screen" }
    var eventTypes = ["Live","Upcoming","Public","Ended"]
    var selectedType : String = "Live"
    var flowLayout = UICollectionViewFlowLayout()
    var pageNumber = 1
    var arrEvents = [EventFeedModel]()
    var cellHeights = [IndexPath: CGFloat]()

    
    // MARK: - ViewController Life cycles
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // MARK: - Overrided Methods for BaseViewController
    
    override func hideLoader() {
        super.hideLoader()
        tblviewEvents.switchRefreshHeader(to: .normal(.success, 0.0))
        tblviewEvents.switchRefreshFooter(to: .normal)
    }

    // MARK: - User Action Handlers
    @IBAction func actionBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    

    // MARK: - Private Methods
    override func initializeData() {
        selectedType = "Live"
    }
    
    override func setupUI() {
        setupSearchView()
        setupEventTypesView()
        setupEventTableView()
        setupEmptyView()
    }
    
    func setupSearchView() {
        txtSearch.attributedPlaceholder = NSAttributedString(string: "Search",
                                                               attributes: [NSAttributedString.Key.foregroundColor: AppColor.whiteOpacity60])
        txtSearch.delegate = self
        txtSearch.addTarget(self, action: #selector(refreshAll), for: .editingChanged)
    }
    
    func setupEventTypesView() {
        colviewEventTypes.register(UINib(nibName:TabItemCell.className, bundle: nil), forCellWithReuseIdentifier: TabItemCell.className)
        colviewEventTypes.dataSource = self
        colviewEventTypes.delegate = self
    }
    
    func setupEventTableView() {
        tblviewEvents.registerMultiple(nibs: [SearchEventCell.className])
        tblviewEvents.dataSource = self
        tblviewEvents.delegate = self
        
        tblviewEvents.configRefreshHeader(with: refreshHeader, container:self) { [weak self] in
            self?.refreshAll()
        }
        
        tblviewEvents.configRefreshFooter(with: refreshFooter, container:self) { [weak self] in
            if let this = self, this.arrEvents.count % 10 == 0, this.arrEvents.count > 0 {
                this.getNextPage()
            }else {
                APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 1) {
                    self?.hideLoader()
                }
            }
        }

    }
    
    func setupEmptyView() {
        viewEmpty.isHidden = true
    }
    
    func updateEmptyView() {
        if arrEvents.count > 0 {
            viewEmpty.isHidden = true
        }else {
            viewEmpty.isHidden = false
        }
    }
    
    func getNextPage(isShowLoader: Bool = false) {
        pageNumber = arrEvents.count / 10 + ((arrEvents.count % 10) > 0 ? 1 : 0) + 1
        getEventListForSearch(eventType: selectedType, isShowLoader: isShowLoader, pageNumber: pageNumber)
    }
    
    @objc override func refreshAll(isShowLoader: Bool = false) {
        getEventListForSearch(eventType: selectedType, isShowLoader: isShowLoader, pageNumber: 1, numberOfRows: pageNumber * 10)
    }
    
    func updateData(list: [EventFeedModel]?, pageNumber: Int = 1, numberOfRowsInPage: Int = 10) {
        if pageNumber == 1 { arrEvents.removeAll() }
        self.arrEvents.replace(arrPage: list, pageNumber: pageNumber, numberOfRowsInPage: numberOfRowsInPage)
        self.tblviewEvents.reloadData()
        self.updateEmptyView()
    }

    
    // MARK: - Backend APIs
    func getEventListForSearch(eventType: String,
                               isShowLoader: Bool = false,
                               pageNumber: Int = 1,
                               numberOfRows: Int = 10 ) {
        if isShowLoader == true { showLoader() }
        
        var type = eventType.lowercased()
        if type == "ended" { type = "end" }
        
        let dictParam1 = ["pageNo" : pageNumber,
                          "count" : numberOfRows,
                          "keyword" : txtSearch.text ?? "",
                          "type" : type,
                          "address": ""] as [String : Any]
        
        EVENT_SERVICE.getEventListForSearchApi(dictParam1).done { (response) -> Void in
            self.hideLoader()
            self.updateData(list: response, pageNumber: pageNumber, numberOfRowsInPage: numberOfRows)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }

    

}

// MARK: - UITextFieldDelegate
extension SearchEventsVC : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        refreshAll(isShowLoader: true)
        return true
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout

extension SearchEventsVC : UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return eventTypes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TabItemCell.className, for: indexPath) as? TabItemCell else { return UICollectionViewCell() }
        let type = eventTypes[indexPath.row]
        cell.eventTypeName.text = type
        if type == selectedType {
            cell.colorLbl.backgroundColor = UIColor.white
        }else{
            cell.colorLbl.backgroundColor = UIColor.clear
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let type = eventTypes[indexPath.row]
        if selectedType != type {
            selectedType = type
            pageNumber = 1
            refreshAll(isShowLoader: true)
            collectionView.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: MAIN_SCREEN_WIDTH / 4.0, height:38)
    }

}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension SearchEventsVC : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrEvents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchEventCell.className, for: indexPath) as? SearchEventCell else { return UITableViewCell() }
        cell.configureEventCell(eventFeed: arrEvents[indexPath.row], isHiddenSeparator: indexPath.row == (arrEvents.count - 1))
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        APP_MANAGER.pushEventDetailsVC(eventId: arrEvents[indexPath.row]._id, sender: self)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.size.height
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? UITableView.automaticDimension
    }

}


