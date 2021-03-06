//
//  SendMoneyVC+ScreenStatuses.swift
//  Franklin
//
//  Created by Anton on 20/02/2019.
//  Copyright © 2019 Matter Inc. All rights reserved.
//

import UIKit

extension SendMoneyController {
    
    func showStart(animated: Bool) {
        chosenContact = nil
        screenStatus = .start
        UIView.animate(withDuration: animated ?
            Constants.ModalView.animationDuration : 0) { [unowned self] in
                self.closeButton.isHidden = false
                self.backgroundView.isUserInteractionEnabled = true
                self.view.isUserInteractionEnabled = true
                self.mainButton.isEnabled = true
                guard let chosentoken = self.chosenToken else {
                    fatalError("no token selected")
                }
//                var net = chosentoken.isFranklin() ? "via plasma" : nil
//                net = chosentoken.isXDai() ? "via xDai" : net
//                self.setTitle(text: "Send money \(net ?? "")", color: Colors.mainBlue)
                self.setTitle(text: "Send \(chosentoken.name)", color: Colors.mainBlue)
                self.showGif(false)
                self.setBottomLabel(text: "Or share via", color: Colors.textLightGray, hidden: false)
                self.setCollectionView(hidden: true)
                self.setBottomButton(text: "Other app...", imageName: "share-blue", backgroundColor: Colors.textWhite, textColor: Colors.mainBlue, hidden: false, borderNeeded: true)
                self.setTopButton(text: "Send", imageName: "send-white", backgroundColor: Colors.orange, textColor: Colors.textWhite, hidden: false, borderNeeded: false)
                self.setTopStack(hidden: false, interactive: true, placeholder: "Amount in \(self.chosenToken?.symbol.uppercased() ?? "Unknown currency")", labelText: "Amount (\(self.chosenToken?.symbol.uppercased() ?? "Unknown currency")):")
                self.setBottomStack(hidden: false, interactive: true, placeholder: "Search by name", labelText: "or send to contact:", position: self.searchStackOrigin)
                self.setMiddleStack(hidden: false, interactive: true, placeholder: "Enter address", labelText: "Enter address:")
                self.setContactStack(hidden: true, interactive: false, contact: nil, labelText: "Send to:")
                self.setReadyIcon(hidden: true)
        }
    }
    
    @objc func showSearch(animated: Bool) {
        screenStatus = .searching
        UIView.animate(withDuration: Constants.ModalView.animationDuration) { [unowned self] in
            self.mainButton.isEnabled = true
            guard let chosentoken = self.chosenToken else {
                fatalError("no token selected")
            }
            self.setTitle(text: "Send \(chosentoken.name)", color: Colors.mainBlue)
            self.showGif(false)
            self.setBottomLabel(text: "Or share via", color: Colors.textLightGray, hidden: true)
            self.setCollectionView(hidden: false)
            self.setBottomButton(text: "Back", imageName: "left-blue", backgroundColor: Colors.textWhite, textColor: Colors.mainBlue, hidden: false, borderNeeded: true)
            self.setTopButton(text: "Add contact", imageName: "add-contacts", backgroundColor: Colors.mainBlue, textColor: Colors.textWhite, hidden: false, borderNeeded: false)
            self.setTopStack(hidden: true, interactive: false, placeholder: "Amount in \(self.chosenToken?.symbol.uppercased() ?? "Unknown currency")", labelText: "Amount (\(self.chosenToken?.symbol.uppercased() ?? "Unknown currency")):")
            self.setBottomStack(hidden: false, interactive: true, placeholder: "Search by name", labelText: "or send to contact:", position: self.topStackView.frame.origin.y)
            self.setMiddleStack(hidden: true, interactive: false, placeholder: "Enter address", labelText: "Enter address:")
            self.setContactStack(hidden: true, interactive: false, contact: nil, labelText: "Send to:")
            self.setReadyIcon(hidden: true)
        }
    }
    
    func showConfirmScreen(animated: Bool, for contact: Contact) {
        screenStatus = .confirm
        
        UIView.animate(withDuration: animated ?
            Constants.ModalView.animationDuration : 0) { [unowned self] in
                self.mainButton.isEnabled = true
                guard let chosentoken = self.chosenToken else {
                    fatalError("no token selected")
                }
                self.setTitle(text: "Send \(chosentoken.name)", color: Colors.mainBlue)
                self.showGif(false)
                self.setBottomLabel(text: "Or share via", color: Colors.textLightGray, hidden: true)
                self.setCollectionView(hidden: true)
                self.setBottomButton(text: "Send to \(contact.name)", imageName: "ssend-white", backgroundColor: Colors.orange, textColor: Colors.textWhite, hidden: false, borderNeeded: false)
                self.setTopButton(text: "Send", imageName: "send-white", backgroundColor: Colors.orange, textColor: Colors.textWhite, hidden: true, borderNeeded: false)
                self.setTopStack(hidden: false, interactive: true, placeholder: "Amount in \(self.chosenToken?.symbol.uppercased() ?? "Unknown currency")", labelText: "Amount (\(self.chosenToken?.symbol.uppercased() ?? "Unknown currency")):")
                self.setBottomStack(hidden: true, interactive: false, placeholder: "Search by name", labelText: "or send to contact:", position: self.searchStackOrigin)
                self.setMiddleStack(hidden: true, interactive: false, placeholder: "Enter address", labelText: "Enter address:")
                self.setContactStack(hidden: false, interactive: true, contact: contact, labelText: "Send to:")
                self.setReadyIcon(hidden: true)
        }
    }
    
