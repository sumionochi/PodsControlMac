//  DictationCommand.swift
import Foundation

struct DictationCommand: Identifiable, Codable, Equatable {
    let id: UUID
    var trigger: String      // what the user says
    var replacement: String  // what gets typed
    
    init(id: UUID = UUID(), trigger: String, replacement: String) {
        self.id = id
        self.trigger = trigger
        self.replacement = replacement
    }
}
