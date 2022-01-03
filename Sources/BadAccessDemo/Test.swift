//
//  Test.swift
//
//  Created by Stefan Springer on 03.01.22.
//

import Foundation
import SwiftXMLC

// !!! adjust those paths before runningn (the samples are top-level of the package): !!!
//let files = [URL(fileURLWithPath: "/Users/stefan/Projekte/BadAccessDemo/lineitem-small.xml")] // works
let files = [URL(fileURLWithPath: "/Users/stefan/Projekte/BadAccessDemo/lineitem.xml")] // does not work

enum MyError: Error {
    case runtimeError(String)
}

func processFile(file: URL) async throws {
    _ = try parseXML(fromPath: file.path)
    
    // simpler call chain, seems to work (but not if some delegates are added as arguments as is needed in the real case):
    /*let document = XDocument()
    let parser = XParser()
    let data: Data = try Data(contentsOf: URL(fileURLWithPath: file.path))
    try parser.parse(fromData: data, eventHandlers: [])*/
}

class Items {
    
    var count = 0
    
    var files: [URL]
    
    init(_ files: [URL]) {
        self.files = files
    }
    
    var next: URL? {
        if count < files.count {
            count += 1
            return files[count-1]
        }
        else {
            return nil
        }
    }
}

@main
struct Test {
    
    static func main() async throws {
        
        print("------- 1: OK")
        
        let run1 = Items(files)

        if #available(macOS 10.15, *) {
            await withTaskGroup(of: Void.self) { group in
                if let file = run1.next { // taking only one file for simplicity of the demo code
                    print("processing \(file.path)...")
                    do {
                        try await processFile(file: file)
                    }
                    catch {
                        print("ERROR: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            print("wrong OS version")
        }
        
        print("press return...")
        _ = readLine()
        print("continuing...")
        
        print("------- 2: Thread 2: EXC_BAD_ACCESS (code=2, address=...)")
        
        let run2 = Items(files)

        if #available(macOS 10.15, *) {
            await withTaskGroup(of: Void.self) { group in
                if let file = run2.next { // taking only one file for simplicity of the demo code
                    print("processing \(file.path)...")
                    group.addTask {
                        do {
                            try await processFile(file: file)
                        }
                        catch {
                            print("ERROR: \(error.localizedDescription)")
                        }
                    }
                }
            }
        } else {
            print("wrong OS version")
        }
        
        print("press return...")
        _ = readLine()
        print("continuing...")
        
        print("------- 3: how it is supposed to run (also EXC_BAD_ACCESS)")
        
        let run3 = Items(files)
        
        let workload = 4
        let realWorkload = min(workload,files.count)
        if #available(macOS 10.15, *) {
            await withTaskGroup(of: Void.self) { group in
                
                @Sendable func call(_ file: URL) async {
                    do {
                        try await processFile(file: file)
                    }
                    catch {
                        print("ERROR: \(error.localizedDescription)")
                    }
                }
                
                func callNext() {
                    if let nextFile = run3.next {
                        group.addTask {
                            await call(nextFile)
                        }
                    }
                }
                
                for _ in 0..<realWorkload {
                    callNext()
                }
                
                // for every finished work item, create a new one:
                for await _ in group {
                    callNext()
                }
            }
        } else {
            print("wrong OS version")
        }

        print("DONE.")
        
    }
}
