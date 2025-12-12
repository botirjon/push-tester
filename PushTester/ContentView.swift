//
//  ContentView.swift
//  PushTester
//
//  Copyright (c) 2025 Botirjon Nasridinov
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var store = ConfigurationStore()
    @State private var editingConfig: PushConfiguration = .empty
    @State private var isSending = false
    @State private var responseMessage = ""
    @State private var showResponse = false
    @State private var isSuccess = false
    @State private var showDeleteConfirmation = false
    @State private var configToDelete: PushConfiguration?

    var body: some View {
        HSplitView {
            // Sidebar - Configuration List
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Configurations")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: addNewConfiguration) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderless)
                }
                .padding()

                Divider()

                List(selection: $store.selectedConfigurationId) {
                    ForEach(store.configurations) { config in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(config.name)
                                    .fontWeight(.medium)
                                Text(config.bundleId.isEmpty ? "No Bundle ID" : config.bundleId)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Circle()
                                .fill(config.isProduction ? Color.orange : Color.green)
                                .frame(width: 8, height: 8)
                        }
                        .tag(config.id)
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                configToDelete = config
                                showDeleteConfirmation = true
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
            .frame(minWidth: 200, maxWidth: 250)

            // Main Content
            VStack(spacing: 0) {
                if store.selectedConfiguration != nil {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            configurationSection
                            authKeySection
                            deviceSection
                            payloadSection
                            actionSection
                        }
                        .padding()
                    }
                } else {
                    VStack {
                        Image(systemName: "app.badge")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)
                        Text("No Configuration Selected")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Create or select a configuration to get started")
                            .foregroundColor(.secondary)
                        Button("Create New Configuration") {
                            addNewConfiguration()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 500)
        }
        .frame(minWidth: 700, minHeight: 600)
        .onChange(of: store.selectedConfigurationId) { _, _ in
            loadSelectedConfiguration()
        }
        .onAppear {
            loadSelectedConfiguration()
        }
        .alert("Delete Configuration", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let config = configToDelete {
                    store.deleteConfiguration(config)
                }
            }
        } message: {
            Text("Are you sure you want to delete this configuration?")
        }
        .sheet(isPresented: $showResponse) {
            ResponseView(message: responseMessage, isSuccess: isSuccess, isPresented: $showResponse)
        }
    }

    private var configurationSection: some View {
        GroupBox("Configuration") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Name:")
                        .frame(width: 100, alignment: .trailing)
                    TextField("Configuration Name", text: $editingConfig.name)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Text("Team ID:")
                        .frame(width: 100, alignment: .trailing)
                    TextField("e.g., J73PT963ZK", text: $editingConfig.teamId)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }

                HStack {
                    Text("Bundle ID:")
                        .frame(width: 100, alignment: .trailing)
                    TextField("e.g., com.example.app", text: $editingConfig.bundleId)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }

                HStack {
                    Text("Environment:")
                        .frame(width: 100, alignment: .trailing)
                    Picker("", selection: $editingConfig.isProduction) {
                        Text("Development (Sandbox)").tag(false)
                        Text("Production").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var authKeySection: some View {
        GroupBox("Authentication Key (.p8)") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Key ID:")
                        .frame(width: 100, alignment: .trailing)
                    TextField("e.g., BTGM53RX84", text: $editingConfig.authKeyId)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }

                HStack {
                    Text("Key File:")
                        .frame(width: 100, alignment: .trailing)
                    TextField("Select .p8 file...", text: $editingConfig.authKeyPath)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .disabled(true)
                    Button("Browse...") {
                        selectAuthKeyFile()
                    }
                }

                if !editingConfig.authKeyPath.isEmpty {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(URL(fileURLWithPath: editingConfig.authKeyPath).lastPathComponent)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var deviceSection: some View {
        GroupBox("Device") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Text("Token:")
                        .frame(width: 100, alignment: .trailing)
                        .padding(.top, 4)
                    TextField("Device Token (64 hex characters)", text: $editingConfig.deviceToken)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }

                if !editingConfig.deviceToken.isEmpty {
                    HStack {
                        Spacer()
                        let isValid = editingConfig.deviceToken.count == 64 &&
                            editingConfig.deviceToken.allSatisfy { $0.isHexDigit }
                        Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(isValid ? .green : .orange)
                        Text(isValid ? "Valid token format" : "Token should be 64 hex characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var payloadSection: some View {
        GroupBox("Push Payload (JSON)") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Spacer()
                    Button("Format JSON") {
                        formatPayload()
                    }
                    .buttonStyle(.borderless)

                    Button("Reset to Default") {
                        editingConfig.payload = PushConfiguration.defaultPayload
                    }
                    .buttonStyle(.borderless)
                }

                TextEditor(text: $editingConfig.payload)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 200)
                    .border(Color.gray.opacity(0.3), width: 1)

                if let error = validatePayload() {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var actionSection: some View {
        HStack {
            Button("Save Configuration") {
                saveConfiguration()
            }
            .buttonStyle(.bordered)

            Spacer()

            Button(action: sendPush) {
                HStack {
                    if isSending {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                    Text(isSending ? "Sending..." : "Send Push Notification")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSending || !isConfigValid)
        }
        .padding(.vertical)
    }

    private var isConfigValid: Bool {
        !editingConfig.teamId.isEmpty &&
        !editingConfig.bundleId.isEmpty &&
        !editingConfig.authKeyId.isEmpty &&
        !editingConfig.authKeyPath.isEmpty &&
        !editingConfig.deviceToken.isEmpty &&
        validatePayload() == nil
    }

    private func loadSelectedConfiguration() {
        if let config = store.selectedConfiguration {
            editingConfig = config
        }
    }

    private func addNewConfiguration() {
        var newConfig = PushConfiguration.empty
        newConfig.name = "Configuration \(store.configurations.count + 1)"
        store.addConfiguration(newConfig)
        editingConfig = newConfig
    }

    private func saveConfiguration() {
        store.selectedConfiguration = editingConfig
    }

    private func selectAuthKeyFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "p8") ?? .data]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            editingConfig.authKeyPath = url.path

            // Try to extract key ID from filename
            let filename = url.deletingPathExtension().lastPathComponent
            if filename.hasPrefix("AuthKey_") {
                let keyId = String(filename.dropFirst("AuthKey_".count))
                if editingConfig.authKeyId.isEmpty {
                    editingConfig.authKeyId = keyId
                }
            }
        }
    }

    private func formatPayload() {
        guard let data = editingConfig.payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let formatted = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
              let formattedString = String(data: formatted, encoding: .utf8) else {
            return
        }
        editingConfig.payload = formattedString
    }

    private func validatePayload() -> String? {
        guard let data = editingConfig.payload.data(using: .utf8) else {
            return "Invalid characters in payload"
        }

        do {
            _ = try JSONSerialization.jsonObject(with: data)
            return nil
        } catch {
            return "Invalid JSON: \(error.localizedDescription)"
        }
    }

    private func sendPush() {
        saveConfiguration()
        isSending = true

        Task {
            do {
                let response = try await APNsService.shared.sendPush(configuration: editingConfig)
                await MainActor.run {
                    isSending = false
                    isSuccess = response.success

                    if response.success {
                        responseMessage = "Push notification sent successfully!\n\nStatus: \(response.statusCode)"
                    } else {
                        var message = "Failed to send push notification\n\nStatus: \(response.statusCode)"
                        if !response.body.isEmpty {
                            if let data = response.body.data(using: .utf8),
                               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let reason = json["reason"] as? String {
                                message += "\nReason: \(reason)"
                            } else {
                                message += "\nResponse: \(response.body)"
                            }
                        }
                        responseMessage = message
                    }
                    showResponse = true
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    isSuccess = false
                    responseMessage = "Error: \(error.localizedDescription)"
                    showResponse = true
                }
            }
        }
    }
}

struct ResponseView: View {
    let message: String
    let isSuccess: Bool
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(isSuccess ? .green : .red)

            Text(isSuccess ? "Success" : "Failed")
                .font(.title)
                .fontWeight(.bold)

            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: 400)

            Button("OK") {
                isPresented = false
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .frame(minWidth: 300)
    }
}

#Preview {
    ContentView()
}
