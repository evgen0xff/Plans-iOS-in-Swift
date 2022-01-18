//
//  MainTabBarVC.swift
//  Plans
//
//  Created by Star on 2/3/21.
//

import UIKit

class MainTabBarVC: UITabBarController {

    enum TabType {
        case home
        case location
        case notification
        case profile
    }
    
    // MARK: - IBoutlets

    @IBOutlet var viewOverLayer: UIView!
    @IBOutlet weak var imgvPopOver: UIImageView!
    @IBOutlet weak var lblPopOver: UILabel!
    

    // MARK: - Properties
    let imagesItem = ["ic_home_grey", "ic_pin_map_grey", "ic_bell_grey", "ic_user_grey"]
    let imagesItemSelected = ["ic_home_purple", "ic_pin_map_purple", "ic_bell_purple", "ic_user_purple"]

    var btnCenterAction : UIButton?

    // MARK: - ViewController Life Cycel
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NOTIFICATION_CENTER.addObserver(self, selector: #selector(updateBadge), name: Notification.Name(rawValue: kRefreshBadges), object: nil)
        updateUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NOTIFICATION_CENTER.removeObserver(self, name: Notification.Name(rawValue: kRefreshBadges), object: nil)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if let btnCenterAction = btnCenterAction {
            view.bringSubviewToFront(btnCenterAction)
        }

        if let viewOverLayer = viewOverLayer, viewOverLayer.isHidden == false {
            view.bringSubviewToFront(viewOverLayer)
        }
    }


    // MARK: - User action handler
    @IBAction func actionTapOverLayer(_ sender: Any) {
        hideOverLayer()
    }
    
    @objc func actionCenterBtn(sender: AnyObject) {
        APP_MANAGER.pushCreateEventVC()
    }

    
    // MARK: - Prviate Meothods
    private func initialize() {
        delegate = self
        NOTIFICATION_CENTER.addObserver(self, selector: #selector(didAppBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)

        APP_MANAGER.initForNewHome(self)
        setupUI()
    }
    
    private func setupUI() {
        setupBottomBar()
    }
    
    private func setupBottomBar() {
        // Adjust Tabbar item image
        if #available(iOS 13, *) {
        }else {
            tabBar.items?.forEach({ (item) in
                item.imageInsets = UIEdgeInsets.init(top: 6, left: 0, bottom: -6, right: 0)
            })
        }
        
        tabBar.items?.enumerated().forEach({ (index, item) in
            item.image = UIImage(named: imagesItem[index])?.withRenderingMode(.alwaysOriginal)
            item.selectedImage = UIImage(named: imagesItemSelected[index])?.withRenderingMode(.alwaysOriginal)
            item.badgeColor = AppColor.pink_badge
        })
        
        // Add Center action button
        viewControllers?.insert(UIViewController(), at: 2)
        setupCenterBtn()
    }
    
