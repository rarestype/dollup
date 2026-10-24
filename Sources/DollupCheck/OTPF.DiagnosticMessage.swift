import SwiftDiagnostics

extension OTPF {
    struct DiagnosticMessage {
        let message: String
        let diagnosticID: MessageID
        let severity: DiagnosticSeverity

        init(_ message: String, id: String = "OTPF", severity: DiagnosticSeverity = .error) {
            self.message = message
            self.diagnosticID = .init(domain: "OTPF", id: id)
            self.severity = severity
        }
    }
}

extension OTPF.DiagnosticMessage: SwiftDiagnostics.DiagnosticMessage {}
