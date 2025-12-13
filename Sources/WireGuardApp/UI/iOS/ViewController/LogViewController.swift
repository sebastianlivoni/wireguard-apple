import UIKit

class LogViewController: UIViewController {

    let textView: UITextView = {
        let textView = UITextView()
        #if os(tvOS)
        textView.isUserInteractionEnabled = true
        textView.panGestureRecognizer.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        #else
        textView.isEditable = false
        #endif
        textView.isSelectable = true
        textView.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)
        textView.adjustsFontForContentSizeCategory = true
        return textView
    }()

    let busyIndicator: UIActivityIndicatorView = {
        let busyIndicator = UIActivityIndicatorView(style: .medium)
        busyIndicator.hidesWhenStopped = true
        return busyIndicator
    }()

    let paragraphStyle: NSParagraphStyle = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.setParagraphStyle(NSParagraphStyle.default)
        paragraphStyle.lineHeightMultiple = 1.2
        return paragraphStyle
    }()

    var isNextLineHighlighted = false

    var logViewHelper: LogViewHelper?
    var isFetchingLogEntries = false
    private var updateLogEntriesTimer: Timer?

    override func loadView() {
        view = UIView()
        #if !os(tvOS)
        view.backgroundColor = .systemBackground
        #endif
        view.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        view.addSubview(busyIndicator)
        busyIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            busyIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            busyIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        #if os(tvOS)
        if let navBar = navigationController?.navigationBar {
            navBar.isTranslucent = true
            navBar.setBackgroundImage(UIImage(), for: .default)
            navBar.shadowImage = UIImage()
            navBar.backgroundColor = .clear

            let blurEffect = UIBlurEffect(style: .regular)
            let blurView = UIVisualEffectView(effect: blurEffect)
            blurView.frame = navBar.bounds
            blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            navBar.insertSubview(blurView, at: 0)
            navBarBlurView = blurView
        }
        #endif

        busyIndicator.startAnimating()
        logViewHelper = LogViewHelper(logFilePath: FileManager.logFileURL?.path)
        startUpdatingLogEntries()
    }

    #if os(tvOS)
    private var navBarBlurView: UIVisualEffectView?

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        navBarBlurView?.removeFromSuperview()
        navBarBlurView = nil
    }
    #endif

    override func viewDidLoad() {
        title = tr("logViewTitle")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped(sender:)))
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
            let isScrolledToEnd = self.textView.contentSize.height - self.textView.bounds.height - self.textView.contentOffset.y < 1

            let richText = NSMutableAttributedString()
            let bodyFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)
            let captionFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.caption1)
            for logEntry in fetchedLogEntries {
                #if os(tvOS)
                let bgColor: UIColor = .clear
                #else
                let bgColor: UIColor = self.isNextLineHighlighted ? .systemGray3 : .systemBackground
                #endif
                let fgColor: UIColor = .label
                let timestampText = NSAttributedString(string: logEntry.timestamp + "\n", attributes: [.font: captionFont, .backgroundColor: bgColor, .foregroundColor: fgColor, .paragraphStyle: self.paragraphStyle])
                let messageText = NSAttributedString(string: logEntry.message + "\n", attributes: [.font: bodyFont, .backgroundColor: bgColor, .foregroundColor: fgColor, .paragraphStyle: self.paragraphStyle])
                richText.append(timestampText)
                richText.append(messageText)
                self.isNextLineHighlighted.toggle()
            }
            self.textView.textStorage.append(richText)
            if isScrolledToEnd {
                let endOfCurrentText = NSRange(location: (self.textView.text as NSString).length, length: 0)
                self.textView.scrollRangeToVisible(endOfCurrentText)
            }
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
        guard let destinationDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withTime, .withTimeZone] // Avoid ':' in the filename
        let timeStampString = dateFormatter.string(from: Date())
        let destinationURL = destinationDir.appendingPathComponent("wireguard-log-\(timeStampString).txt")

        DispatchQueue.global(qos: .userInitiated).async {

            if FileManager.default.fileExists(atPath: destinationURL.path) {
                let isDeleted = FileManager.deleteFile(at: destinationURL)
                if !isDeleted {
                    ErrorPresenter.showErrorAlert(title: tr("alertUnableToRemovePreviousLogTitle"), message: tr("alertUnableToRemovePreviousLogMessage"), from: self)
                    return
                }
            }

            let isWritten = Logger.global?.writeLog(to: destinationURL.path) ?? false

            DispatchQueue.main.async {
                guard isWritten else {
                    ErrorPresenter.showErrorAlert(title: tr("alertUnableToWriteLogTitle"), message: tr("alertUnableToWriteLogMessage"), from: self)
                    return
                }
                #if !os(tvOS)
                let activityVC = UIActivityViewController(activityItems: [destinationURL], applicationActivities: nil)
                if let sender = sender as? UIBarButtonItem {
                    activityVC.popoverPresentationController?.barButtonItem = sender
                }
                activityVC.completionWithItemsHandler = { _, _, _, _ in
                    // Remove the exported log file after the activity has completed
                    _ = FileManager.deleteFile(at: destinationURL)
                }
                self.present(activityVC, animated: true)
                #endif
            }
        }
    }
}
