//
//  RYFloatingInput.swift
//  RYFloatingInput-Swift
//
//  Created by Ray on 25/08/2017.
//  Copyright © 2017 ycray.net. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

public extension RYFloatingInput {

    public func setup(setting: RYFloatingInputSetting) {

        self.setting = setting

        self.backgroundColor = setting.backgroundColor
        self.icon.image = setting.iconImage
        self.input.textColor = setting.textColor
        self.input.tintColor = setting.cursorColor
        self.dividerHeight.constant = setting.dividerHeight
        self.input.placeholder = setting.placeholder
        self.input.isSecureTextEntry = setting.isSecure ?? false
        self.input.attributedPlaceholder = NSAttributedString(string: setting.placeholder ?? "",
                                                              attributes: [NSAttributedString.Key.foregroundColor: setting.placeholderColor])
        self.divider.backgroundColor = setting.dividerColor
        self.warningLbl.textColor = setting.accentColor

        if setting.iconImage != nil {
            inputLeadingMargin.constant = 48
        }
        self.rx()
    }

    public func text() -> String? {
        return self.input.text
    }
  
    public func setText(_ text: String?) {
      self.input.text = text
    }

    public func setEnabled(_ flag: Bool? = true) {
        self.input.isUserInteractionEnabled = flag!
    }

    public override func resignFirstResponder() -> Bool {
        return input.resignFirstResponder()
    }
  
    public func setFocus() {
        self.input.becomeFirstResponder()
    }
  
    public func showErrorMessage() {
        self.input.becomeFirstResponder()
        self.input.resignFirstResponder()
        self.input.becomeFirstResponder()
    }
  
    public func textField() -> UITextField {
        return self.input
    }
}

public class RYFloatingInput: UIView {

    public typealias InputViolation = (message: String, callback: (() -> Void)?)

    @IBOutlet fileprivate weak var icon: UIImageView!
    @IBOutlet fileprivate weak var floatingHint: UILabel!
    @IBOutlet fileprivate weak var input: UITextField!
    @IBOutlet fileprivate weak var divider: UIView!
    @IBOutlet fileprivate weak var dividerHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var warningLbl: UILabel!
    @IBOutlet fileprivate weak var inputLeadingMargin: NSLayoutConstraint!

    fileprivate var setting: RYFloatingInputSetting?
    fileprivate let disposeBag = DisposeBag()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    private func setupView() {
        let view = viewFromNib()
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
    }
    
    private func viewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
        return view
    }
    
    fileprivate func rx() {
      
      let vm = RYFloatingInputViewModel(input: self.input.rx.text.orEmpty.asDriver(),
                                        dependency: (minLength: self.setting?.minLength,
                                                     maxLength: self.setting?.maxLength,
                                                     inputType: self.setting?.inputType,
                                                     canEmpty: self.setting?.canEmpty))
      
      input.rx.controlEvent([.editingDidEnd])
        .subscribe(onNext: { _ in
          self.divider.backgroundColor = self.setting?.dividerColor
          self.floatingHint.textColor = self.setting?.dividerColor
          if !self.input.isFirstResponder {
            
            vm.inputViolatedDrv
              .map({ (status) -> (status: ViolationStatus, violation: InputViolation?)in
                switch status {
                case .valid:                return (status, nil)
                case .inputTypeViolated:    return (status, self.setting?.inputTypeViolation)
                case .maxLengthViolated:    return (status, self.setting?.maxLengthViolation)
                case .emptyViolated:        return (status, self.setting?.emptyViolation)
                case .minLengthViolated:    return (status, self.setting?.minLengthViolation)
                }
              })
              .drive(self.rx.status)
              .disposed(by: self.disposeBag)
            
            vm.hintVisibleDrv
              .drive(self.rx.hintVisible)
              .disposed(by: self.disposeBag)
          }
        })
        .disposed(by: disposeBag)
      
      input.rx.controlEvent([.editingDidBegin])
        .subscribe(onNext: { _ in
          self.divider.backgroundColor = self.setting?.accentColor
          self.floatingHint.textColor = self.setting?.accentColor
          if !self.input.isFirstResponder {
            
            vm.inputViolatedDrv
              .map({ (status) -> (status: ViolationStatus, violation: InputViolation?)in
                switch status {
                case .valid:                return (status, nil)
                case .inputTypeViolated:    return (status, self.setting?.inputTypeViolation)
                case .maxLengthViolated:    return (status, self.setting?.maxLengthViolation)
                case .emptyViolated:        return (status, self.setting?.emptyViolation)
                case .minLengthViolated:    return (status, self.setting?.minLengthViolation)
                }
              })
              .drive(self.rx.status)
              .disposed(by: self.disposeBag)
            
            vm.hintVisibleDrv
              .drive(self.rx.hintVisible)
              .disposed(by: self.disposeBag)
          }
        })
        .disposed(by: disposeBag)
      
      input.rx.controlEvent([.editingChanged])
        .subscribe(onNext: { (_) in
          vm.hintVisibleDrv
            .drive(self.rx.hintVisible)
            .disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
  
    override public func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
      if !(setting?.enableAction ?? false) {
        UIMenuController.shared.isMenuVisible = false
        self.resignFirstResponder()
        return false
      } else {
        return super.canPerformAction(action, withSender: sender)
      }
    }
}

private extension Reactive where Base: RYFloatingInput {

    var status: Binder<(status: RYFloatingInput.ViolationStatus, violation: RYFloatingInput.InputViolation?)> {

        return Binder(base, binding: { (floatingInput, pair) in

            guard let violation = pair.violation else {
                floatingInput.floatingHint.textColor = floatingInput.setting?.accentColor
                floatingInput.warningLbl.text = nil
                if floatingInput.input.isFirstResponder {
                    floatingInput.divider.backgroundColor = floatingInput.setting?.accentColor
                }
                return
            }
            floatingInput.floatingHint.textColor = floatingInput.setting?.warningColor
            if (floatingInput.input.isFirstResponder) {
                floatingInput.divider.backgroundColor = floatingInput.setting?.warningColor
            }
            floatingInput.warningLbl.text = violation.message
            floatingInput.warningLbl.textColor = floatingInput.setting?.warningColor
            if let callback = violation.callback {
                callback()
            }
        })
    }

    var hintVisible: Binder<RYFloatingInput.HintVisibility> {

        return Binder(base, binding: { (floatingInput, visibility) in

            UIView.animate(withDuration: 0.3,  delay: 0.0, options: .curveEaseInOut, animations: {
                floatingInput.floatingHint.isHidden = (visibility != .visible)
                floatingInput.floatingHint.alpha = (visibility == .visible) ? 1.0 : 0.0
                floatingInput.floatingHint.text = (visibility == .visible) ? floatingInput.setting?.placeholder : nil
            })
        })
    }
}
