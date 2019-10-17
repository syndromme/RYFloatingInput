//
//  RYFloatingInputViewModel.swift
//  RYFloatingInput-Swift
//
//  Created by Ray on 11/09/2017.
//  Copyright © 2017 ycray.net. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

internal class RYFloatingInputViewModel {
    
    internal let inputViolatedDrv: Driver<RYFloatingInput.ViolationStatus>
    internal let hintVisibleDrv: Driver<RYFloatingInput.HintVisibility>

      internal init(input: Driver<String>, dependency: (minLength: Int?, maxLength: Int?, inputType: RYFloatingInput.InputType?, canEmpty: Bool?)) {
     
        inputViolatedDrv = input
            .map({ (content) -> RYFloatingInput.ViolationStatus in

//                guard (content.count == 0 && !(dependency.canEmpty!) || (content.count > 0 && (dependency.canEmpty!))) else {
//                  return .valid
//                }
              
                if content.count == 0 && !(dependency.canEmpty!) {
                  return .emptyViolated
                }
              
                guard let minL = dependency.minLength, content.count >= minL else {
                  return .minLengthViolated
                }
              
                guard let rp = dependency.inputType?.pattern, !RYFloatingInputViewModel.regex(pattern: rp, input: content) else {
                    return .inputTypeViolated
                }
                guard let ml = dependency.maxLength, content.count < ml else {
                    return .maxLengthViolated
                }
                return .valid
            })

        hintVisibleDrv = input
            .map({ (content) -> RYFloatingInput.HintVisibility in
                return (content.count > 0) ? .visible : ((dependency.canEmpty ?? true) ? .visible : .hidden)//(content.count > 0) ? .visible : .hidden
            })
            .distinctUntilChanged()
    }
}

private extension RYFloatingInputViewModel {

    static func regex(pattern: String, input: String) -> Bool {

        do {
            let regexNumbersOnly = try NSRegularExpression(pattern: pattern, options: [])
            return regexNumbersOnly.firstMatch(in: input, options: [], range: NSMakeRange(0, input.count)) == nil

        } catch let error as NSError {
            print(error.description)
        }
        return true
    }
}
