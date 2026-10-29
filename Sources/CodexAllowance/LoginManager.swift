import ServiceManagement

struct LoginManager {
    var status: SMAppService.Status { SMAppService.mainApp.status }

    func setEnabled(_ enabled: Bool) throws {
        if enabled { try SMAppService.mainApp.register() }
        else { try SMAppService.mainApp.unregister() }
    }

    func openSettings() { SMAppService.openSystemSettingsLoginItems() }
}
