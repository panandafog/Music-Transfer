//
//  MTFileManager.swift
//  Music Transfer (iOS)
//
//  Created by Andrey on 08.05.2022.
//

import AppKit

enum MTFileManager {
    
    static func saveToFile(_ string: String, filename: String) {
        let homePath = FileManager.default.homeDirectoryForCurrentUser
        let desktopPath = homePath.appendingPathComponent("Desktop")
        let filePath = desktopPath.appendingPathComponent(filename)
        saveToFile(string, fileURL: filePath)
    }
    
    static func saveToFile(_ string: String, fileURL: URL) {
        do {
            try string.write(to: fileURL, atomically: false, encoding: .utf8)
        } catch {
            let errorMessage = error.localizedDescription + "\n" + string
            fatalError(errorMessage)
        }
    }
    
    static func saveLibraryURL() -> URL? {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.text]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.allowsOtherFileTypes = false
        savePanel.title = "Save library"
        savePanel.message = "Choose a folder and a name to store your library."
        savePanel.nameFieldLabel = "File name:"
        savePanel.nameFieldStringValue = "Library.txt"
        
        let response = savePanel.runModal()
        return response == .OK ? savePanel.url : nil
    }
}
