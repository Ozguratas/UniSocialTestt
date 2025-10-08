import Foundation

enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
}

struct Logger {
    static var isEnabled: Bool = true
    
    #if DEBUG
    static let isDebugMode = true
    #else
    static let isDebugMode = false
    #endif
    
    static func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        guard isEnabled && isDebugMode else { return }
        let fileName = (file as NSString).lastPathComponent
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        print("[\(timestamp)] [\(level.rawValue)] \(fileName):\(line)\n\(message)")
    }
    
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
}
