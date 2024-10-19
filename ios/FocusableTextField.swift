//
//  FocusableTextField.swift
//  KrowdKinect
//
//  Created by Jason Groenjes on 10/5/24.
//

import SwiftUI
import UIKit

struct FocusableTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFirstResponder: Bool

    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    var onClear: (() -> Void)? = nil
    var onDone: (() -> Void)? = nil
    var textColor: UIColor = .black
    var font: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: FocusableTextField

        init(_ parent: FocusableTextField) {
            self.parent = parent
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                if !self.parent.isFirstResponder {
                    self.parent.isFirstResponder = true
                }
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                let newText = textField.text ?? ""
                // Only update the binding if the text has changed
                if self.parent.text != newText {
                    self.parent.text = newText
                }
                if self.parent.isFirstResponder {
                    self.parent.isFirstResponder = false
                }
            }
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            DispatchQueue.main.async {
                let newText = textField.text ?? ""
                // Only update the binding if the text has changed
                if self.parent.text != newText {
                    self.parent.text = newText
                }
            }
        }

        @objc func clearTapped() {
            DispatchQueue.main.async {
                self.parent.onClear?()
            }
        }

        @objc func doneTapped() {
            DispatchQueue.main.async {
                self.parent.onDone?()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.keyboardType = keyboardType
        textField.returnKeyType = .done
        textField.textColor = textColor
        textField.font = font

        // Create toolbar
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        // Create buttons
        let clearButton = UIBarButtonItem(title: "Clear All", style: .plain, target: context.coordinator, action: #selector(context.coordinator.clearTapped))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: context.coordinator, action: #selector(context.coordinator.doneTapped))

        toolbar.setItems([clearButton, spacer, doneButton], animated: false)
        textField.inputAccessoryView = toolbar

        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        // Only update the text if it's different from the current value
        if uiView.text != text {
            uiView.text = text
        }
        // Update textColor if it has changed
        if uiView.textColor != textColor {
            uiView.textColor = textColor
        }

        // Manage first responder status safely
        if isFirstResponder && !uiView.isFirstResponder {
            DispatchQueue.main.async {
                       uiView.becomeFirstResponder()
                   }
        } else if !isFirstResponder && uiView.isFirstResponder {
            DispatchQueue.main.async {
                uiView.resignFirstResponder()
            }
        }
    }
}
