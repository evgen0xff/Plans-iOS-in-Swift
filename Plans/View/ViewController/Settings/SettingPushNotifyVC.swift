//
//  SettingPushNotifyVC.swift
//  Plans
//
//  Created by Star on 2/23/21.
//
import UIKit

class SettingPushNotifyVC: UserBaseVC {

    // MARK: - All IBOutlet
    @IBOutlet weak var tableView: UITableView!
    

    // MARK: - All Properties
    var settings : SettingsModel?
    var isOnline : Bool = true
    
    // MARK: - View LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func refreshAll(isShowLoader: Bool = false) {
        super.refreshAll(isShowLoader: isShowLoader)
        getSettings()
    }
    
    override func setupUI() {
        super.setupUI()
        tableView.register(nib: SettingOptionCell.className)
    }

    
    @IBAction func actionBackBtn(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    // MARK: - Set Up Navigation
    
    
    func updateUI(isOnline: Bool = true) {
        self.isOnline = isOnline
        tableView.reloadData()
    }
}

// MARK: - TableView delegates
extension SettingPushNotifyVC : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings?.pushNotifications?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SettingOptionCell.className, for: indexPath) as? SettingOptionCell else { return UITableViewCell()}
        cell.setupUI(model: settings?.pushNotifications?[indexPath.row], delegate: self, isActive: isOnline)
        return cell
    }
}

// MARK: - SettingOptionCell Delegate
extension SettingPushNotifyVC: SettingOptionCellDelegate {
    
    func didValueChanged(optionModel: SettingOptionModel?, status: Bool) {
        updateSettings(optionModel, status: status)
    }
    
}

// MARK: - Hit api
extension SettingPushNotifyVC {
    private func updateSettings(_ optionModel: SettingOptionModel?, status: Bool) {

        guard let key = optionModel?.key else { return }
        let dict = [key: status] as [String : Any]

        SETTING_SERVICES.updateSettings(dict).done { (response) -> Void in
            self.settings = response
            self.updateUI(isOnline: true)
            }.catch { (error) in
                self.updateUI(isOnline: false)
                POPUP_MANAGER.handleError(error)
        }
    }
    
    private func getSettings (isShownLoading : Bool = true) {
        if isShownLoading {
            showLoader()
        }
        SETTING_SERVICES.getSettings().done { (response) -> Void in
            self.hideLoader()
            self.settings = response
            self.updateUI(isOnline: true)
        }.catch { (error) in
            self.hideLoader()
            self.updateUI(isOnline: false)
            POPUP_MANAGER.handleError(error)
        }
    }
}


