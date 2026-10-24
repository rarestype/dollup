import SwiftDiagnostics

extension OneTypePerFile {
    struct DiagnosticMessage {
        let message: String
        let diagnosticID: MessageID
        let severity: DiagnosticSeverity

        init(_ message: String, id: String = "OTPF", severity: DiagnosticSeverity = .error) {
            self.message = message
            self.diagnosticID = .init(domain: "OneTypePerFile", id: id)
            self.severity = severity
        }
    }
}
extension OneTypePerFile.DiagnosticMessage: SwiftDiagnostics.DiagnosticMessage {}
