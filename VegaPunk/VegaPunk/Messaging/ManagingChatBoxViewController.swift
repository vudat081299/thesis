//
//  ManagingChatBoxViewController.swift
//  VegaPunk
//
//  Created by Dat Vu on 05/03/2023.
//

import UIKit

class ManagingChatBoxViewController: UIViewController {
    
    /// at index 0: is members in current chatBox, index 1: is users who not in chatBox
    var users = Array(repeating: [User](), count: 2)
    var chatBoxId = UUID()

    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configureHierarchy()
        title = "Quản lý phòng chat"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    // MARK: - APIs
    func add(member user: User, into chatBoxId: UUID) {
        RequestEngine.add(member: user.id!, into: chatBoxId, completion: { [self] in
            DispatchQueue.main.async { [self] in
                users[0].append(user)
                users[1].removeAll { $0 == user }
                tableView.reloadData()
            }
            update()
        })
    }
    func delete(member user: User, from chatBoxId: UUID) {
        RequestEngine.delete(member: user.id!, from: chatBoxId, completion: { [self] in
            DispatchQueue.main.async { [self] in
                users[0].removeAll { $0 == user }
                users[1].append(user)
                tableView.reloadData()
            }
            update()
        })
    }
    func update() {
        RequestEngine.getAllMappingPivots()
    }
}

extension ManagingChatBoxViewController: UITableViewDelegate, UITableViewDataSource {
    private func configureHierarchy() {
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: ChatBoxMemberTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: ChatBoxMemberTableViewCell.reuseIdentifier)
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 18
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        if users[1].count == 0 {
            return 1
        }
        return 2
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users[section].count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatBoxMemberTableViewCell.reuseIdentifier, for: indexPath) as! ChatBoxMemberTableViewCell
        let row = indexPath.row
        let sec = indexPath.section
        cell.prepare(with: users[sec][row])
        return cell
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Thành viên"
        }
        return "Người dùng khác"
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = indexPath.row
        let sec = indexPath.section
        let user = users[sec][row]
        if sec == 0 {
            let alert = UIAlertController(title: "Xoá thành viên", message: "Bạn có muốn xoá \(user.name!) khỏi nhóm chat?", preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Huỷ", style: .default, handler: nil)
            let delete = UIAlertAction(title: "Xoá", style: .destructive) { [self] _ in
                self.delete(member: user, from: chatBoxId)
            }
            alert.addAction(cancel)
            alert.addAction(delete)
            alert.preferredAction = cancel
            self.present(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Thêm thành viên", message: "Bạn có muốn thêm \(user.name!) vào nhóm chat?", preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Huỷ", style: .default, handler: nil)
            let add = UIAlertAction(title: "Thêm", style: .destructive) { [self] _ in
                self.add(member: user, into: chatBoxId)
            }
            alert.addAction(cancel)
            alert.addAction(add)
            alert.preferredAction = cancel
            self.present(alert, animated: true, completion: nil)
        }
    }
}
