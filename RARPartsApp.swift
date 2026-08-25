import Cocoa

final class DropView: NSView {
    var onDrop: ((URL) -> Void)?
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation { .copy }
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let url = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self])?.first as? URL,
              url.pathExtension.lowercased() == "rar" else { return false }
        onDrop?(url); return true
    }
    override func draw(_ dirtyRect: NSRect) {
        NSColor.controlAccentColor.withAlphaComponent(0.06).setFill()
        NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 16, yRadius: 16).fill()
        NSColor.separatorColor.setStroke()
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 16, yRadius: 16)
        path.setLineDash([7, 5], count: 2, phase: 0); path.stroke()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let fileLabel = NSTextField(labelWithString: "No archive selected")
    let destinationLabel = NSTextField(labelWithString: "Destination: beside archive")
    let status = NSTextField(labelWithString: "Drop the .part1.rar file here to begin")
    let extractButton = NSButton(title: "Extract Archive", target: nil, action: nil)
    var archive: URL?
    var destination: URL?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let content = NSView(frame: NSRect(x: 0, y: 0, width: 560, height: 390))
        let title = NSTextField(labelWithString: "Multipart RAR Extractor")
        title.font = .boldSystemFont(ofSize: 24)
        let subtitle = NSTextField(labelWithString: "Combine split RAR volumes into one folder")
        subtitle.textColor = .secondaryLabelColor
        let drop = DropView(frame: NSRect(x: 32, y: 145, width: 496, height: 150))
        drop.registerForDraggedTypes([.fileURL]); drop.onDrop = { [weak self] in self?.select($0) }
        let dropText = NSTextField(labelWithString: "Drop .part1.rar here")
        dropText.font = .systemFont(ofSize: 18, weight: .medium); dropText.alignment = .center
        dropText.frame = NSRect(x: 120, y: 205, width: 320, height: 25); drop.addSubview(dropText)
        fileLabel.frame = NSRect(x: 52, y: 165, width: 456, height: 22); fileLabel.alignment = .center; drop.addSubview(fileLabel)
        let choose = NSButton(title: "Choose File…", target: self, action: #selector(chooseFile)); choose.bezelStyle = .rounded
        choose.frame = NSRect(x: 32, y: 105, width: 125, height: 30)
        let chooseDest = NSButton(title: "Choose Destination…", target: self, action: #selector(chooseDestination)); chooseDest.bezelStyle = .rounded
        chooseDest.frame = NSRect(x: 168, y: 105, width: 170, height: 30)
        destinationLabel.frame = NSRect(x: 348, y: 108, width: 180, height: 22); destinationLabel.font = .systemFont(ofSize: 11); destinationLabel.textColor = .secondaryLabelColor
        extractButton.frame = NSRect(x: 32, y: 48, width: 496, height: 40); extractButton.bezelStyle = .rounded; extractButton.keyEquivalent = "\r"; extractButton.target = self; extractButton.action = #selector(extract)
        status.frame = NSRect(x: 32, y: 18, width: 496, height: 22); status.alignment = .center; status.textColor = .secondaryLabelColor
        [title, subtitle, drop, choose, chooseDest, destinationLabel, extractButton, status].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; content.addSubview($0) }
        title.translatesAutoresizingMaskIntoConstraints = false; subtitle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([title.topAnchor.constraint(equalTo: content.topAnchor, constant: 24), title.centerXAnchor.constraint(equalTo: content.centerXAnchor), subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 5), subtitle.centerXAnchor.constraint(equalTo: content.centerXAnchor), drop.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 32), drop.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -32), drop.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 18), drop.heightAnchor.constraint(equalToConstant: 150), extractButton.leadingAnchor.constraint(equalTo: drop.leadingAnchor), extractButton.trailingAnchor.constraint(equalTo: drop.trailingAnchor), extractButton.topAnchor.constraint(equalTo: drop.bottomAnchor, constant: 57), extractButton.heightAnchor.constraint(equalToConstant: 40), status.centerXAnchor.constraint(equalTo: content.centerXAnchor), status.topAnchor.constraint(equalTo: extractButton.bottomAnchor, constant: 7)])
        window = NSWindow(contentRect: content.frame, styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false); window.title = "RAR Parts"; window.contentView = content; window.center(); window.makeKeyAndOrderFront(nil)
    }
    func select(_ url: URL) { archive = url; fileLabel.stringValue = url.lastPathComponent; status.stringValue = "Ready — all consecutive parts will be combined" }
    @objc func chooseFile() { let p = NSOpenPanel(); p.allowedFileTypes = ["rar"]; p.allowsMultipleSelection = false; if p.runModal() == .OK, let u = p.url { select(u) } }
    @objc func chooseDestination() { let p = NSOpenPanel(); p.canChooseDirectories = true; p.canChooseFiles = false; if p.runModal() == .OK { destination = p.url; destinationLabel.stringValue = p.url?.lastPathComponent ?? "Custom destination" } }
    @objc func extract() { guard let archive else { status.stringValue = "Select the .part1.rar file first"; return }; extractButton.isEnabled = false; status.stringValue = "Extracting…"; let out = destination ?? archive.deletingLastPathComponent().appendingPathComponent(archive.deletingPathExtension().deletingPathExtension().lastPathComponent); DispatchQueue.global().async { let task = Process(); guard let bundledUnar = Bundle.main.url(forResource: "unar", withExtension: nil) else { DispatchQueue.main.async { self.extractButton.isEnabled = true; self.status.stringValue = "The bundled extraction engine is missing" }; return }; task.executableURL = bundledUnar; task.arguments = ["-output-directory", out.path, archive.path]; do { try task.run(); task.waitUntilExit(); DispatchQueue.main.async { self.extractButton.isEnabled = true; self.status.stringValue = task.terminationStatus == 0 ? "Done — extracted successfully" : "Extraction failed" } } catch { DispatchQueue.main.async { self.extractButton.isEnabled = true; self.status.stringValue = "Could not start the bundled extraction engine" } } } }
}

let app = NSApplication.shared
let delegate = AppDelegate(); app.delegate = delegate; app.setActivationPolicy(.regular); app.run()