    func repositionBadge(tabIndex: Int){
        guard tabIndex < tabBar.subviews.count else { return }
        tabBar.subviews[tabIndex].subviews.forEach { badgeView in
            if NSStringFromClass(badgeView.classForCoder) == "_UIBadgeView" {
                badgeView.layer.transform = CATransform3DIdentity
                badgeView.layer.transform = CATransform3DMakeTranslation(-7.0, 3.0, 1.0)
            }
        }
    }
    
    
    private func setupCenterBtn() {
        removeCenterBtn()
        
        let height : CGFloat = 64.0
        let width : CGFloat = 64.0
        let x = tabBar.frame.origin.x + tabBar.frame.size.width / 2.0 - width / 2.0
        let y = tabBar.frame.origin.y - 8.0 - UIDevice.current.heightBottomNotch

        btnCenterAction = UIButton.init(frame: CGRect(x:x , y: y, width: width, height: height))
        btnCenterAction?.setImage(UIImage(named : "ic_plus_circle_purple"), for: .normal)
        btnCenterAction?.addTarget(self, action: #selector(actionCenterBtn(sender:)), for: .touchUpInside)
        btnCenterAction?.isHidden = false

        view.addSubview(btnCenterAction!)
        view.bringSubviewToFront(btnCenterAction!)
    }
    
    private func removeCenterBtn() {
        btnCenterAction?.removeFromSuperview()
        btnCenterAction?.isHidden = true
        btnCenterAction = nil
    }
    
    
    // MARK: - Public Methods
    public func updateUI(isHiddenCenterAction: Bool? = nil) {

        // Show/Hide Center Button
        if let isHidden = isHiddenCenterAction {
            btnCenterAction?.isHidden = isHidden
        }
        
        updateBadge()
    }
    
    @objc func updateBadge() {
        // Update Notification Item Icon
        let indexNotificationTab = (viewControllers?.count ?? 0) - 2
        guard indexNotificationTab >= 0,
              indexNotificationTab < viewControllers?.count ?? 0 else { return }

        if USER_MANAGER.countUnviewedNotify > 0 {
            tabBar.items![indexNotificationTab].badgeValue = "\(USER_MANAGER.countUnviewedNotify)"
            repositionBadge(tabIndex: indexNotificationTab)
        }else {
            tabBar.items![indexNotificationTab].badgeValue = nil
        }
    }

    public func getTabType (_ index: Int) -> TabType {
        var tabType = TabType.home
        switch index {
        case 0 :
            tabType = .home
        case 1 :
            tabType = .location
        case (viewControllers?.count ?? 0) - 2:
            tabType = .notification
        case (viewControllers?.count ?? 0) - 1:
            tabType = .profile
        default:
            tabType = .home
        }
        return tabType
    }

    public func getTabIndex (_ tabType: TabType) -> Int {
        var index = 0
        switch tabType {
        case .home:
            index = 0
        case .location:
            index = 1
        case .notification:
            index = (self.viewControllers?.count ?? 0) - 2
        case .profile:
            index = (self.viewControllers?.count ?? 0) - 1
        }
        return index
    }

    public func selectTab(_ tabType: TabType) {
        selectTab(getTabIndex(tabType))
    }
    
    public func selectTab (_ index : Int?) {
        if index != nil, index! >= 0, let controllers = self.viewControllers, index! < controllers.count {
            self.selectedIndex = index!
        }
    }
    
    public func getTabItemVC (_ index : Int) -> UIViewController? {
        guard index >= 0, let controllers = self.viewControllers, index < controllers.count else {
            return nil
        }
        return controllers[index]
    }
    
    // Pop Over Layer
    func popUpEventLive(event: EventFeedModel?) {
        guard let event = event else { return }
        imgvPopOver.image = UIImage(named: "ic_live_large")
        lblPopOver.text = "You are live at " + (event.eventName ?? "") + "!"
        viewOverLayer.isHidden = false
        viewOverLayer.frame = view.bounds
        view.addSubview(viewOverLayer)
        view.bringSubviewToFront(viewOverLayer)
    }
    
    func popUpNewCoin(coin: Int?) {
        guard let coin = coin, coin > 0 else { return }
        imgvPopOver.image = UIImage(named: "ic_star_\(coin)_large")
        lblPopOver.text = "Congratulations!\nYou earned a new badge!"
        viewOverLayer.isHidden = false
        viewOverLayer.frame = view.bounds
        view.addSubview(viewOverLayer)
        view.bringSubviewToFront(viewOverLayer)
    }
    
    public func hideOverLayer() {
        viewOverLayer.isHidden = true
        viewOverLayer.removeFromSuperview()
    }
    
    @objc func didAppBecomeActive(_ notification: Notification) {
        updateUI()
        APP_MANAGER.getLivedEventsForEnding()
    }

    
}

// MARK: - Tab Bar Delegate Method

extension MainTabBarVC: UITabBarControllerDelegate {
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool{
        return true
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController){
    }
}



