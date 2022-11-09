//
//  ViewController.swift
//  taskApp
//
//  Created by Masaharu Hoshino (Work) on 2022/11/06.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var categorySearchTextField: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    // Realmインスタンスを取得する
    let realm = try! Realm()
    
    // DB内のタスクが格納されるリスト
    // 日付の近い順でソート: 昇順
    // 以降内容をアップデートするとリスト内は自動的に更新される
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // データを表示していないTableViewに罫線を表示するコード（テーブルの表示範囲が分かるようにする）
        tableView.fillerRowHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    // データの数（＝セルの数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskArray.count
    }
    
    // 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能なセルを得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // セルに値を設定する
        let task = taskArray[indexPath.row]
        cell.textLabel?.text = task.title
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        let dateString: String = formatter.string(from: task.date)
        cell.detailTextLabel?.text = dateString
        
        return cell
    }

    //  各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue", sender: nil)
    }
    
    // セルが削除可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    // Deleteボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // 削除するタスクを取得する
            let task = self.taskArray[indexPath.row]
            
            // ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
            
            // データベースから削除する
            try! realm.write {
                self.realm.delete(self.taskArray[indexPath.row])
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            // 未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                for request in requests {
                    print("/---------------")
                    print(request)
                    print("---------------/")
                }
            }
        }
    }
    
    @IBAction func searchByCategory(_ sender: Any) {
        // 検索ボタン押下で、テキストフィールドに入力されたカテゴリでデータをフィルタリング
        self.taskArray = realm.objects(Task.self).filter("category == %@", self.categorySearchTextField.text!)
        
        if self.taskArray.count == 0 {  // 検索結果が0件の場合
            // プレースホルダーのテキストを3秒間だけ変更するためのタイマー作成、始動
            Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(placeholderTimer(_:)), userInfo: nil, repeats: false)
            // テキストフィールドのテキストを消す
            self.categorySearchTextField.text = ""
            // プレースホルダーのテキスト変更
            self.categorySearchTextField.attributedPlaceholder = NSAttributedString(string: "そんなカテゴリは無いです", attributes: [NSAttributedString.Key.foregroundColor: UIColor.red])
            
            // データを検索前の状態に戻す
            self.taskArray = realm.objects(Task.self).sorted(byKeyPath: "date", ascending: true)
        }
        // テーブルの再描画
        self.tableView.reloadData()
    }
    
    // プレースホルダーのテキストを元に戻す関数
    @objc func placeholderTimer(_ timer: Timer) {
        self.categorySearchTextField.attributedPlaceholder = NSAttributedString(string: "カテゴリーで検索", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
    }
    
    // segueで画面遷移する時に呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let inputViewcontroler:InputViewController = segue.destination as! InputViewController
        
        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewcontroler.task = taskArray[indexPath!.row]
        } else {
            let task = Task()
            
            let allTasks = realm.objects(Task.self)
            if allTasks.count != 0 {
                task.id = allTasks.max(ofProperty: "id")! + 1
            }
            
            inputViewcontroler.task = task
        }
    }
    
    // 入力画面から戻ってきた時にTableViewを更新させる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

}

