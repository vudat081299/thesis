//
//  UserAccessControlViewController.swift
//  MyMapKit
//
//  Created by Vũ Quý Đạt  on 17/12/2020.
//

import UIKit

enum Gender: Int, CaseIterable, Codable {
    case male, female, other
    static var listRawValue: [String] {
        var list = [String]()
        for item in self.allCases {
            list.append("\(item.rawValue)")
        }
        return list
    }
    var description: String {
        switch self {
        case .male:
            return "male"
        case .female:
            return "female"
        case .other:
            return "other"
        }
    }
}
enum InputType: Int {
    case text, username, password, confirmPassword, gender, datePicker
}

protocol PassInputDataFromCell {
    func pass(_ string: String, at field: IndexPath)
}

class SignUpViewController: UIViewController, UIScrollViewDelegate {
    
    
    // MARK: - IBOutlet.
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottomCS: NSLayoutConstraint!
    
    
    // MARK: - Variables.
    var keyboardHeight: CGFloat = 0.0
    var inputDataKeyValue: [String: String] = [:]
    var birthString = ""
    
    let notificationCenter = NotificationCenter.default
    
        
    // MARK: - Data tableView.
    let sectionHeaders = ["Create your account"]
    let rowLabels = [
        "Name", "Username", "Password", "Confirm password",
        "Gender", "Phone", "Email", "Birth", "Bio", "Country"
    ]
    let placeHolders = [
        "Required", "Required", "Required", "Required",
        "Optional", "Optional", "Optional", "dd/mm/yyyy", "Optional", "Optional"
    ]
    let inputTypes: [InputType] = [
        .text, .username, .password, .confirmPassword,
        .gender, .text, .text, .datePicker, .text, .text
    ]
    var inputData = [
        "", "", "", "",
        "", "", "", "", "", ""
    ]
    let fieldKey = [
        "name", "username", "password", "confirmPassword",
        "gender", "phone", "email", "birth", "bio", "country"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sign up"
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.sizeToFit()
        navigationItem.largeTitleDisplayMode = .always
        
        // Do any additional setup after loading the view.
        configureHierarchy()
        setUpNavigationBar()
    }
    
    
    // MARK: - Mini tasks
    func validateInput() -> Bool {
        if (inputData[inputTypes.firstIndex(where: { $0 == .password})!].count < 8) {
            AlertNotification.notify(message: "Your password to short!", on: self)
            return false
        }
        if (inputData[inputTypes.firstIndex(where: { $0 == .password})!] !=
            inputData[inputTypes.firstIndex(where: { $0 == .confirmPassword})!]) {
            AlertNotification.notify(message: "Confirm password not match!", on: self)
            return false
        }
        for (index, value) in inputData.enumerated() {
            if index < 4 && value == "" {
                AlertNotification.notify(message: "Please fill in required field!", on: self)
                return false
            }
            if index == inputTypes.firstIndex(where: { $0 == .confirmPassword})! ||
                index == inputTypes.firstIndex(where: { $0 == .gender})!{
                continue
            }
            if (value != "") {
                inputDataKeyValue[fieldKey[index]] = value
            }
        }
        return true
    }
    
}


