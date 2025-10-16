//
//  ExpandableHeaderView.swift
//  dataWallet
//
//  Created by iGrant on 29/05/25.
//

import Foundation
import UIKit

class ExpandableHeaderView: UIView {
    var section: Int = 0
    var toggleAction: ((Int) -> Void)?
    var checkboxAction: ((Int, Bool) -> Void)?
    var optionCheckboxAction: ((Int, Bool) -> Void)?
    
    let label = UILabel()
    let optionContainerView = UIView() // Container view for option elements
    let optionLabel = UILabel()
    let checkbox = UIButton(type: .system)
    let optionCheckbox = UIButton(type: .system)
    let mainContentView = UIView()
    
    var isMandatory: Bool = false
    var isOptionSelected: Bool = false
    var isMultipleOptions: Bool = false
    var isChecked: Bool = false {
        didSet {
            updateCheckboxImage(isMandatory: isMandatory)
        }
    }
    
    private var showCheckbox: Bool = false
    private var showOptionLabel: Bool = false

    init(title: String, section: Int, isExpanded: Bool, leadingConstant: CGFloat, isChecked: Bool, isOptionSelected: Bool, showCheckbox: Bool, isMandatory: Bool, showOptionLabel: Bool, isMultipleOptions: Bool, toggleAction: @escaping (Int) -> Void,
         checkboxAction: @escaping (Int, Bool) -> Void,
         optionCheckboxAction: @escaping (Int, Bool) -> Void) {
        self.isChecked = isChecked
        self.isOptionSelected = isOptionSelected
        super.init(frame: .zero)
        self.section = section
        self.showCheckbox = showCheckbox
        self.isMultipleOptions = isMultipleOptions
        self.showOptionLabel = showOptionLabel
        self.toggleAction = toggleAction
        self.isMandatory = isMandatory
        self.checkboxAction = checkboxAction
        self.optionCheckboxAction = optionCheckboxAction
        setupUI(title: title, isExpanded: isExpanded, leadingConstant: leadingConstant)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupTitle(title: String) {
        label.text = title
    }
    
    private func updateCheckboxImage(isMandatory: Bool) {
        if (isChecked || isMandatory || isMultipleOptions ) {
            if isMandatory || isMultipleOptions {
                checkbox.isUserInteractionEnabled = false
                checkbox.tintColor = .systemGray
            } else {
                checkbox.isUserInteractionEnabled = true
                checkbox.tintColor = .darkGray
            }
            let newIcon = "checkmark.square.fill"
            checkbox.setImage(UIImage(systemName: newIcon), for: .normal)
        } else {
            checkbox.tintColor = isMandatory ? .systemGray : .darkGray
            let newIcon = "square"
            checkbox.setImage(UIImage(systemName: newIcon), for: .normal)
        }
    }
    
    private func updateOptionCheckboxImage() {
        let newIcon = isOptionSelected ? "radio_button_checked" : "radio_button_unchecked"
        optionCheckbox.setImage(UIImage(named: newIcon), for: .normal)
        optionCheckbox.tintColor = .black
    }

    private func setupUI(title: String, isExpanded: Bool, leadingConstant: CGFloat) {
        backgroundColor = .clear
        
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.layer.cornerRadius = 8
        contentView.backgroundColor = .clear
        addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        contentView.backgroundColor = .clear

        // Main Label
        label.text = title
        label.textColor = .systemGray
        label.font = UIFont.systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        optionContainerView.translatesAutoresizingMaskIntoConstraints = false
        optionContainerView.backgroundColor = .clear
        optionContainerView.isHidden = !showOptionLabel
        
        optionLabel.textColor = .systemGray
        optionLabel.font = UIFont.systemFont(ofSize: 16)
        optionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        optionCheckbox.translatesAutoresizingMaskIntoConstraints = false
        optionCheckbox.addTarget(self, action: #selector(toggleOptionCheckbox), for: .touchUpInside)
        updateOptionCheckboxImage()
        
        let optionTapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleOptionCheckbox))
        optionLabel.isUserInteractionEnabled = true
        optionLabel.addGestureRecognizer(optionTapGesture)
        
        updateCheckboxImage(isMandatory: isMandatory)
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        checkbox.addTarget(self, action: #selector(toggleCheckbox), for: .touchUpInside)
        
        let chevronButton = UIButton(type: .system)
        let iconName = isExpanded ? "chevron.up" : "chevron.down"
        chevronButton.setImage(UIImage(systemName: iconName), for: .normal)
        chevronButton.tintColor = .systemGray
        chevronButton.translatesAutoresizingMaskIntoConstraints = false
        chevronButton.addTarget(self, action: #selector(toggleSection), for: .touchUpInside)
        
        mainContentView.translatesAutoresizingMaskIntoConstraints = false
        
        if isExpanded {
            if !showCheckbox {
                mainContentView.backgroundColor =  .clear
            } else {
                mainContentView.layer.cornerRadius = 8
                mainContentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                mainContentView.backgroundColor =  .white
            }
        } else {
            mainContentView.layer.cornerRadius = 8
            mainContentView.backgroundColor =  .white
        }
        
        // Add subviews to contentView (clear background)
        contentView.addSubview(optionContainerView)
        contentView.addSubview(mainContentView)
        
        // Add elements to main content view (white background)
        mainContentView.addSubview(label)
        mainContentView.addSubview(chevronButton)

        // Add option elements to option container view (clear background)
        optionContainerView.addSubview(optionCheckbox)
        optionContainerView.addSubview(optionLabel)

        // Constraints for option container view
        NSLayoutConstraint.activate([
            optionCheckbox.leadingAnchor.constraint(equalTo: optionContainerView.leadingAnchor),
            optionCheckbox.centerYAnchor.constraint(equalTo: optionContainerView.centerYAnchor),
            optionCheckbox.widthAnchor.constraint(equalToConstant: 27),
            optionCheckbox.heightAnchor.constraint(equalToConstant: 27),
            
            optionLabel.leadingAnchor.constraint(equalTo: optionCheckbox.trailingAnchor, constant: 8),
            optionLabel.centerYAnchor.constraint(equalTo: optionCheckbox.centerYAnchor),
            optionLabel.trailingAnchor.constraint(equalTo: optionContainerView.trailingAnchor)
        ])

        // Constraints for main content view
        if showCheckbox {
            mainContentView.addSubview(checkbox)
            
            if showOptionLabel {
                // Layout with option container and main content
                NSLayoutConstraint.activate([
                    // Option Container (clear background)
                    optionContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    optionContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                    optionContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
                    optionContainerView.heightAnchor.constraint(equalToConstant: 30),
                    
                    // Main Content View (white background)
                    mainContentView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    mainContentView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                    mainContentView.topAnchor.constraint(equalTo: optionContainerView.bottomAnchor, constant: 4),
                    mainContentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                    mainContentView.heightAnchor.constraint(equalToConstant: 44),
                    
                    // Item Checkbox
                    checkbox.leadingAnchor.constraint(equalTo: mainContentView.leadingAnchor, constant: 8),
                    checkbox.centerYAnchor.constraint(equalTo: mainContentView.centerYAnchor),
                    checkbox.widthAnchor.constraint(equalToConstant: 20),
                    checkbox.heightAnchor.constraint(equalToConstant: 20),
                    
                    // Main Label
                    label.leadingAnchor.constraint(equalTo: checkbox.trailingAnchor, constant: 10),
                    label.centerYAnchor.constraint(equalTo: mainContentView.centerYAnchor),
                    label.trailingAnchor.constraint(lessThanOrEqualTo: chevronButton.leadingAnchor, constant: -10),
                    
                    // Chevron
                    chevronButton.trailingAnchor.constraint(equalTo: mainContentView.trailingAnchor, constant: -10),
                    chevronButton.centerYAnchor.constraint(equalTo: mainContentView.centerYAnchor),
                    chevronButton.widthAnchor.constraint(equalToConstant: 20),
                    chevronButton.heightAnchor.constraint(equalToConstant: 20)
                ])
            } else {
                // Layout without option label (regular item)
                NSLayoutConstraint.activate([
                    // Main Content View (white background) - fills entire contentView
                    mainContentView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    mainContentView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                    mainContentView.topAnchor.constraint(equalTo: contentView.topAnchor),
                    mainContentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                    
                    // Item Checkbox
                    checkbox.leadingAnchor.constraint(equalTo: mainContentView.leadingAnchor, constant: 8),
                    checkbox.centerYAnchor.constraint(equalTo: mainContentView.centerYAnchor),
                    checkbox.widthAnchor.constraint(equalToConstant: 20),
                    checkbox.heightAnchor.constraint(equalToConstant: 20),
                    
                    // Main Label
                    label.leadingAnchor.constraint(equalTo: checkbox.trailingAnchor, constant: 10),
                    label.centerYAnchor.constraint(equalTo: mainContentView.centerYAnchor),
                    label.trailingAnchor.constraint(lessThanOrEqualTo: chevronButton.leadingAnchor, constant: -10),
                    
                    // Chevron
                    chevronButton.trailingAnchor.constraint(equalTo: mainContentView.trailingAnchor, constant: -10),
                    chevronButton.centerYAnchor.constraint(equalTo: mainContentView.centerYAnchor),
                    chevronButton.widthAnchor.constraint(equalToConstant: 20),
                    chevronButton.heightAnchor.constraint(equalToConstant: 20)
                ])
            }
        } else {
            // Layout without any checkboxes
            NSLayoutConstraint.activate([
                // Main Content View (white background) - fills entire contentView
                mainContentView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                mainContentView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                mainContentView.topAnchor.constraint(equalTo: contentView.topAnchor),
                mainContentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                
                label.leadingAnchor.constraint(equalTo: mainContentView.leadingAnchor, constant: leadingConstant),
                label.centerYAnchor.constraint(equalTo: mainContentView.centerYAnchor),
                label.trailingAnchor.constraint(equalTo: chevronButton.leadingAnchor, constant: -10),

                chevronButton.trailingAnchor.constraint(equalTo: mainContentView.trailingAnchor, constant: -10),
                chevronButton.centerYAnchor.constraint(equalTo: mainContentView.centerYAnchor),
                chevronButton.widthAnchor.constraint(equalToConstant: 20),
                chevronButton.heightAnchor.constraint(equalToConstant: 20)
            ])
        }
    }
    
    func setOptionText(_ text: String) {
        optionLabel.text = text.uppercased()
    }
    
    func setCheckboxState(_ checked: Bool, isMandatorySingle: Bool) {
        guard showCheckbox else { return }
        isChecked = checked
        isMandatory = isMandatorySingle
        updateCheckboxImage(isMandatory: isMandatory)
    }
    
    func setOptionCheckboxState(_ selected: Bool) {
        isOptionSelected = selected
        updateOptionCheckboxImage()
    }

    @objc private func toggleSection() {
        toggleAction?(section)
    }

    @objc private func toggleCheckbox() {
        guard showCheckbox else { return }
        if isMandatory {
            isChecked = true
        } else {
            isChecked = !isChecked
        }
        checkboxAction?(section, isChecked)
    }
    
    @objc private func toggleOptionCheckbox() {
        guard showOptionLabel else { return }
        isOptionSelected = !isOptionSelected
        updateOptionCheckboxImage()
        optionCheckboxAction?(section, isOptionSelected)
    }
}
