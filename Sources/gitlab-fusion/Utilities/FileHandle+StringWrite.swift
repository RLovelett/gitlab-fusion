//
//  FileHandle+StringWrite.swift
//  gitlab-fusion
//
//  Created by Ryan Lovelett on 10/1/20.
//

import Foundation

extension FileHandle {
    func write(line string: String) {
        var copy = string.appending("\n")
        let data = copy.withUTF8(Data.init(buffer:))
        self.write(data)
    }
}