// MARK: - APIs
extension SignUpViewController {
    func signUp(_ user: User) {
        Auth.signUp(user) {
            SoundFeedBack.success()
            DispatchQueue.main.async {
                self.navigationItem.rightBarButtonItem?.tintColor = .systemGreen
                self.navigationItem.rightBarButtonItem?.image = UIImage(systemName: "checkmark.circle.fill")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.navigationItem.rightBarButtonItem?.tintColor = .link
                self.navigationItem.rightBarButtonItem?.image = nil
                self.navigationItem.rightBarButtonItem?.title = "Regist"
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}


// MARK: - Navigation
extension SignUpViewController {
    @objc func rightBarItemAction() {
        self.view.endEditing(true)
        if validateInput() {
            do {
                var user = try inputDataKeyValue.convert(to: User.self)
                if let gender = inputDataKeyValue["gender"] {
                    user.gender = Gender(rawValue: Int(gender)!)
                }
                signUp(user)
            } catch {
                AlertNotification.notify(message: "Some thing wrong when sign up!", on: self)
            }
        }
    }
    func setUpNavigationBar() {
        navigationItem.title = "Regist Account"
        // BarButtonItem.
        let rightBarItem: UIBarButtonItem = {
            let bt = UIBarButtonItem(title: "Regist", style: .plain, target: self, action: #selector(rightBarItemAction))
            return bt
        }()
        navigationItem.rightBarButtonItem = rightBarItem
    }
}


// MARK: - TableView.
extension SignUpViewController: UITableViewDataSource, UITableViewDelegate {
    private func configureHierarchy() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: TextInputCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: TextInputCell.reuseIdentifier)
        tableView.register(UINib(nibName: SignupPickerInputTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: SignupPickerInputTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: SignupDatePickerInputTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: SignupDatePickerInputTableViewCell.reuseIdentifier)
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionHeaders[section]
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 350
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowLabels.count
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let inputType = inputTypes[row]
        let cell = tableView.dequeueReusableCell(withIdentifier: TextInputCell.reuseIdentifier, for: indexPath) as! TextInputCell
        cell.contentLabel.text = rowLabels[row]
        cell.inputTextField.isEnabled = true
        cell.inputTextField.isSecureTextEntry = false
        cell.inputTextField.delegate = self
        cell.inputTextField.tag = row
        cell.inputTextField.text = inputData[row]
        cell.inputTextField.placeholder = placeHolders[row]
        
        switch inputType {
        case .password, .confirmPassword:
            cell.inputTextField.isSecureTextEntry = true
            break
        case .gender:
            if let gender = Int(inputData[row]) {
                cell.inputTextField.text = Gender(rawValue: gender)?.description
            }
            cell.inputTextField.isEnabled = false
            break
        default:
            break
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = indexPath.row
        if row == inputTypes.firstIndex(where: { $0 == .gender}) {
            let alert = UIAlertController(title: "Pick your gender", message: "", preferredStyle: .actionSheet)
            let maleAction = UIAlertAction(title: "Male", style: .default) { _ in
                self.reloadGenderRow(indexPath, value: "0")
                
            }
            let femaleAction = UIAlertAction(title: "Female", style: .default) { _ in
                self.reloadGenderRow(indexPath, value: "1")
                
            }
            let otherAction = UIAlertAction(title: "Other", style: .default) { _ in
                self.reloadGenderRow(indexPath, value: "2")
            }
            alert.addAction(maleAction)
            alert.addAction(femaleAction)
            alert.addAction(otherAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    func reloadGenderRow(_ indexPath: IndexPath, value: String) {
        let row = indexPath.row
        inputData[row] = value
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
}


//MARK: Keyboard.
extension SignUpViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        tableView.setContentOffset(CGPoint(x: 0, y: 100), animated: true)
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var text = textField.text ?? ""
        
        if (textField.tag == inputTypes.firstIndex(where: { $0 == .username}) ||
            textField.tag == inputTypes.firstIndex(where: { $0 == .password}) ||
            textField.tag == inputTypes.firstIndex(where: { $0 == .confirmPassword})) &&
            string.contains(" ")
            {
            return false
        }
        
        if textField.tag == inputTypes.firstIndex(where: { $0 == .datePicker}) {
//            let birthPureString = (textField.text ?? "").replacingOccurrences(of: "/", with: "")
//            guard let _ = Int(string) else { return false }
//            if birthPureString.count == 8 { return false }
//            var firstIndex = text.index(text.startIndex, offsetBy: 2)
//            var secondIndex = text.index(text.startIndex, offsetBy: 5)
//            if text.count > 2 {
//                text.insert(Character("/"), at: firstIndex)
//            } else if text.count > 5 {
//                text.insert(Character("/"), at: secondIndex)
//            }
//            let placeHolder = ""
            if string.count == 0 {
                return true
            } else if text.count == 10 {
                return false
            } else {
                guard let _ = Int(string) else { return false }
                if text.count == 2 || text.count == 5 {
                    text += "/"
                }
                textField.text = text
            }
        } else {
            text += string
            inputData[textField.tag] = text
        }
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        inputData[textField.tag] = textField.text ?? ""
    }
    @objc func keyboardWillShow(_ notification: NSNotification) {
        if let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardHeight = keyboardRect.height
            self.tableViewBottomCS.constant = keyboardHeight
            self.view.layoutIfNeeded()
        }
    }
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardHeight = keyboardRect.height
            self.tableViewBottomCS.constant = 0
            self.view.layoutIfNeeded()
        }
    }
}
