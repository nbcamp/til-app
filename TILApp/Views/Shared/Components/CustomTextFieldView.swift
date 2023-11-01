//
//  CustomTextFieldView.swift
//  TILApp
//
//  Created by 이재희 on 10/27/23.
//
import UIKit

class CustomTextFieldView: UIView {
    var titleText: String {
        get { titleLabel.text ?? "" }
        set { titleLabel.text = newValue }
    }

    var placeholder: String {
        get { textField.placeholder ?? "" }
        set { textField.placeholder = newValue }
    }

    var mainText: String {
        get { textField.text ?? "" }
        set { textField.text = newValue }
    }

    var delegate: UITextFieldDelegate? {
        get { textField.delegate }
        set { textField.delegate = newValue }
    }
    
    var keyboardType: UIKeyboardType {
        get { textField.keyboardType }
        set { textField.keyboardType = newValue }
    }

    var readOnly: Bool = false {
        didSet {
            textField.isUserInteractionEnabled = !readOnly
            textField.textColor = readOnly ? .systemGray2 : .black
        }
    }

    var textFieldTag: Int = 0 {
        didSet {
            textField.tag = textFieldTag
        }
    }

    var componentSize: CGSize {
        return CGSize(width: frame.width, height: height)
    }

    private let titleLabel = CustomTitleLabel()
    private let textField = CustomTextField()
    private let height: CGFloat = 64

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupView()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        // backgroundColor = .systemBackground

        flex.define {
            $0.addItem(titleLabel).margin(0, 20).height(24)
            $0.addItem(textField).margin(0, 20).height(40)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        pin.width(100%).height(height)
        flex.layout()
    }
}
