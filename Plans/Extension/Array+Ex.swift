//
//  Array+Addition.swift
//  Plans
//
//  Created by Star on 7/10/20.
//  Copyright © 2020 Brainmobi. All rights reserved.
//

import Foundation

extension Array  {

    mutating func replace(arrPage: [Element]?, pageNumber: Int,  numberOfRowsInPage: Int) {
        guard let arrPage = arrPage, pageNumber > 0, numberOfRowsInPage > 0 else { return }
        var index = numberOfRowsInPage * (pageNumber - 1)
        for _ in 0...(numberOfRowsInPage - 1) {
            if index < count {
                remove(at: index)
            }
        }
        if index > count {
            index = count
        }
        insert(contentsOf: arrPage, at: index)
    }
}

extension MutableCollection where Self : RandomAccessCollection {
  mutating func sort(
    by firstPredicate: (Element, Element) -> Bool,
    _ secondPredicate: (Element, Element) -> Bool,
    _ otherPredicates: ((Element, Element) -> Bool)...
  ) {
    sort(by:) { lhs, rhs in
      if firstPredicate(lhs, rhs) { return true }
      if firstPredicate(rhs, lhs) { return false }
      if secondPredicate(lhs, rhs) { return true }
      if secondPredicate(rhs, lhs) { return false }
      for predicate in otherPredicates {
        if predicate(lhs, rhs) { return true }
        if predicate(rhs, lhs) { return false }
      }
      return false
    }
  }
}

extension Sequence {
  mutating func sorted(
    by firstPredicate: (Element, Element) -> Bool,
    _ secondPredicate: (Element, Element) -> Bool,
    _ otherPredicates: ((Element, Element) -> Bool)...
  ) -> [Element] {
    return sorted(by:) { lhs, rhs in
      if firstPredicate(lhs, rhs) { return true }
      if firstPredicate(rhs, lhs) { return false }
      if secondPredicate(lhs, rhs) { return true }
      if secondPredicate(rhs, lhs) { return false }
      for predicate in otherPredicates {
        if predicate(lhs, rhs) { return true }
        if predicate(rhs, lhs) { return false }
      }
      return false
    }
  }
}
