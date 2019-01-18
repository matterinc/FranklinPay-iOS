//
//  WalletViewController.swift
//  DiveLane
//
//  Created by Anton Grigorev on 08/09/2018.
//  Copyright © 2018 Matter Inc. All rights reserved.
//

import UIKit
import Web3swift
import EthereumAddress
import BigInt

class WalletViewController: BasicViewController {

    @IBOutlet weak var walletTableView: BasicTableView!
    @IBOutlet weak var blockchainControl: SegmentedControl!

    private var tokensService = TokensService()
    private var walletsService = WalletsService()
    private var twoDimensionalTokensArray: [ExpandableTableTokens] = []
    private var twoDimensionalUTXOsArray: [ExpandableTableUTXOs] = []
    private var chosenUTXOs: [TableUTXO] = []

    private let alerts = Alerts()
    private let plasmaCoordinator = PlasmaCoordinator()
    private let etherCoordinator = EtherCoordinator()
    
    var ratesUpdating = false

    private enum Blockchain: Int {
        case ether = 0
        case plasma = 1
    }

    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
        #selector(self.handleRefresh(_:)),
                for: UIControl.Event.valueChanged)
        refreshControl.tintColor = Colors.secondMain

        return refreshControl
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        print(CurrentWallet.currentWallet?.address)
        print(CurrentToken.currentToken?.name)
        print(CurrentNetwork.currentNetwork.name)
        self.view.backgroundColor = Colors.firstMain
        self.tabBarController?.tabBar.selectedItem?.title = nil
        self.setupNavigation()
        self.setupTableView()
        self.refreshing(true)
    }
    
    func setupTableView() {
        let nibToken = UINib.init(nibName: "TokenCell", bundle: nil)
        self.walletTableView.delegate = self
        self.walletTableView.dataSource = self
        let footerView = UIView()
        footerView.backgroundColor = Colors.firstMain
        self.walletTableView.tableFooterView = footerView
        self.walletTableView.addSubview(self.refreshControl)
        self.walletTableView.register(nibToken, forCellReuseIdentifier: "TokenCell")
    }
    
    func setupNavigation() {
        self.title = "Wallets"
        self.navigationController?.navigationBar.isHidden = false
    }
    
    func clearData() {
        twoDimensionalTokensArray.removeAll()
        twoDimensionalUTXOsArray.removeAll()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateTable()
    }

//    func unselectAllTokens() {
//        var indexPath = IndexPath(row: 0, section: 0)
//        for wallet in twoDimensionalTokensArray {
//            for _ in wallet.tokens {
//                self.twoDimensionalTokensArray[indexPath.section].tokens[indexPath.row].isSelected = false
//                if let cell = self.walletTableView.cellForRow(at: indexPath) as? TokenCell {
//                    cell.changeSelectButton(isSelected: false)
//                }
//                indexPath.row += 1
//            }
//            indexPath.section += 1
//            indexPath.row = 0
//        }
//    }

    func unselectAllUTXOs() {
        var indexPath = IndexPath(row: 0, section: 0)
        for wallet in twoDimensionalUTXOsArray {
            for _ in wallet.utxos {
                self.twoDimensionalUTXOsArray[indexPath.section].utxos[indexPath.row].isSelected = false
                guard let cell = self.walletTableView.cellForRow(at: indexPath) as? UTXOCell else {return}
                cell.changeSelectButton(isSelected: false)
                indexPath.row += 1
            }
            indexPath.section += 1
            indexPath.row = 0
        }
    }

