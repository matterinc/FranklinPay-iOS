//
//  OnboardingViewController.swift
//  DiveLane
//
//  Created by Anton Grigorev on 08/09/2018.
//  Copyright © 2018 Matter Inc. All rights reserved.
//

import UIKit
import SwiftyGif

class OnboardingViewController: BasicViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var settingUp: UILabel!
    @IBOutlet weak var iv: UIImageView!
    @IBOutlet weak var link: UILabel!
    @IBOutlet weak var bottomInfo: UILabel!
    @IBOutlet weak var prodName: UILabel!
    @IBOutlet weak var subtitle: UILabel!
    @IBOutlet weak var animationImageView: UIImageView!
    @IBOutlet weak var importButton: BasicWhiteButton!
    @IBOutlet weak var createButton: BasicGreenButton!
    @IBOutlet weak var contentView: UIView!
    
    // MARK: - Internal lets
    
    internal let walletCreating = WalletCreating()
    internal let appController = AppController()
    internal let alerts = Alerts()
    internal var walletCreated = false
    
    // MARK: - Lazy vars
    
    weak var animationTimer: Timer?
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        mainSetup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showStart()
    }
    
    // MARK: - Main setup
    
    func setupNavigation() {
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func showStart() {
        UIView.animate(withDuration: 1) { [unowned self] in
            self.view.alpha = 1
        }
    }
    
    func mainSetup() {
        link.alpha = 0
        bottomInfo.alpha = 0
        
        parent?.view.backgroundColor = .white
        view.alpha = 0
        
        animationImageView.setGifImage(UIImage(gifName: "loading.gif"))
        animationImageView.loopCount = -1
        
        prodName.text = Constants.prodName
        prodName.textAlignment = .center
        prodName.textColor = Colors.textDarkGray
        prodName.font = UIFont(name: Constants.Fonts.franklinSemibold, size: 55) ?? UIFont.boldSystemFont(ofSize: 55)
        
        subtitle.textAlignment = .center
        subtitle.text = Constants.slogan
        subtitle.textColor = Colors.textDarkGray
        subtitle.font = UIFont(name: Constants.Fonts.franklinMedium, size: 22) ?? UIFont.systemFont(ofSize: 22)
        
        bottomInfo.textAlignment = .center
        bottomInfo.text = "By clicking 'Continue' you agree to the"
        bottomInfo.textColor = Colors.textDarkGray
        bottomInfo.font = UIFont(name: Constants.Fonts.regular, size: 16) ?? UIFont.systemFont(ofSize: 16)
        
        let attrs = [
            NSAttributedString.Key.font : UIFont(name: Constants.Fonts.regular, size: 16) ?? UIFont.systemFont(ofSize: 16),
            NSAttributedString.Key.foregroundColor : Colors.mainGreen,
            NSAttributedString.Key.underlineStyle : 1] as [NSAttributedString.Key : Any]
        let buttonTitleString = NSAttributedString(string: "terms and conditions", attributes: attrs)
        link.attributedText = buttonTitleString
        
        settingUp.textAlignment = .center
        settingUp.text = "Setting up your wallet"
        settingUp.textColor = Colors.textDarkGray
        settingUp.font = UIFont(name: Constants.Fonts.regular, size: 24) ?? UIFont.systemFont(ofSize: 24)
        
        animationImageView.frame = CGRect(x: 0, y: 0, width: 0.8*UIScreen.main.bounds.width, height: 257)
        animationImageView.contentMode = .center
        animationImageView.alpha = 0
        animationImageView.isUserInteractionEnabled = false
        
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "franklin")!
        
        settingUp.alpha = 0
        
        createButton.addTarget(self,
                                      action: #selector(continueAction(sender:)),
                                      for: .touchUpInside)
        createButton.setTitle("Create wallet", for: .normal)
        createButton.alpha = 1
        
        importButton.addTarget(self,
                               action: #selector(importAction(sender:)),
                               for: .touchUpInside)
        importButton.setTitle("Import wallet", for: .normal)
        importButton.alpha = 1
        
//        link.addTarget(self, action: #selector(readTerms(sender:)), for: .touchUpInside)
        
    }
    
    // MARK: - Animations
    
    func animation() {
        animationTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: false)
        creatingWalletAnimation()
    }
    
    @objc func fireTimer() {
        animationTimer?.invalidate()
        if walletCreated {
            goToApp()
        }
    }
    
    func creatingWalletAnimation() {
        UIView.animate(withDuration: Constants.Main.animationDuration) {
            self.createButton.alpha = 0
            self.importButton.alpha = 0
            self.link.alpha = 0
            self.bottomInfo.alpha = 0
            self.animationImageView.alpha = 1
            self.settingUp.alpha = 1
        }
    }
    
    // MARK: - Actions
    
    func creatingWallet() {
        DispatchQueue.global().async { [unowned self] in
            do {
                let wallet = try self.walletCreating.createWallet()
                self.finishSavingWallet(wallet)
            } catch let error {
                self.alerts.showErrorAlert(for: self, error: error, completion: nil)
            }
        }
    }
    
    func finishSavingWallet(_ wallet: Wallet) {
        do {
            try walletCreating.prepareWallet(wallet)
//            appController.initPreparations(for: wallet, on: Web3Network(network: .Mainnet))
            walletCreated = true
            if animationTimer == nil {
                goToApp()
            }
        } catch let error {
            deleteWallet(wallet: wallet, withError: error)
        }
        
    }
    
    func deleteWallet(wallet: Wallet, withError error: Error) {
        do {
            try wallet.delete()
            alerts.showErrorAlert(for: self, error: error, completion: nil)
        } catch let deleteErr {
            alerts.showErrorAlert(for: self, error: deleteErr, completion: nil)
        }
    }
    
    func goToApp() {
        DispatchQueue.main.async { [unowned self] in
            UIView.animate(withDuration: Constants.Main.animationDuration) { [unowned self] in
                self.view.hideSubviews()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [unowned self] in
                    let tabViewController = self.appController.goToApp()
                    //                        tabViewController.context
                    //                        tabViewController.view.backgroundColor = Colors.background
                    //                        let transition = CATransition()
                    //                        transition.duration = Constants.Main.animationDuration
                    //                        transition.type = CATransitionType.push
                    //                        transition.subtype = CATransitionSubtype.fromRight
                    //                        transition.timingFunction = CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut)
                    //                        self.view.window!.layer.add(transition, forKey: kCATransition)
                    self.present(tabViewController, animated: false, completion: nil)
//                    let tabViewController = self.appController.goToApp()
//                    tabViewController.view.backgroundColor = Colors.background
//                    let transition = CATransition()
//                    transition.duration = Constants.Main.animationDuration
//                    transition.type = CATransitionType.push
//                    transition.subtype = CATransitionSubtype.fromRight
//                    transition.timingFunction = CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut)
//                    self.view.window!.layer.add(transition, forKey: kCATransition)
//                    self.present(tabViewController, animated: false, completion: nil)
                })
            }
        }
    }
    
    // MARK: - Buttons actions
    
    @objc func continueAction(sender: UIButton) {
        createButton.isUserInteractionEnabled = false
        animation()
        creatingWallet()
    }
    
    @objc func importAction(sender: UIButton) {
        let vc = WalletImportingViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func readTerms(sender: UIButton) {
        print("Need to open terms")
    }

}
