//
//  UserProfileViewController.swift
//  VegaPunk
//
//  Created by Dat Vu on 20/02/2023.
//

import UIKit

class UserProfileViewController: UIViewController, UIScrollViewDelegate {
    
    
    // MARK: - IBOutlet.
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottomCS: NSLayoutConstraint!
    var pickedImage: UIImage!
    
    
    // MARK: - Variables.
    let notificationCenter = NotificationCenter.default
    var user: User!
    let imagePicker = UIImagePickerController()
    
    var keyboardHeight: CGFloat = 0.0
    var inputDataKeyValue: [String: String] = [:]
    var birthString = ""
    
    
    // MARK: - Table view data.
    let sectionHeaders = ["Update your profile"]
    let rowLabels = [
        "Avatar", "Name",
        "Gender", "Phone", "Email", "Birth", "Bio", "Country"
    ]
    let placeHolders = [
        "Optional", "Optional",
        "Optional", "Optional", "Optional", "dd/mm/yyyy", "Optional", "Optional"
    ]
    let inputTypes: [CellCategory] = [
        .imagePicker, .text,
        .gender, .text, .text, .datePicker, .text, .text
    ]
    var inputData: [String?] = [
        nil, nil,
        nil, nil, nil, nil, nil, nil
    ]
    let fieldKeys = [
        "avatar", "name",
        "gender", "phone", "email", "birth", "bio", "country"
    ]
    
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        // Delegate
        imagePicker.delegate = self
        
        // Prepare
        prepareData()
        configureHierarchy()
        setUpNavigationBar()
        prepareObserver()
    }
    
    
    // MARK: - Tasks
    ///  Configure `tableView` hierarchy
    private func configureHierarchy() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: TextInputCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: TextInputCell.reuseIdentifier)
        tableView.register(UINib(nibName: SignupDatePickerInputTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: SignupDatePickerInputTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: ProfileAvatarTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: ProfileAvatarTableViewCell.reuseIdentifier)
    }
    
    
    // MARK: - Mini tasks
    func validateInput() -> Bool {
        let requiredIndex = [1, 3, 4]
        for (index, value) in inputData.enumerated() {
            if requiredIndex.contains(index) && (value == nil || value == "") {
                AlertNotification.notify(message: "Please fill in required field!", on: self)
                return false
            }
            fillDataToSubmitForm()
        }
        return true
    }
    func fillDataToSubmitForm() {
        for (index, value) in inputData.enumerated() {
            if index == inputTypes[.gender] ||
                index == inputTypes[.imagePicker] {
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
    func prepareData() {
        user = AuthenticatedUser.retrieve()?.data
        var userClone = user
        userClone?.gender = nil
        userClone?.token = nil
        do {
            if let userCloneDictionary = try userClone?.toDictionary() {
                for (index, field) in fieldKeys.enumerated() {
                    inputData[index] = userCloneDictionary[field]
                }
            }
        } catch {
            inputData[0] = user.avatar
            inputData[1] = user.name
            inputData[2] = user.gender?.description
            inputData[3] = user.phone
            inputData[4] = user.email
            inputData[5] = user.birth
            inputData[6] = user.bio
            inputData[7] = user.country
        }
    }
}


// MARK: - APIs
extension UserProfileViewController {
    func update(_ user: User) {
        var user = user
        if let image = pickedImage {
            RequestEngine.upload(image.pngData()!) { [self] fileId in
                pickedImage = nil
                user.avatar = fileId
                RequestEngine.updateUser(user) {
                    updatedSuccess()
                }
            }
        } else {
            RequestEngine.updateUser(user) {
                updatedSuccess()
            }
        }
        
        func updatedSuccess() {
            SoundFeedBack.success()
            DispatchQueue.main.async {
                self.navigationItem.rightBarButtonItem?.tintColor = .systemGreen
                self.navigationItem.rightBarButtonItem?.image = UIImage(systemName: "checkmark.circle.fill")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.navigationItem.rightBarButtonItem?.tintColor = .link
                self.navigationItem.rightBarButtonItem?.image = nil
                self.navigationItem.rightBarButtonItem?.title = "Update"
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}


// MARK: - Navigation
extension UserProfileViewController {
    func prepareNavigation() {
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.sizeToFit()
        setUpNavigationBar()
    }
    @objc func rightBarItemAction() {
        self.view.endEditing(true)
        if validateInput() {
            do {
                var user = try inputDataKeyValue.convert(to: User.self)
//                user.username = self.user.username
                if let gender = inputDataKeyValue["gender"] {
                    user.gender = Gender(rawValue: Int(gender)!)
                }
                update(user)
            } catch {
                AlertNotification.notify(message: "Some thing wrong when update your profile!", on: self)
            }
        }
    }
    func setUpNavigationBar() {
        navigationItem.title = "Profile"
        navigationItem.largeTitleDisplayMode = .always
        // BarButtonItem.
        let rightBarItem: UIBarButtonItem = {
            let bt = UIBarButtonItem(title: "Update", style: .plain, target: self, action: #selector(rightBarItemAction))
            return bt
        }()
        navigationItem.rightBarButtonItem = rightBarItem
    }
}


// MARK: - Image picker
extension UserProfileViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true, completion: nil)
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            pickedImage = image
            tableView.reloadData()
        }
    }
}


// MARK: - Table view DataSource.
extension UserProfileViewController: UITableViewDataSource {
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
        if indexPath.row == 0 {
            return 160
        }
        return 44
    }
}
// MARK: - Table view Delegate.
extension UserProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        if row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: ProfileAvatarTableViewCell.reuseIdentifier, for: indexPath) as! ProfileAvatarTableViewCell
            if pickedImage != nil {
                cell.avatarImage.image = pickedImage
            } else {
                cell.prepare(inputData[row])
            }
            return cell
        }
        
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
            if let genderText = inputData[row], let gender = Int(genderText) {
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
        if row == inputTypes.firstIndex(where: { $0 == .imagePicker}) {
            FeedBackTapEngine.tapped(style: .medium)
            imagePicker.allowsEditing = true
            imagePicker.sourceType = .photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        }
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
    
    
    // MARK: - Tasks
    func reloadGenderRow(_ indexPath: IndexPath, value: String) {
        let row = indexPath.row
        inputData[row] = value
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
}


// MARK: Text field Delegate.
extension UserProfileViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        tableView.setContentOffset(CGPoint(x: 0, y: 100), animated: true)
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var text = textField.text ?? ""
        if textField.tag == inputTypes.firstIndex(where: { $0 == .datePicker}) {
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
    
    
    // MARK: - Key board observer
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

