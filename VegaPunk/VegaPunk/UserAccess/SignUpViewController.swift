//
//  UserAccessControlViewController.swift
//  MyMapKit
//
//  Created by Vũ Quý Đạt  on 17/12/2020.
//

import UIKit

enum CellCategory: Int {
    case imagePicker, text, username, password, confirmPassword, gender, datePicker, number
}

class SignUpViewController: UIViewController, UIScrollViewDelegate {
    
    
    // MARK: - IBOutlets.
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottomCS: NSLayoutConstraint!
    
    
    // MARK: - Variables.
    let notificationCenter = NotificationCenter.default
    
    var keyboardHeight: CGFloat = 0.0
    var inputDataKeyValue: [String: String] = [:]
    var birthString = ""
    
        
    // MARK: - Table view data.
    let sectionHeaders = ["Create your account"]
    let rowLabels = [
        "Name", "Username", "Password", "Confirm password",
        "Gender", "Phone", "Email", "Birth", "Bio", "Country"
    ]
    let placeHolders = [
        "Required", "Required", "Required", "Required",
        "Optional", "Optional", "Optional", "dd/mm/yyyy", "Optional", "Optional"
    ]
    let inputTypes: [CellCategory] = [
        .text, .username, .password, .confirmPassword,
        .gender, .text, .text, .datePicker, .text, .text
    ]
    var inputData: [String?] = [
        nil, nil, nil, nil,
        nil, nil, nil, nil, nil, nil
    ]
    let fieldKeys = [
        "name", "username", "password", "confirmPassword",
        "gender", "phone", "email", "birth", "bio", "country"
    ]
    
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        configureHierarchy()
        prepareNavigation()
        prepareObserver()
    }
    
    
    // MARK: - Tasks
    ///  Configure `tableView` hierarchy
    private func configureHierarchy() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: TextInputCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: TextInputCell.reuseIdentifier)
        tableView.register(UINib(nibName: SignupDatePickerInputTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: SignupDatePickerInputTableViewCell.reuseIdentifier)
    }
    
    
    // MARK: - Mini tasks
    func validateInput() -> Bool {
        if let inputData = inputData[inputTypes[.password]], inputData.count < 8 {
            AlertNotification.notify(message: "Your password to short!", on: self)
            return false
        }
        if (inputData[inputTypes[.password]] !=
            inputData[inputTypes[.confirmPassword]]) {
            AlertNotification.notify(message: "Confirm password not match!", on: self)
            return false
        }
        for (index, value) in inputData.enumerated() {
            if index < 3 && (value == nil || value == "") {
                AlertNotification.notify(message: "Please fill in required field!", on: self)
                return false
            }
        }
        return true
    }
    func fillDataToSubmitForm() {
        for (index, value) in inputData.enumerated() {
            if index == inputTypes[.confirmPassword] ||
                index == inputTypes[.gender] {
                continue
            }
            if (value != nil && value != "") {
                inputDataKeyValue[fieldKeys[index]] = value
            }
        }
    }
    func prepareObserver() {
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
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
    func prepareNavigation() {
        title = "Regist Account"
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.sizeToFit()
        setUpNavigationBar()
    }
    func setUpNavigationBar() {
        navigationItem.title = "Regist Account"
        navigationItem.largeTitleDisplayMode = .always
        // BarButtonItem.
        let rightBarItem: UIBarButtonItem = {
            let bt = UIBarButtonItem(title: "Regist", style: .plain, target: self, action: #selector(rightBarItemAction))
            return bt
        }()
        navigationItem.rightBarButtonItem = rightBarItem
    }
    @objc func rightBarItemAction() {
        self.view.endEditing(true)
        if validateInput() {
            fillDataToSubmitForm()
            do {
                var user = try inputDataKeyValue.convert(to: User.self)
                if let gender = inputData[inputTypes[.gender]] {
                    user.gender = Gender(rawValue: Int(gender)!)
                }
                signUp(user)
            } catch {
                AlertNotification.notify(message: "Some thing wrong when sign up!", on: self)
            }
        }
    }
}


// MARK: - Table view
extension SignUpViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionHeaders[section]
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 240
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowLabels.count
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}
extension SignUpViewController: UITableViewDelegate {
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
            cell.inputTextField.isEnabled = false
            if let genderString = inputData[row], /// genderString is number represent in String
               let genderRaw = Int(genderString),
               let gender = Gender(rawValue: genderRaw)
            {
                cell.inputTextField.text = gender.description
            }
            break
        default:
            break
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        prepareGenderPickerView(for: indexPath)
    }
    
    func prepareGenderPickerView(for indexPath: IndexPath) {
        let row = indexPath.row
        if row == inputTypes.firstIndex(of: .gender) {
            let alert = UIAlertController(title: "Pick your gender", message: "", preferredStyle: .actionSheet)
            Gender.allCases.forEach { gender in
                let action = UIAlertAction(title: gender.description.Capitalized, style: .default) { _ in
                    self.reloadGender(indexPath, value: gender.rawValue)
                }
                alert.addAction(action)
            }
            self.present(alert, animated: true, completion: nil)
        }
    }
    func reloadGender(_ indexPath: IndexPath, value: Int) {
        let row = indexPath.row
        inputData[row] = value.description
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
}


// MARK: Text field Delegate.
extension SignUpViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        tableView.setContentOffset(CGPoint(x: 0, y: 100), animated: true)
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var text = textField.text ?? ""
        
        if (textField.tag == inputTypes.firstIndex(of: .username) ||
            textField.tag == inputTypes.firstIndex(of: .password) ||
            textField.tag == inputTypes.firstIndex(of: .confirmPassword)) &&
            string.contains(" ") { return false }
        
        if textField.tag == inputTypes.firstIndex(of: .datePicker) {
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
