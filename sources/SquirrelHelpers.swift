//
//  SquirrelHelpers.swift
//  Squirrel
//
//  Created by Leo Liu on 5/11/24.
//

import Foundation
import CoreGraphics

infix operator ?= : AssignmentPrecedence
// swiftlint:disable:next operator_whitespace
func ?=<T>(left: inout T, right: T?) {
  if let right = right {
    left = right
  }
}
// swiftlint:disable:next operator_whitespace
func ?=<T>(left: inout T?, right: T?) {
  if let right = right {
    left = right
  }
}

extension NSRange {
  static let empty = NSRange(location: NSNotFound, length: 0)
}

extension NSPoint {
  static func += (lhs: inout Self, rhs: Self) {
    lhs.x += rhs.x
    lhs.y += rhs.y
  }
  static func - (lhs: Self, rhs: Self) -> Self {
    Self.init(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
  }
  static func -= (lhs: inout Self, rhs: Self) {
    lhs.x -= rhs.x
    lhs.y -= rhs.y
  }
  static func * (lhs: Self, rhs: CGFloat) -> Self {
    Self.init(x: lhs.x * rhs, y: lhs.y * rhs)
  }
  static func / (lhs: Self, rhs: CGFloat) -> Self {
    Self.init(x: lhs.x / rhs, y: lhs.y / rhs)
  }
  var length: CGFloat {
    sqrt(pow(self.x, 2) + pow(self.y, 2))
  }
}

struct SquirrelInputPositionTracker {
  struct Anchor: Equatable {
    let attr0: NSRect
    let windowID: CGWindowID
    let quartzTopLeft: CGPoint
    let bundleID: String
  }

  private(set) var anchor: Anchor?

  mutating func reset() {
    anchor = nil
  }

  mutating func resolve(
    rawAttr0: NSRect,
    bundleID: String,
    hasActiveComposition: Bool,
    findWindowAtAttr0: () -> (windowID: CGWindowID, quartzTopLeft: CGPoint)?,
    lookupWindowTopLeft: (CGWindowID) -> CGPoint?
  ) -> NSRect {
    guard hasActiveComposition,
          !rawAttr0.isNull, !rawAttr0.isInfinite,
          rawAttr0.origin.x.isFinite, rawAttr0.origin.y.isFinite,
          rawAttr0 != .zero else {
      anchor = nil
      return rawAttr0
    }

    if let existing = anchor, existing.bundleID == bundleID, existing.attr0 == rawAttr0 {
      if let currentTopLeft = lookupWindowTopLeft(existing.windowID) {
        let dx = currentTopLeft.x - existing.quartzTopLeft.x
        let dy = -(currentTopLeft.y - existing.quartzTopLeft.y)
        if dx.isFinite, dy.isFinite, abs(dx) > 0.5 || abs(dy) > 0.5 {
          return rawAttr0.offsetBy(dx: dx, dy: dy)
        }
      }
      return rawAttr0
    }

    if let hostWin = findWindowAtAttr0() {
      anchor = Anchor(
        attr0: rawAttr0,
        windowID: hostWin.windowID,
        quartzTopLeft: hostWin.quartzTopLeft,
        bundleID: bundleID
      )
    } else {
      anchor = nil
    }
    return rawAttr0
  }
}