//    func selectToken(cell: UITableViewCell) {
//        unselectAllTokens()
//        guard let cell = cell as? TokenCell else {return}
//        guard let indexPathTapped = self.walletTableView.indexPath(for: cell) else {return}
//        let token = self.twoDimensionalTokensArray[indexPathTapped.section].tokens[indexPathTapped.row]
//        CurrentWallet.currentWallet = token.inWallet
//        CurrentToken.currentToken = token.token
//        self.twoDimensionalTokensArray[indexPathTapped.section].tokens[indexPathTapped.row].isSelected = true
//        cell.changeSelectButton(isSelected: true)
//    }

    func selectUTXO(cell: UITableViewCell) {
        guard let cell = cell as? UTXOCell else {return}
        guard let indexPathTapped = self.walletTableView.indexPath(for: cell) else {return}
        let utxo = self.twoDimensionalUTXOsArray[indexPathTapped.section].utxos[indexPathTapped.row]
        let wallet = utxo.inWallet
        let selected = self.twoDimensionalUTXOsArray[indexPathTapped.section].utxos[indexPathTapped.row].isSelected
        if selected {
            for i in 0..<self.chosenUTXOs.count where self.chosenUTXOs[i] == utxo {
                self.chosenUTXOs.remove(at: i)
                break
            }
        } else {
            guard self.chosenUTXOs.count < 2 else {
                self.alerts.showErrorAlert(for: self,
                                           error: "Can't select more than 2 utxos",
                                           completion: nil)
                return
            }
            if let firstUTXO = self.chosenUTXOs.first {
                guard wallet == firstUTXO.inWallet else {
                    self.alerts.showErrorAlert(for: self,
                                               error: "UTXOs must be in one wallet",
                                               completion: nil)
                    return
                }
                self.chosenUTXOs.append(utxo)
            } else {
                self.chosenUTXOs.append(utxo)
            }
        }
        self.twoDimensionalUTXOsArray[indexPathTapped.section].utxos[indexPathTapped.row].isSelected = !selected
        cell.changeSelectButton(isSelected: !selected)
        if self.chosenUTXOs.count == 2 {
            self.alerts.showAccessAlert(for: self, with: "Merge UTXOs?") { [unowned self] (result) in
                if result {
                    guard let tx = try? self.plasmaCoordinator.formMergeUTXOsTransaction(for: wallet, utxos: self.chosenUTXOs) else {
                        self.alerts.showErrorAlert(for: self, error: "Can't merge UTXOs", completion: nil)
                        return
                    }
                    self.enterPincode(for: tx)
                }
            }
        }
    }

    func enterPincode(for transaction: PlasmaTransaction) {
        //need to wallet.getPassword
        let enterPincode = EnterPincodeViewController(for: .transaction, data: transaction)
        self.navigationController?.pushViewController(enterPincode, animated: true)
    }

    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.updateTable()
    }

    func reloadDataInTable() {
        DispatchQueue.main.async { [unowned self] in
            self.walletTableView.reloadData()
        }
    }

    func updateTable() {
        self.clearData()
        //self.setBlockchainControl(enabled: false)
        let blockchain = self.blockchainControl.selectedSegmentIndex
        self.updateEtherBlockchain(firstCompletion: {
            if blockchain == Blockchain.ether.rawValue {
                self.reloadDataInTable()
                self.refreshing(false)
            }
        }) {
            if blockchain == Blockchain.ether.rawValue {
                self.reloadDataInTable()
                self.refreshing(false)
            }
        }
        self.updatePlasmaBlockchain {
            if blockchain == Blockchain.plasma.rawValue {
                self.reloadDataInTable()
                self.refreshing(false)
            }
        }
//        switch self.blockchainControl.selectedSegmentIndex {
//        case Blockchain.ether.rawValue:
//            self.updateEtherBlockchain()
//        default:
//            self.updatePlasmaBlockchain()
//        }
    }
    
    func updatePlasmaBlockchain(completion: @escaping () -> Void) {
        DispatchQueue.global().async { [unowned self] in
            let utxos = self.plasmaCoordinator.getWalletsAndUTXOs()
            self.twoDimensionalUTXOsArray = utxos
            completion()
//            self.reloadDataInTable()
//            self.setBlockchainControl(enabled: true)
//            self.refreshing(false)
        }
    }
    
    func refreshing(_ enabled: Bool) {
        if enabled {
            DispatchQueue.main.async { [unowned self] in
                self.refreshControl.tintColor = Colors.secondMain
                self.refreshControl.beginRefreshing()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2,
                                          execute: { [unowned self] in
                                            self.refreshControl.endRefreshing()
            })
        }
    }
    
