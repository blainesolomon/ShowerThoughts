//
//  ViewController.swift
//  ShowerThoughts
//
//  Created by Blaine Solomon on 3/18/18.
//  Copyright © 2018 Blaine Solomon. All rights reserved.
//

import UIKit

class MasterVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    override func viewDidLoad() {
        super.viewDidLoad()

        setupPreferences()
        setupLongPressGesture()
        setupPullToRefresh()
        loadShowerThoughtsFromReddit()
    }

    func setupPreferences() {
        isDarkMode = UserDefaults.standard.bool(forKey: DarkModeKey)
        tableView.indicatorStyle = isDarkMode ? .white : .black
        navigationController?.navigationBar.barStyle = isDarkMode ? .black : .default
        view.backgroundColor = isDarkMode ? .black : .white
    }

    func setupLongPressGesture() {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(MasterVC.userDidLongPressOnNavBar(sender:)))
        navigationController?.navigationBar.addGestureRecognizer(gesture)
    }

    func setupPullToRefresh() {
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(MasterVC.userDidPullToRefresh), for: .valueChanged)
        tableView.refreshControl?.beginRefreshing()
    }

    @objc func userDidPullToRefresh() {
        showerThoughts.removeAll()
        tableView.reloadData()
        loadShowerThoughtsFromReddit()
    }

    @objc func userDidLongPressOnNavBar(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            toggleTheme()
        }
    }

    @objc func toggleTheme() {
        isDarkMode = !isDarkMode

        tableView.indicatorStyle = isDarkMode ? .white : .black
        navigationController?.navigationBar.barStyle = isDarkMode ? .black : .default
        view.backgroundColor = isDarkMode ? .black : .white

        for cell in tableView.visibleCells {
            cell.textLabel?.textColor = isDarkMode ? .white : .black
        }

        UserDefaults.standard.set(isDarkMode, forKey: DarkModeKey)
    }

    // MARK - Table

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return showerThoughts.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item  = showerThoughts[indexPath.item]
        showShareSheet(item: item)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        cell.textLabel?.text = showerThoughts[indexPath.item]
        cell.textLabel?.textColor = self.isDarkMode ? .white : .black
        cell.backgroundColor = .clear

        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = UIColor.gray.withAlphaComponent(0.5)

        return cell
    }

    func showShareSheet(item: String) {
        let controller = UIActivityViewController(activityItems: [item], applicationActivities: nil)
        present(controller, animated: true, completion: nil)
    }

    // MARK - Setup

    func loadShowerThoughtsFromReddit() {
        let webURL = URL(string: "https://www.reddit.com/r/Showerthoughts/hot/.json?limit=100")
        let task = URLSession.shared.dataTask(with: webURL!, completionHandler: { data, response, error in

            guard let serverData = data else {
                return
            }

            do {
                guard let rootJSONDict = try JSONSerialization.jsonObject(with: serverData, options: []) as? [String: Any] else {
                    return
                }

                guard let dataDict = rootJSONDict["data"] as? [String: Any] else {
                    return
                }

                guard var childrenArray = dataDict["children"] as? [[String: Any]] else {
                    return
                }

                childrenArray.removeFirst() //First child is the subreddit description

                var titleCollection = [String]()

                for item in childrenArray {
                    if let itemDict = item["data"] as? [String: Any] {
                        if let title = itemDict["title"] as? String {
                            titleCollection.append(title)
                        }
                    }
                }

                OperationQueue.main.addOperation {
                    self.showerThoughts.removeAll()
                    self.showerThoughts.append(contentsOf: titleCollection)
                    self.tableView.refreshControl?.endRefreshing()
                    self.tableView.reloadData()
                }
            } catch {

            }
        })

        task.resume()
    }

    // MARK: - Properties

    var isDarkMode = false
    @IBOutlet weak var tableView: UITableView!
    var showerThoughts = [String]()

}

let DarkModeKey = "DarkModeKey"

