import Foundation

public enum INC_LogEvent: String {
    case e = "[‼️]" // error
    case i = "[ℹ️]" // info
    case d = "[💬]" // debug
    case v = "[🔬]" // verbose
    case w = "[⚠️]" // warning
    case s = "[🔥]" // severe
}

func print(_ object: Any) {
    #if DEBUG
    Swift.print(object)
    #endif
}

open class INC_Log {

    static var dateFormat = "yyyy-MM-dd hh:mm:ssSSS"
    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        return formatter
    }

    private static var isLoggingEnabled: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    private static var _cacheQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .background
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    static var shouldCache = false {
        didSet {
            if shouldCache {
                let fileURL = _cacheURL
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    try? FileManager.default.removeItem(atPath: fileURL.path)
                }
            }
        }
    }

    static func cachedLog() -> String? {
        let fileURL = _cacheURL

        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = FileManager.default.contents(atPath: fileURL.path) else {
            return nil
        }

        return String(data: data, encoding: .utf8)

    }

    private static var _cacheURL: URL {
        URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory,
                                                                               .userDomainMask,
                                                                               true).first!).appendingPathComponent("WBWLog.txt")
    }

    private static func _save(_ message: String) {

        let fileURL = _cacheURL

        guard let data = message.data(using: .utf8) else {
            return
        }

        _cacheQueue.addOperation {
            autoreleasepool {
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                        fileHandle.closeFile()
                    }
                }else{
                    try? data.write(to: fileURL)
                }
            }
        }
    }

    private class func log(event: INC_LogEvent, _ object: Any, filename: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function) {
        guard isLoggingEnabled else {
            return
        }
        let message = "\(Date().toString()) \(event.rawValue)[\(sourceFileName(filePath: filename))]:\(line) \(column) \(funcName) -> \(object)"
        print(message)
        if shouldCache {
            _save("\n" + message)
        }
    }

    public class func e( _ object: Any, filename: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function) {
        log(event: .e, object, filename: filename, line: line, column: column, funcName: funcName)
    }

    public class func i ( _ object: Any, filename: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function) {
        log(event: .i, object, filename: filename, line: line, column: column, funcName: funcName)
    }

    public class func d( _ object: Any, filename: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function) {
        log(event: .d, object, filename: filename, line: line, column: column, funcName: funcName)
    }

    public class func v( _ object: Any, filename: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function) {
        log(event: .v, object, filename: filename, line: line, column: column, funcName: funcName)
    }

    public class func w( _ object: Any, filename: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function) {
        log(event: .w, object, filename: filename, line: line, column: column, funcName: funcName)
    }

    public class func s( _ object: Any, filename: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function) {
        log(event: .s, object, filename: filename, line: line, column: column, funcName: funcName)
    }

    private class func sourceFileName(filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return components.isEmpty ? "" : components.last!
    }
}

internal extension Date {
    func toString() -> String {
        return INC_Log.dateFormatter.string(from: self as Date)
    }
}