//    func setBlockchainControl(enabled: Bool) {
//        DispatchQueue.main.async { [unowned self] in
//            self.blockchainControl.isUserInteractionEnabled = enabled
//            self.blockchainControl.isEnabled = enabled
//        }
//    }

    func updateEtherBlockchain(firstCompletion: @escaping () -> Void, secondCompletion: @escaping () -> Void) {
        DispatchQueue.global().async { [unowned self] in
            let tokens = self.etherCoordinator.getWalletsAndTokens()
            self.twoDimensionalTokensArray = tokens
            //self.reloadDataInTable()
            firstCompletion()
            self.updateTokensBalances {
                secondCompletion()
                //self.reloadDataInTable()
                //self.setBlockchainControl(enabled: true)
                //self.refreshing(false)
            }
        }
    }
    
    func updateTokenRow(rowIndexPath: IndexPath) {
        DispatchQueue.main.async { [unowned self] in
            self.walletTableView.reloadRows(at: [rowIndexPath], with: .none)
        }
    }
    
    func updateTokensBalances(completion: @escaping () -> Void) {
        guard !self.ratesUpdating else {return}
        self.ratesUpdating = true
        guard !self.twoDimensionalTokensArray.isEmpty else {return}
        var indexPath = IndexPath(row: 0, section: 0)
        for wallet in self.twoDimensionalTokensArray {
            for token in wallet.tokens {
                var currentTableToken = token
                let currentToken = token.token
                let currentWallet = token.inWallet
                let balance = self.etherCoordinator.getBalance(for: currentToken, wallet: currentWallet)
                currentToken.balance = balance
                let balanceInDollars = self.etherCoordinator.getBalanceInDollars(for: token.token, withBalance: balance)
                currentToken.usdBalance = balanceInDollars
                currentTableToken.token = currentToken
                self.twoDimensionalTokensArray[indexPath.section].tokens[indexPath.row] = currentTableToken
//                    let ip = indexPath
//                    self.updateTokenRow(rowIndexPath: ip)
                try? token.inWallet.setBalance(token: currentToken, network: CurrentNetwork.currentNetwork, balance: balance)
                try? token.inWallet.setUsdBalance(token: currentToken, network: CurrentNetwork.currentNetwork, usdBalance: balanceInDollars)
                indexPath.row += 1
            }
            indexPath.section += 1
            indexPath.row = 0
        }
        self.ratesUpdating = false
        completion()
    }

    @IBAction func blockchainChanged(_ sender: UISegmentedControl) {
        self.reloadDataInTable()
        self.refreshing(true)
        self.updateTable()
    }
    
    func deleteToken(in indexPath: IndexPath) {
        guard self.blockchainControl.selectedSegmentIndex == Blockchain.ether.rawValue else {return}
        let token = self.twoDimensionalTokensArray[indexPath.section].tokens[indexPath.row].token
        let wallet = self.twoDimensionalTokensArray[indexPath.section].tokens[indexPath.row].inWallet
        let network = CurrentNetwork.currentNetwork
        let isEtherToken = token == Ether()
        if isEtherToken {return}
        do {
            try wallet.delete(token: token, network: network)
            CurrentToken.currentToken = Ether()
            self.updateTable()
        } catch let error {
            self.alerts.showErrorAlert(for: self, error: error, completion: nil)
        }
    }
    
    func didPressExpand(sender: UIButton) {
        let section = sender.tag
        var indexPaths = [IndexPath]()
        let isExpanded: Bool
        
        switch self.blockchainControl.selectedSegmentIndex {
        case Blockchain.ether.rawValue:
            for row in self.twoDimensionalTokensArray[section].tokens.indices {
                let indexPath = IndexPath(row: row, section: section)
                indexPaths.append(indexPath)
            }
            
            isExpanded = self.twoDimensionalTokensArray[section].isExpanded
            self.twoDimensionalTokensArray[section].isExpanded = !isExpanded
        default:
            for row in self.twoDimensionalUTXOsArray[section].utxos.indices {
                let indexPath = IndexPath(row: row, section: section)
                indexPaths.append(indexPath)
            }
            
            isExpanded = self.twoDimensionalUTXOsArray[section].isExpanded
            self.twoDimensionalUTXOsArray[section].isExpanded = !isExpanded
        }
        if isExpanded {
            self.walletTableView.deleteRows(at: indexPaths, with: .fade)
        } else {
            self.walletTableView.insertRows(at: indexPaths, with: .fade)
        }
    }
    
    func didPressAdd(sender: UIButton) {
        let section = sender.tag
        guard let wallet = self.twoDimensionalTokensArray[section].tokens.first?.inWallet else {
            self.alerts.showErrorAlert(for: self, error: "Can't select wallet", completion: nil)
            return
        }
        let searchTokenController = SearchTokenViewController(for: wallet)
        self.navigationController?.pushViewController(searchTokenController, animated: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        switch self.blockchainControl.selectedSegmentIndex {
        case Blockchain.ether.rawValue:
            return self.twoDimensionalTokensArray.count
        default:
            return self.twoDimensionalUTXOsArray.count
        }
    }
}

