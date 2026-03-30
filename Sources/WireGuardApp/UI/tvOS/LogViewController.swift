// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit

class LogViewController: UITableViewController {

    var logViewHelper: LogViewHelper?
    var isFetchingLogEntries = false
    private var updateLogEntriesTimer: Timer?

    let busyIndicator: UIActivityIndicatorView = {
        let busyIndicator = UIActivityIndicatorView(style: .medium)
        busyIndicator.hidesWhenStopped = true
        return busyIndicator
    }()

    var entries: [LogViewHelper.LogEntry] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(busyIndicator)
        busyIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            busyIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            busyIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        busyIndicator.startAnimating()

        logViewHelper = LogViewHelper(logFilePath: FileManager.logFileURL?.path)
        startUpdatingLogEntries()
    }

    override func loadView() {
        super.loadView()

        title = tr("logViewTitle")

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped(sender:)))
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = TextCell()
        cell.message = entries[indexPath.row].message
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        entries[section].timestamp
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
        //entries.count
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        entries.count
    }

    func updateLogEntries() {
        guard !isFetchingLogEntries else { return }
        isFetchingLogEntries = true
        logViewHelper?.fetchLogEntriesSinceLastFetch { [weak self] fetchedLogEntries in
            guard let self = self else { return }
            defer {
                self.isFetchingLogEntries = false
            }
            if self.busyIndicator.isAnimating {
                self.busyIndicator.stopAnimating()
            }
            guard !fetchedLogEntries.isEmpty else { return }

            entries.append(contentsOf: fetchedLogEntries)

            tableView.reloadData()
            // TODO: tableView.reloadRows(at: <#T##[IndexPath]#>, with: <#T##UITableView.RowAnimation#>)

            //let isScrolledToEnd = self.textView.contentSize.height - self.textView.bounds.height - self.textView.contentOffset.y < 1

            /*let richText = NSMutableAttributedString()
            let bodyFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)
            let captionFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.caption1)
            for logEntry in fetchedLogEntries {
                #if os(tvOS)
                let bgColor: UIColor = .clear
                #else
                let bgColor: UIColor = self.isNextLineHighlighted ? .systemGray3 : .systemBackground
                #endif
                let fgColor: UIColor = .label
                /*let timestampText = NSAttributedString(string: logEntry.timestamp + "\n", attributes: [.font: captionFont, .backgroundColor: bgColor, .foregroundColor: fgColor, .paragraphStyle: self.paragraphStyle])
                let messageText = NSAttributedString(string: logEntry.message + "\n", attributes: [.font: bodyFont, .backgroundColor: bgColor, .foregroundColor: fgColor, .paragraphStyle: self.paragraphStyle])
                richText.append(timestampText)
                richText.append(messageText)
                self.isNextLineHighlighted.toggle()*/
            }*/
            //self.textView.textStorage.append(richText)
            /*if isScrolledToEnd {
                let endOfCurrentText = NSRange(location: (self.textView.text as NSString).length, length: 0)
                self.textView.scrollRangeToVisible(endOfCurrentText)
            }*/
        }
    }

    func startUpdatingLogEntries() {
        updateLogEntries()
        updateLogEntriesTimer?.invalidate()
        let timer = Timer(timeInterval: 1 /* second */, repeats: true) { [weak self] _ in
            self?.updateLogEntries()
        }
        updateLogEntriesTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    @objc func saveTapped(sender: AnyObject) {
        fatalError("Not implemented")
    }
}
