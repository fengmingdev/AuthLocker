#if canImport(UIKit)
import UIKit
import AuthLockerCore

public final class LogsViewController: UITableViewController {
    private var items: [SecurityEvent] = []
    private let logger = SecurityLogger.shared
    private var offset = 0
    private let page = 50

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "安全日志"
        if #available(iOS 14.0, *) {
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "导出", style: .plain, target: self, action: #selector(onExport))
        loadMore()
    }

    private func loadMore() {
        let new = logger.query(limit: page, offset: offset)
        if new.isEmpty { return }
        let start = items.count
        items.append(contentsOf: new)
        offset += new.count
        var indexPaths: [IndexPath] = []
        for i in start..<items.count { indexPaths.append(IndexPath(row: i, section: 0)) }
        tableView.insertRows(at: indexPaths, with: .automatic)
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let e = items[indexPath.row]
        if #available(iOS 14.0, *) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            var content = UIListContentConfiguration.subtitleCell()
            content.text = e.kind.rawValue
            content.secondaryText = ISO8601DateFormatter().string(from: e.timestamp)
            cell.contentConfiguration = content
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
            cell.textLabel?.text = e.kind.rawValue
            cell.detailTextLabel?.text = ISO8601DateFormatter().string(from: e.timestamp)
            return cell
        }
    }

    public override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row >= items.count - 1 { loadMore() }
    }

    @objc private func onExport() {
        let alert = UIAlertController(title: "导出格式", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "JSON", style: .default) { _ in
            var sanitized: [SecurityEvent] = []
            for e in self.items { sanitized.append(SecurityEvent(kind: e.kind, timestamp: e.timestamp, details: nil)) }
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            var lines: [String] = []
            for e in sanitized {
                if let data = try? encoder.encode(e), let s = String(data: data, encoding: .utf8) { lines.append(s) }
            }
            let text = lines.joined(separator: "\n")
            let vc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
            self.present(vc, animated: true)
        })
        alert.addAction(UIAlertAction(title: "CSV", style: .default) { _ in
            let text = SecurityLogger.shared.exportCSV(limit: self.items.count, sanitize: true)
            let vc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
            self.present(vc, animated: true)
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
}
#endif
