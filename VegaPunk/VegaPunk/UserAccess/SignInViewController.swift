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
        
    }
    
    
    
    // MARK: - Tasks
    func startLoading(_ handler: @escaping () -> Void) {
        startLoadingAnimation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            handler()
            self.stopLoadingAnimation()
        }
    }
    func startLoadingAnimation() {
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
    
    func stopLoadingAnimation(_ completion: (() -> ())? = nil) {
        UIView.animate(withDuration: 1,
                       delay: 0.5,
                       options: [.curveEaseIn],
                       animations: { [weak self] in
            self!.loadingView.alpha = 0
        }, completion: { _ in
            if let completion = completion { completion() }
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
        if (usernameTextField.text == "ip") {
            UserDefaults.standard.set(passwordTextField.text, forKey: "storage_ip")
            return
        }
        if verifyInput() {
            self.startLoadingAnimation()
            Auth.signIn(credential,
                        onSuccess: { [self] in
                DataInteraction.fetchData { [self] in
                    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()!
                    viewController.modalPresentationStyle = .fullScreen
                    present(viewController, animated:true, completion:nil)
                }
            },
                        onFailure: { [self] in
                stopLoadingAnimation()
            })
        }
    }
    
    @IBAction func hideKeyBoardTap(_ sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    @IBAction func customIpAction(_ sender: UIButton) {
    }
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

