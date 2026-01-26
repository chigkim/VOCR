//
//  UIElement Extension.swift
//  FloTools
//
//  Created by Chi Kim on 2/3/19.
//  Copyright © 2019 Chi Kim. All rights reserved.
//

import AXSwift
import Cocoa
import Foundation

extension Array where Element == UIElement {
    func filter(role: Role) -> [UIElement] {
        return filter { try! $0.role()! == role }
    }

    func filter(title: String) -> [UIElement] {
        return filter {
            if let regex = try? NSRegularExpression(pattern: title, options: .caseInsensitive) {
                let value = $0.title!
                if let result = regex.firstMatch(
                    in: value, range: NSRange(value.startIndex..., in: value))
                {
                    return true
                }
            }
            return false
        }
    }

}

extension UIElement {

    var children: [UIElement] {
        guard let AXElements: [AXUIElement] = try! attribute(.children) else {
            return []
        }
        let elements = AXElements.map { UIElement($0) }
        return elements
    }

    var title: String? {
        if let value: String = try! attribute(.title) {
            return value
        }
        return nil
    }

    var elementDescription: String? {
        if let value: String = try! attribute(.description) {
            return value
        }
        return nil
    }

    var valueDescription: String? {
        if let value: String = try! attribute(.valueDescription) {
            return value
        }
        return nil
    }

    var value: String? {
        if let value: Any = try! attribute(.value) {

            return String(describing: value)

        }
        return nil
    }

    var label: String? {
        var roleName = "Unknown: "
        if let roleStr = try! role()?.rawValue {
            let start = roleStr.index(roleStr.startIndex, offsetBy: 2)
            roleName = roleStr[start...] + ": "
        }
        var name = ""
        if title != nil {
            name = title!
        } else if elementDescription != nil {
            name = elementDescription!
        } else if valueDescription != nil {
            name = valueDescription!
        } else if value != nil {
            name = String(describing: value)
        }
        return name + " " + roleName
    }

    var parent: UIElement? {
        if let parent: UIElement = try! attribute(.parent) {
            return parent
        }
        return nil
    }
}
