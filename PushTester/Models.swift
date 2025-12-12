//
//  Models.swift
//  PushTester
//
//  Copyright (c) 2025 Botirjon Nasridinov
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation

struct PushConfiguration: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var teamId: String
    var bundleId: String
    var authKeyId: String
    var authKeyPath: String
    var isProduction: Bool
    var deviceToken: String
    var payload: String

    static var defaultPayload: String {
        """
        {
          "aps": {
            "alert": {
              "title": "Test Notification",
              "body": "This is a test push notification"
            },
            "sound": "default",
            "mutable-content": 1
          }
        }
        """
    }

    static var empty: PushConfiguration {
        PushConfiguration(
            name: "New Configuration",
            teamId: "",
            bundleId: "",
            authKeyId: "",
            authKeyPath: "",
            isProduction: false,
            deviceToken: "",
            payload: defaultPayload
        )
    }
}

class ConfigurationStore: ObservableObject {
    @Published var configurations: [PushConfiguration] = []
    @Published var selectedConfigurationId: UUID?

    private let saveKey = "PushTesterConfigurations"
    private let selectedKey = "PushTesterSelectedConfiguration"

    init() {
        load()
    }

    var selectedConfiguration: PushConfiguration? {
        get {
            configurations.first { $0.id == selectedConfigurationId }
        }
        set {
            if let newValue = newValue,
               let index = configurations.firstIndex(where: { $0.id == newValue.id }) {
                configurations[index] = newValue
                save()
            }
        }
    }

    func addConfiguration(_ config: PushConfiguration) {
        configurations.append(config)
        selectedConfigurationId = config.id
        save()
    }

    func deleteConfiguration(_ config: PushConfiguration) {
        configurations.removeAll { $0.id == config.id }
        if selectedConfigurationId == config.id {
            selectedConfigurationId = configurations.first?.id
        }
        save()
    }

    func save() {
        if let encoded = try? JSONEncoder().encode(configurations) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
        if let selectedId = selectedConfigurationId {
            UserDefaults.standard.set(selectedId.uuidString, forKey: selectedKey)
        }
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([PushConfiguration].self, from: data) {
            configurations = decoded
        }
        if let selectedIdString = UserDefaults.standard.string(forKey: selectedKey),
           let selectedId = UUID(uuidString: selectedIdString) {
            selectedConfigurationId = selectedId
        } else {
            selectedConfigurationId = configurations.first?.id
        }
    }
}