    @objc func showSending(animated: Bool) {
        screenStatus = .sending
        closeButton.isHidden = true
        backgroundView.isUserInteractionEnabled = false
        view.isUserInteractionEnabled = false
        showGif(true)
        UIView.animate(withDuration: animated ?
            Constants.ModalView.animationDuration : 0, animations: { [unowned self] in
                self.mainButton.isEnabled = true
                
                self.setTitle(text: "Sending...", color: Colors.mainBlue)
                self.setBottomLabel(text: "Or share via", color: Colors.textLightGray, hidden: true)
                self.setCollectionView(hidden: true)
                self.setBottomButton(text: nil, imageName: nil, backgroundColor: Colors.orange, textColor: Colors.textWhite, hidden: true, borderNeeded: false)
                self.setTopButton(text: nil, imageName: nil, backgroundColor: Colors.orange, textColor: Colors.textWhite, hidden: true, borderNeeded: false)
                self.setTopStack(hidden: false, interactive: true, placeholder: "Amount in \(self.chosenToken?.symbol.uppercased() ?? "Unknown currency")", labelText: "Amount (\(self.chosenToken?.symbol.uppercased() ?? "Unknown currency")):")
                self.setBottomStack(hidden: true, interactive: false, placeholder: "Search by self.name", labelText: "or send to contact:", position: self.searchStackOrigin)
                self.setMiddleStack(hidden: true, interactive: false, placeholder: "Enter address", labelText: "Enter address:")
                self.setContactStack(hidden: false, interactive: true, contact: self.chosenContact, labelText: "Send to:")
                self.setReadyIcon(hidden: true)
        }) { [unowned self] (completed) in
            if completed {
                self.sending()
            }
        }
    }
    
    @objc func showReady(animated: Bool) {
        screenStatus = .ready
        DispatchQueue.main.async { [unowned self] in
            self.closeButton.isHidden = false
            self.backgroundView.isUserInteractionEnabled = true
            self.view.isUserInteractionEnabled = true
            self.showGif(false)
            guard let contact = self.chosenContact else {return}
            UIView.animate(withDuration: animated ?
                Constants.ModalView.animationDuration : 0) { [unowned self] in
                    self.setReadyIcon(hidden: false)
            }
            UIView.animate(withDuration: animated ?
                Constants.ModalView.animationDuration : 0) { [unowned self] in
                    self.mainButton.isEnabled = true
                    
                    self.setTitle(text: "Sent!", color: Colors.mainGreen)
                    self.setBottomLabel(text: "Or share via", color: Colors.textLightGray, hidden: true)
                    self.setCollectionView(hidden: true)
                    self.setBottomButton(text: "Close", imageName: nil, backgroundColor: Colors.mainBlue, textColor: Colors.textWhite, hidden: false, borderNeeded: true)
                    self.setTopButton(text: "Save contact", imageName: "add-contacts", backgroundColor: Colors.textWhite, textColor: Colors.mainBlue, hidden: contact.name == "" ? false : true, borderNeeded: true)
                    self.setTopStack(hidden: false, interactive: false, placeholder: "Amount in \(self.chosenToken?.symbol.uppercased() ?? "Unknown currency")", labelText: "Amount (\(self.chosenToken?.symbol.uppercased() ?? "Unknown currency")):")
                    self.setBottomStack(hidden: true, interactive: false, placeholder: "Search by name", labelText: "or send to contact:", position: self.searchStackOrigin)
                    self.setMiddleStack(hidden: true, interactive: false, placeholder: "Enter address", labelText: "Enter address:")
                    self.setContactStack(hidden: false, interactive: false, contact: self.chosenContact, labelText: "Send to:")
            }
        }
    }
    
    @objc func showSaving(animated: Bool) {
        screenStatus = .saving
        UIView.animate(withDuration: animated ?
            Constants.ModalView.animationDuration : 0) { [unowned self] in
                self.mainButton.isEnabled = true
                
                self.setTitle(text: "Add contact", color: Colors.mainBlue)
                self.showGif(false)
                self.setBottomLabel(text: "Or share via", color: Colors.textLightGray, hidden: true)
                self.setCollectionView(hidden: true)
                self.setBottomButton(text: "Close", imageName: nil, backgroundColor: Colors.textWhite, textColor: Colors.mainBlue, hidden: false, borderNeeded: true)
                self.setTopButton(text: "Save", imageName: "button-save", backgroundColor: Colors.mainGreen, textColor: Colors.textWhite, hidden: false, borderNeeded: false)
                self.setTopStack(hidden: false, interactive: true, placeholder: "Enter name", labelText: "Contact name:", resetText: true, keyboardType: .default)
                self.setBottomStack(hidden: true, interactive: false, placeholder: "Search by name", labelText: "or send to contact:", position: self.searchStackOrigin)
                self.setMiddleStack(hidden: true, interactive: false, placeholder: "Enter address", labelText: "Enter address:")
                self.setContactStack(hidden: true, interactive: false, contact: self.chosenContact, labelText: "Send to:")
                self.setReadyIcon(hidden: true)
        }
    }
    
    func sending() {
        guard let token = chosenToken else { return }
        if token.isFranklin() {
            animationTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: false)
        } else if token.isXDai() {
            sendXDai()
        } else if token.isEther() {
            sendEther()
        } else if !CurrentNetwork.currentNetwork.isXDai() || token.isDai() {
            sendToken(token)
        } else {
            sendTokenXDai(token)
        }
    }
}
