//
//  UITableView+Ex.swift
//  Plans
//
//  Created by Plans Collective LLC on 4/16/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit

extension UITableView {
    
    // Register nib on UITableView...
    func register(nib nibName:String) {
        let nib = UINib(nibName: nibName, bundle: nil)
        self.register(nib, forCellReuseIdentifier: nibName)
    }
    
    // Register multiple nib at once
    func registerMultiple(nibs arrayNibs:[String]) {
        for nibName in arrayNibs {
            register(nib: nibName)
        }
    }
    
    func hideEmptyCells() {
        let view = UIView()
        view.backgroundColor = .clear
        view.frame = .zero
        self.tableFooterView = view
    }
    
    func scrollToTop(animation: Bool) {
        if self.tableHeaderView != nil {
            self.setContentOffset(.zero, animated: animation)
        } else {
            let indexPath = IndexPath(row: 0, section: 0)
            self.scrollToRow(at: indexPath, at: .top, animated: animation)
        }
    }
    
    func scrollToBottom(animation: Bool) {
        var sectionLast = -1
        var rowLast = -1
        
        for i in 0..<numberOfSections {
            let section = (numberOfSections - 1) - i
            if section >= 0 {
                let row = numberOfRows(inSection: section) - 1
                if row >= 0 {
                    sectionLast = section
                    rowLast = row
                    break
                }
            }
        }
        
        if sectionLast >= 0, rowLast >= 0 {
            let indexPath = IndexPath(row: rowLast, section: sectionLast)
            self.scrollToRow(at: indexPath, at: .bottom, animated: animation)
        }
    }
    
    func register<T:UITableViewCell>(_: T.Type) where T: ReusableView {
        self.register(T.self, forCellReuseIdentifier: T.defaultReuseIdentifier)
    }
    
    func register<T:UITableViewCell>(_: T.Type) where T: ReusableView, T: NibLoadableView {
        let bundle = Bundle(for: T.self)
        let nib = UINib(nibName: T.nibName, bundle: bundle)
        
        self.register(nib, forCellReuseIdentifier: T.defaultReuseIdentifier)
    }
    
    func dequeueReusableCell<T:UITableViewCell>() -> T where T: ReusableView {
        guard let cell = self.dequeueReusableCell(withIdentifier: T.defaultReuseIdentifier) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.defaultReuseIdentifier)")
        }
        return cell
    }
    
    func dequeueReusableCell<T:UITableViewCell>(forIndexPath indexPath: IndexPath) -> T where T: ReusableView {
        guard let cell = self.dequeueReusableCell(withIdentifier: T.defaultReuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.defaultReuseIdentifier)")
        }
        return cell
    }
}

protocol ReusableView: class {
    static var defaultReuseIdentifier: String { get }
}

protocol NibLoadableView: class {
    static var nibName: String { get }
}

extension ReusableView where Self: UIView {
    static var defaultReuseIdentifier: String {
        return String(describing: Self.self)
    }
}

extension NibLoadableView where Self: UIView {
    static var nibName: String {
        return String(describing: Self.self)
    }
}
