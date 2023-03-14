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
    let imagePicker = UIImagePickerController()
    var user: User!
    
    var keyboardHeight: CGFloat = 0.0
    var inputDataKeyValue: [String: String] = [:]
    var birthString = ""
    var isUserInteractionEnabled = true // Depic whether this view is for user update their profile or display orther user's profile
    
    
    // MARK: - Table view data.
    let sectionHeaders = ["Cập nhật thông tin cá nhân"]
    let sectionHeadersForProfileViewer = "Thông tin người dùng"
    let rowLabels = [
        "Avatar", "Họ & tên",
        "Giới tính", "Số điện thoại", "Email", "Ngày sinh", "Giới thiệu", "Quốc gia"
    ]
    let placeHolders = [
        "Không bắt buộc", "Không bắt buộc",
        "Không bắt buộc", "Bắt buộc", "Bắt buộc", "dd/mm/yyyy", "Không bắt buộc", "Không bắt buộc"
    ]
    let inputTypes: [CellCategory] = [
        .imagePicker, .text,
        .gender, .number, .text, .datePicker, .text, .text
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
        configureHierarchy()
        prepareNavigation()
        prepareObserver()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareData()
        tableView.reloadData()
        setUpNavigationBar()
    }
    
    
    // MARK: - public methods
    public func prepareData() {
//        with user: User? = AuthenticatedUser.retrieve()?.data
        if user == nil {
            user = AuthenticatedUser.retrieve()?.data
        }
//        self.user = user
        isUserInteractionEnabled = user.id == AuthenticatedUser.retrieve()?.data?.id
        var userClone = user!
        let gender = userClone.gender?.rawValue.description
        do {
            userClone.gender = nil
            userClone.token = nil
            let userCloneDictionary = try userClone.toDictionary()
            for (index, field) in fieldKeys.enumerated() {
                inputData[index] = userCloneDictionary[field]
            }
            inputData[inputTypes[.gender]] = gender
        } catch {
            inputData[0] = user.avatar
            inputData[1] = user.name
            inputData[2] = user.gender?.rawValue.description
            inputData[3] = user.phone
            inputData[4] = user.email
            inputData[5] = user.birth
            inputData[6] = user.bio
            inputData[7] = user.country
        }
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
    
    
    // MARK: - @objc
    @objc func signOut() {
        user = nil
        resetApplicationMetadata()
        configureApplication()
        appState = .unauthorized
        self.view.window?.switchRootViewController()
    }
    
    
    // MARK: - Mini tasks
    func validateInput() -> Bool {
        let requiredIndex = [1, 3, 4]
        for (index, value) in inputData.enumerated() {
            if requiredIndex.contains(index) && (value == nil || value == "") {
                AlertNotification.notify(message: "Hãy nhập những thông tin bắt buộc!", on: self)
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
    func resetApplicationMetadata() {
        AuthenticatedUser.remove()
        Chatboxes.remove()
        Mappings.remove()
        Messages.remove()
        Friend.remove()
    }
    
    /// Configure default specification for application.
    /// - ex: domain, ip, port,..
    func configureApplication() {
        AuthenticatedUser.store(networkConfig: NetworkConfig(domain: "http://\(configureIp):8080/", ip: configureIp, port: "8080"))
    }
}


// MARK: - APIs
extension UserProfileViewController {
    func update(_ user: User) {
        var user = user
        navigationItem.rightBarButtonItem?.isEnabled = false
        if let image = pickedImage {
            RequestEngine.upload(image.resized(to: 360).pngData()!) { [self] fileId in
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
            DispatchQueue.main.async { [self] in
                SoundFeedBack.success()
                if let userData = AuthenticatedUser.retrieve()?.data {
                    self.user = userData
                }
                prepareData()
                tableView.reloadData()
                navigationItem.rightBarButtonItem?.tintColor = .systemGreen
                navigationItem.rightBarButtonItem?.image = UIImage(systemName: "checkmark.circle.fill")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
                navigationItem.rightBarButtonItem?.tintColor = .link
                navigationItem.rightBarButtonItem?.image = nil
                navigationItem.rightBarButtonItem?.title = "Cập nhật"
                navigationItem.rightBarButtonItem?.isEnabled = true
                navigationController?.popViewController(animated: true)
            }
        }
    }
}


// MARK: - Navigation
extension UserProfileViewController {
    func prepareNavigation() {
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.navigationBar.sizeToFit()
        self.navigationController?.navigationItem.largeTitleDisplayMode = .always
//        setUpNavigationBar()
    }
    func setUpNavigationBar() {
//        navigationItem.title = "Profile"
//        navigationItem.largeTitleDisplayMode = .always
        if !isUserInteractionEnabled { return }
        // BarButtonItem.
        let rightBarItem: UIBarButtonItem = {
            let bt = UIBarButtonItem(title: "Cập nhật", style: .plain, target: self, action: #selector(rightBarItemAction))
            return bt
        }()
        navigationItem.rightBarButtonItem = rightBarItem
        let leftBarButtonItem: UIBarButtonItem = {
            let bt = UIBarButtonItem(title: "Đăng xuất", style: .plain, target: self, action: #selector(signOut))
            bt.tintColor = .systemRed
            return bt
        }()
        navigationItem.leftBarButtonItem = leftBarButtonItem
    }
    @objc func rightBarItemAction() {
        self.view.endEditing(true)
        if validateInput() {
            do {
                var user = try inputDataKeyValue.convert(to: User.self)
                user.username = self.user.username
                if let gender = inputData[inputTypes[.gender]] {
                    user.gender = Gender(rawValue: Int(gender)!)
                }
                update(user)
            } catch {
                AlertNotification.notify(message: "Some thing wrong when update your profile!", on: self)
            }
        }
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


// MARK: - Table view
extension UserProfileViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if !isUserInteractionEnabled { return sectionHeadersForProfileViewer }
        return sectionHeaders[section]
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 240
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
        cell.isUserInteractionEnabled = isUserInteractionEnabled
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
        prepareAvatarPickerView(for: indexPath)
        prepareGenderPickerView(for: indexPath)
    }
    
    func prepareAvatarPickerView(for indexPath: IndexPath) {
        let row = indexPath.row
        if row == inputTypes.firstIndex(where: { $0 == .imagePicker}) {
            FeedBackTapEngine.tapped(style: .medium)
            imagePicker.allowsEditing = true
            imagePicker.sourceType = .photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    func prepareGenderPickerView(for indexPath: IndexPath) {
        let row = indexPath.row
        if row == inputTypes.firstIndex(of: .gender) {
            let alert = UIAlertController(title: "Chọn giới tính của bạn", message: "", preferredStyle: .actionSheet)
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


// MARK: Text field Delegate
extension UserProfileViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        tableView.setContentOffset(CGPoint(x: 0, y: 100), animated: true)
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var text = textField.text ?? ""
        if textField.tag == inputTypes[.datePicker] {
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
        } else if textField.tag == inputTypes[.number] {
            if string.count == 0 {
                return true
            }
            guard let _ = Int(string) else { return false }
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