extension WalletViewController: UITableViewDelegate, UITableViewDataSource, TableHeaderDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let background: TableHeader
        switch self.blockchainControl.selectedSegmentIndex {
        case Blockchain.ether.rawValue:
            background = TableHeader(for: (self.twoDimensionalTokensArray[section].tokens.first?.inWallet)!, plasma: false, section: section)
        default:
            background = TableHeader(for: (self.twoDimensionalUTXOsArray[section].utxos.first?.inWallet)!, plasma: true, section: section)
        }
        background.delegate = self
        return background
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.rows.heights.tokens
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Constants.headers.heights.tokens
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.blockchainControl.selectedSegmentIndex {
        case Blockchain.ether.rawValue:
            if !self.twoDimensionalTokensArray[section].isExpanded {
                return 0
            }

            return self.twoDimensionalTokensArray[section].tokens.count
        default:
            if !self.twoDimensionalUTXOsArray[section].isExpanded {
                return 0
            }

            return self.twoDimensionalUTXOsArray[section].utxos.count
        }

    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch blockchainControl.selectedSegmentIndex {
        case Blockchain.ether.rawValue:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "TokenCell",
                                                           for: indexPath) as? TokenCell else {
                                                            return UITableViewCell()
            }
            cell.link = self
            let tableToken = self.twoDimensionalTokensArray[indexPath.section].tokens[indexPath.row]
            cell.configure(token: tableToken)
            return cell
        default:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "UTXOCell",
                                                           for: indexPath) as? UTXOCell else {
                                                            return UITableViewCell()
            }
            cell.link = self
            let tableUtxo = self.twoDimensionalUTXOsArray[indexPath.section].utxos[indexPath.row]
            cell.configure(utxo: tableUtxo)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        switch self.blockchainControl.selectedSegmentIndex {
        case Blockchain.ether.rawValue:
            guard let indexPathForSelectedRow = tableView.indexPathForSelectedRow else {
                return
            }
            let cell = tableView.cellForRow(at: indexPathForSelectedRow) as? TokenCell

            guard let selectedCell = cell else {
                return
            }

            guard let indexPathTapped = self.walletTableView.indexPath(for: selectedCell) else {
                return
            }

            let tableToken = self.twoDimensionalTokensArray[indexPathTapped.section].tokens[indexPathTapped.row]

            let tokenViewController = TokenViewController(token: tableToken.token)
            self.navigationController?.pushViewController(tokenViewController, animated: true)
            tableView.deselectRow(at: indexPath, animated: true)
        default:
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.deleteToken(in: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let plasmaBlockchain = self.blockchainControl.selectedSegmentIndex == Blockchain.plasma.rawValue
        if plasmaBlockchain {
            return false
        }
        return indexPath.row == 0 ? false : true
    }
}