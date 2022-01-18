//
//  CalendarVC.swift
//  Plans
//
//  Created by Star on 2/7/21.
//

import UIKit
import FSCalendar
import EventKit

class CalendarVC: EventBaseVC {
    
    // MARK: - IBOutlets
    @IBOutlet weak var viewTopBar: UIView!
    @IBOutlet weak var viewSearch: UIView!
    @IBOutlet weak var txtSearch: UITextField!
    @IBOutlet weak var viewHeader: UIView!
    @IBOutlet weak var calendarView: FSCalendar!
    @IBOutlet weak var viewFooter: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lblMonth: UILabel!
    @IBOutlet weak var btnCreateEvent: UIButton!
    

    // MARK: - Properties
    override var screenName: String? { "Calendar_Screen" }

    var selectedDate : Date?
    var searchedEventList = [EventCalendarModel]()
    var allEventList = [EventCalendarModel]()
    var datesEvent = [Date]()
    let eventStore = EKEventStore()

    
    // MARK: - ViewController Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI(date: selectedDate, isMonth: true)
    }

    // MARK: - User action handlers
    @IBAction func actionBackBtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionCreateEvent(_ sender: Any) {
        APP_MANAGER.pushCreateEventVC(sender: self)
    }
    
    // MARK: - Private Methods
    override func initializeData() {
        selectedDate = selectedDate ?? Date()
    }
    
    override func setupUI() {
        setupSearchTextField()
        setupTableView()
        setupCalendarView()
        setupEmptyView()
    }
    
    private func setupEmptyView() {
        btnCreateEvent.layer.borderColor = AppColor.grey_button_border.cgColor
        viewFooter.isHidden = true
    }
    
    private func updateEmptyViewHeight() {
        var height = tableView.bounds.height - (tableView.tableHeaderView?.bounds.height ?? 0) - 28.0
        if height < 110 {
            height = 110
        }
        tableView.tableFooterView?.frame.size.height = height
        tableView.tableFooterView?.sizeToFit()
        tableView.tableFooterView?.layoutIfNeeded()
    }
    
    private func setupSearchTextField() {
        txtSearch.delegate = self
        txtSearch.attributedPlaceholder = NSAttributedString(string: "Search",
                                                             attributes: [NSAttributedString.Key.foregroundColor: AppColor.whiteOpacity60])
        txtSearch.addTarget(self, action: #selector(searchPlaceAsPerText(_ :)), for: .editingChanged)
    }
    
    private func setupTableView() {
        tableView.register(UINib(nibName: CalendarSectionView.className, bundle: nil), forHeaderFooterViewReuseIdentifier: CalendarSectionView.className)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = viewHeader
        tableView.tableFooterView = viewFooter
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0.0
        }
    }
    
    private func setupCalendarView() {
        viewHeader.isHidden = false
        calendarView.delegate = self
        calendarView.dataSource = self
        calendarView.appearance.headerMinimumDissolvedAlpha = 0.0
        calendarView.appearance.headerDateFormat = "MMMM yyyy"
        calendarView.appearance.caseOptions = .weekdayUsesSingleUpperCase
        calendarView.scope = .month
        calendarView.clipsToBounds = true
        calendarView.appearance.selectionColor = .clear
        calendarView.appearance.borderSelectionColor = .white
        calendarView.appearance.todayColor = UIColor.white.withAlphaComponent(0.3)
        calendarView.appearance.headerTitleColor = UIColor.white
        calendarView.calendarWeekdayView.isHidden = false
        calendarView.appearance.weekdayTextColor = UIColor.white
        calendarView.appearance.titleDefaultColor = UIColor.white
        calendarView.appearance.weekdayFont = AppFont.bold.size(17)
        calendarView.appearance.titleFont = AppFont.bold.size(17)
        calendarView.weekdayHeight = 40.0
        calendarView.rowHeight = 100.0
        calendarView.appearance.borderRadius = 1.0
        calendarView.appearance.imageOffset = CGPoint(x: 0, y: -30)
        calendarView.clipsToBounds = true
        calendarView.appearance.titleSelectionColor = UIColor.white
        calendarView.headerHeight = 0
        calendarView.placeholderType = .none
        calendarView.appearance.titleOffset = CGPoint(x: 0, y: 0)
        calendarView.today = Date()
        calendarView.select(selectedDate, scrollToDate: true)
    }
    
    private func updateUI (date : Date? = nil, isMonth : Bool = false) {
        let curDate = date ?? Date()
        
        lblMonth.text = curDate.dateStringWith(strFormat: "MMMM yyyy")
        var startTime, endTime : Double?
        if isMonth == false {
            startTime = curDate.startTimeOfDay()?.timeIntervalSince1970
            endTime = curDate.endTimeOfDay()?.timeIntervalSince1970
        } else {
            startTime = curDate.firstDayofMonth()?.timeIntervalSince1970
            endTime = curDate.lastDayofMonth()?.timeIntervalSince1970
        }
        getEventCalendar(startTime: startTime, endTime: endTime, isMonth: isMonth)
    }
    
    private func updateEmptyUI() {
        viewFooter.isHidden = searchedEventList.count > 0 ? true : false
        updateEmptyViewHeight()
    }
    
    private func updateData (list: [EventCalendarModel], isMonth: Bool = false) {
        allEventList.removeAll()
        if isMonth == true {
            datesEvent.removeAll()
        }
        let newList = list.sorted(by: { ($0.startTime ?? 0) > ($1.startTime ?? 0) })
        allEventList = newList.filter({ (model) -> Bool in
            if let startTime = model.startTime, let endTime = model.endTime {
                if let startDate = Date(timeIntervalSince1970: startTime).startTimeOfDay(),
                    let endDate = Date(timeIntervalSince1970: endTime).startTimeOfDay() {
                    if let seleStart = selectedDate?.startTimeOfDay() {
                        if startDate == seleStart || endDate == seleStart {
                            return true
                        }
                        if startDate < seleStart, endDate > seleStart {
                            return true
                        }
                    }
                }
            }
            return false
        })
        
        newList.forEach { (model) in
            if let startTime = model.startTime {
                if let endTime = model.endTime {
                    if var startDate = Date(timeIntervalSince1970: startTime).startTimeOfDay(),
                        let endDate = Date(timeIntervalSince1970: endTime).startTimeOfDay() {
                        while startDate <= endDate {
                            if datesEvent.contains(startDate) == false {
                                datesEvent.append(startDate)
                            }
                            startDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
                        }
                    }
                }
            }
            if let value = USER_DEFAULTS.value(forKey: kSyncCalendar) as? Bool,
                value == true {
                self.checkCalendarAuthorizationStatus(model)
            }
        }
        calendarView.reloadData()
        searchPlaceAsPerText(txtSearch)
        updateEmptyUI()
    }
    
    // MAKR: - Sync Events with Phone Calendar
        
    func checkCalendarAuthorizationStatus(_ model: EventCalendarModel) {
        let status = EKEventStore.authorizationStatus(for: EKEntityType.event)
        switch (status) {
        case EKAuthorizationStatus.notDetermined:
            // This happens on first-run
            requestAccessToCalendar(model)
        case EKAuthorizationStatus.authorized:
            // Things are in line with being able to show the calendars in the table view
            addEvents(model)
        case EKAuthorizationStatus.restricted, EKAuthorizationStatus.denied:
            break
        default:
            break
        }
    }

        
    private func requestAccessToCalendar(_ model: EventCalendarModel) {
        eventStore.requestAccess(to: EKEntityType.event, completion: {
            (accessGranted: Bool, error: Error?) in
            if accessGranted == true {
                APP_CONFIG.defautMainQ.async(execute: {
                    self.addEvents(model)
                })
            }
        })
    }
        
    private func addEvents(_ model: EventCalendarModel) {
        // Create an Event Store instance
        eventStore.requestAccess(to: .event) { (granted, error) in
            if (granted) && (error == nil) {
                
                guard let startTimeT = model.startTime else { return }
                guard let endTimeT = model.endTime else { return }
                
                let startTime = Date(timeIntervalSince1970: startTimeT)
                let endTime = Date(timeIntervalSince1970: endTimeT)
                
                if startTime < endTime {
                } else {
                    return
                }
                
                let predicate2 = self.eventStore.predicateForEvents(withStart: startTime as Date, end: endTime as Date, calendars: nil)
                let eV = self.eventStore.events(matching: predicate2) as [EKEvent]
                if eV.count > 0 {
                    for i in eV {
                        do {
                            (try self.eventStore.remove(i, span: EKSpan.thisEvent, commit: true))
                        }
                        catch{}
                    }
                }
                
                let event:EKEvent = EKEvent(eventStore: self.eventStore)
                event.startDate = startTime
                event.endDate = endTime
                if let eventName = model.eventsName {
                    event.title = eventName
                } else {
                    return
                }
                event.calendar = self.eventStore.defaultCalendarForNewEvents
                
                // Save the calendar using the Event Store instance
                do {
                    try self.eventStore.save(event, span: .thisEvent)
                } catch {}
            }
        }
        
        // This lists every reminder
        let predicate = eventStore.predicateForReminders(in: [])
        eventStore.fetchReminders(matching: predicate) { reminders in
        }
    }

    
    
    // MARK: - Publice Methods
    
    // MARK: - Notification Handlers
    @objc internal func searchPlaceAsPerText(_ textfield:UITextField) {
        searchedEventList.removeAll()
        
        if let searchText = textfield.text?.lowercased().trimmingCharacters(in: .whitespaces), searchText.count > 0 {
            for model in allEventList {
                if let name = model.eventsName?.lowercased(), name.contains(searchText) {
                    searchedEventList.append(model)
                }
            }
        } else {
            searchedEventList.append(contentsOf: allEventList)
        }
        tableView.reloadData()
    }
    
    // MARK: - Backend Apis
    func getEventCalendar(startTime : Double?, endTime : Double?, isMonth: Bool = false) {
        guard let startTime = startTime, let endTime = endTime else { return }
        
        let dict = ["start" : startTime,
                    "end" : endTime]
        EVENT_SERVICE.getEventCalenderListApi(dict).done { (userResponse) -> Void in
            self.updateData(list: userResponse, isMonth: isMonth)
        }.catch { (error) in
            POPUP_MANAGER.handleError(error)
        }
    }


}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension CalendarVC : UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return selectedDate != nil ? 1 : 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchedEventList.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let calendarSectionView = tableView.dequeueReusableHeaderFooterView(withIdentifier: CalendarSectionView.className ) as? CalendarSectionView else { return nil }
        switch section {
        case 0:
            if let selectedDate = selectedDate {
                let strStartDate = selectedDate.dateStringWith(strFormat: "EE, MMM dd")
                let calendar = Calendar.current
                if calendar.isDateInToday(selectedDate){
                    calendarSectionView.lblDay.text = "Today - " + strStartDate
                } else if calendar.isDateInTomorrow(selectedDate) {
                    calendarSectionView.lblDay.text = "Tomorrow - " + strStartDate
                } else if calendar.isDateInYesterday(selectedDate)  {
                    calendarSectionView.lblDay.text = "Yesterday - " + strStartDate
                } else {
                    calendarSectionView.lblDay.text =  strStartDate
                }
            }

        default:
            break
        }
        return calendarSectionView
        
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let calendarEventCell = tableView.dequeueReusableCell(withIdentifier: CalendarEventCell.className, for: indexPath) as? CalendarEventCell else { return UITableViewCell() }
        calendarEventCell.configureCellWithData(searchedEventList[indexPath.row], selectedDate: selectedDate)
        return calendarEventCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 28.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = searchedEventList[indexPath.row]
        APP_MANAGER.pushEventDetailsVC(eventId: model._id, sender: self)
    }


}


// MARK: - UITextfieldDelegate
extension CalendarVC : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
}

// MARK: - FSCalendarDelegate, FSCalendarDataSource
extension CalendarVC : FSCalendarDelegate, FSCalendarDataSource {
    func calendar(_ calendar: FSCalendar, imageFor date: Date) -> UIImage? {
        if datesEvent.contains(date) == true {
            return UIImage(named: "ic_dot_1_white")
        }
        return nil
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        selectedDate = date
        updateUI(date: selectedDate)
    }
    
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        selectedDate = calendar.currentPage
        calendar.select(selectedDate)
        updateUI(date: selectedDate, isMonth: true)
    }

    
    
}
