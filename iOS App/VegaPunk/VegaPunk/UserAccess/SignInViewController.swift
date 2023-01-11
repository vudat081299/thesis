//
//  UserAccessControlViewController.swift
//  MyMapKit
//
//  Created by Vũ Quý Đạt  on 17/12/2020.
//

import UIKit

class SignInViewController: UIViewController {
    
    @IBOutlet weak var csTopContainerView: NSLayoutConstraint!
    @IBOutlet weak var csTopSigninView: NSLayoutConstraint!
    @IBOutlet weak var signinView: UIView!
    @IBOutlet weak var layerUsernameTextField: UIView!
    @IBOutlet weak var usernameTextFieldContainer: UIView!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var layerPasswordTextField: UIView!
    @IBOutlet weak var passwordTextFieldContainer: UIView!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var domainInput: UITextField!
    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var animationLoadingView: NVActivityIndicatorView!
    
    var credential = Credential(username: "", password: "")
    var keyboardHeight: CGFloat = 0.0
    var isChangePageByPageControl = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Prepare navigation
        navigationController?.navigationBar.isHidden = false
        title = "Social Messaging"

        // Do any additional setup after loading the view.
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // set up UI
        animationLoadingView.type = .cubeTransition
        
        layerUsernameTextField.border()
        layerUsernameTextField.dropShadow()
        usernameTextFieldContainer.border()
        usernameTextFieldContainer.dropShadow()
        layerPasswordTextField.border()
        layerPasswordTextField.dropShadow()
        passwordTextFieldContainer.border()
        passwordTextFieldContainer.dropShadow()
        
        let _ = UserData.store(networkConfigure: NetworkConfigure(domain: "http://192.168.1.24:8080/", ip: "192.168.1.24", port: "8080"))
//        let _ = UserData.store(credential: Credential(username: "dat3", password: "dat3"))
//        RequestEngine.getAllUsers() //
//        RequestEngine.getAllMappings() //
//        RequestEngine.getMessagesOfChatBox(UUID(uuidString: "C3016DD5-5360-4E18-93BC-A0DE9E12A00B")!)
//        RequestEngine.getAllMappingPivots() //
//        RequestEngine.getMemberInChatBox(UUID(uuidString: "C3016DD5-5360-4E18-93BC-A0DE9E12A00B")!)
        
//        Auth.signUp(User(name: "trantradang", username: "trangtadsfasdfrang3009", join: Date().iso8601String, password: "vasdfudat0812")) //
        
    }
    
    
    
    // MARK: - Tasks
    func startLoading(_ handler: @escaping () -> Void) {
        startLoadingAnimation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            handler()
            self.stopLoadingAnimation()
        }
    }
    func startLoadingAnimation () {
        UIView.animate(withDuration: 0.3,
                       delay: 0.1,
                       options: [.curveEaseIn],
                       animations: { [weak self] in
                        self!.view.endEditing(true)
                        self!.loadingView.isHidden = false
                        self!.view.bringSubviewToFront(self!.loadingView)
                        self!.loadingView.alpha = 1
                        self!.animationLoadingView.startAnimating()
                       }, completion: nil)
    }
    
    func stopLoadingAnimation () {
        UIView.animate(withDuration: 1,
                       delay: 0.5,
                       options: [.curveEaseIn],
                       animations: { [weak self] in
                        self!.loadingView.alpha = 0
                       }, completion: {_ in
                        self.loadingView.isHidden = true
                        self.view.sendSubviewToBack(self.loadingView)
                        self.animationLoadingView.stopAnimating()
                       })
    }
    
    
    
    // MARK: - Mini tasks
    func verifyInput() -> Bool {
        guard let username = usernameTextField.text, !username.isEmpty else {
            ErrorPresenter.showError(message: "Please enter your username!", on: self)
            return false
        }
        guard let password = passwordTextField.text, !password.isEmpty else {
            ErrorPresenter.showError(message: "Please enter your password!", on: self)
            return false
        }
        credential.username = username
        credential.password = password
        return true
    }
    
    
    
    // MARK: IBActions
    @IBAction func signIn(_ sender: UIButton) {
        if verifyInput() {
            Auth.signIn(credential) {
                self.startLoadingAnimation()
                RequestEngine.getAllUsers {
                    RequestEngine.getAllMappings {
                        RequestEngine.getAllMappingPivots {
                            RequestEngine.getMyChatBoxes {
                                self.stopLoadingAnimation()
                                DispatchQueue.main.async { [self] in
                                    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()!
                                    viewController.modalPresentationStyle = .fullScreen
                                    self.present(viewController, animated:true, completion:nil)
                                }
                            }
                        }
                    }
                }
            }
        }
//        Auth.login(username: username, password: password) { result in
//            switch result {
//            case .success:
//                DispatchQueue.main.async { [self] in
//                    startLoading {
//                        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()!
//                        viewController.modalPresentationStyle = .fullScreen
//                        self.present(viewController, animated:true, completion:nil)
//                    }
//                }
//            case .failure:
//                let message = "Could not login. Check your credentials and try again!"
//                ErrorPresenter.showError(message: message, on: self)
//            }
//        }
    }
    
    @IBAction func hideKeyBoardTap(_ sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    @IBAction func customIpAction(_ sender: UIButton) {
    }
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}



//MARK: Keyboard appearance.
extension SignInViewController: UITextFieldDelegate {
    @objc func keyboardWillShow(_ notification: NSNotification) {
        if let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardHeight = keyboardRect.height
            UIView.animate(withDuration: 0.3,
                           delay: 0.1,
                           options: [.curveEaseIn],
                           animations: { [weak self] in
                            self!.csTopContainerView.constant = -50
                            self?.view.layoutIfNeeded()
                           }, completion: nil)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        csTopContainerView.constant = 0
        view.layoutIfNeeded()
    }
}

