// /////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
// This file is part of cithare                                                               //
// Copyright (C) 2023 Yves Ndiaye                                                             //
//                                                                                            //
// cithare is free software: you can redistribute it and/or modify it under the terms         //
// of the GNU General Public License as published by the Free Software Foundation,            //
// either version 3 of the License, or (at your option) any later version.                    //
//                                                                                            //
// cithare is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;       //
// without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR           //
// PURPOSE.  See the GNU General Public License for more details.                             //
// You should have received a copy of the GNU General Public License along with ciathare.     //
// If not, see <http://www.gnu.org/licenses/>.                                                //
//                                                                                            //
// /////////////////////////////////////////////////////////////////////////////////////////////

import Foundation
import ArgumentParser
#if os(macOS)
import Darwin
#else
import Glibc
#endif

struct Size: Equatable {
    public var line : Int
    public var column: Int
}

private var originalTermios: termios = .init()

private func saveTerminalOriginalState() {
    tcgetattr(STDIN_FILENO, &originalTermios)
}

private var restoreTermiosCallback: @convention(c) () -> Void = {
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &originalTermios)
}


private func registerRestoreTerm() {
    atexit( restoreTermiosCallback )
}

struct Terminal {
    public private(set) var started : Bool
    
    public static let NEW_SCREEN_BUFF_SEQ: String = "\u{001B}[?1049h\u{001B}[H"
    public static let END_SRCEEN_BUFF_SEQ: String = "\u{001B}[?1049l"
    public static let UPPER_LEFT_CORNER: String = "┌";
    public static let UPPER_RIGHT_CORNER: String = "┐";
    public static let LOWER_LEFT_CORNER: String = "└";
    public static let LOWER_RIGTH_CORNER: String = "┘";
    public static let HORIZONTAL_LINE: String = "─"; // "─" != '-'
    public static let VERTICAL_LINE: String = "│";
    
    public var width: Int = -1
    
    private var termiosNew: termios
    
    private var _width: Int {
        let column = size.column
        return min(column, max(width, 0))
    }
    
    
    /// Terminal size
    public var size: Size {
        var winsize: winsize = .init()
        _ = ioctl(STDIN_FILENO, TIOCGWINSZ, &winsize)
        return .init(line: Int(winsize.ws_row), column: Int( winsize.ws_col) )
    }
    
    
    init(width: Int?) {
        self.started = false
        self.termiosNew = .init()
        
        let column = size.column
        self.width = width.map { w in min(column, max(w, 0)) } ?? column
        
    }
    init() {
        self.init(width: nil)
    }
    
    private func flushOut(_ flush: Bool) {
        if flush { fflush(stdout) }
    }
    
    private mutating func enableRawMode() {
        saveTerminalOriginalState()
        registerRestoreTerm()
        self.termiosNew.c_lflag &= UInt(bitPattern: Int( ~(ECHO | ICANON | ISIG) ));
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &self.termiosNew)
    }
    
    private mutating func disableRawMode() {
        restoreTermiosCallback()
    }
    
    private mutating func startWindowedSession(rawMode: Bool = true) {
        if rawMode {
            enableRawMode()
        }
        write(STDOUT_FILENO, Self.NEW_SCREEN_BUFF_SEQ, Self.NEW_SCREEN_BUFF_SEQ.count)
    }
    
    private mutating func endWindowedSession() {
        write(STDOUT_FILENO, Self.END_SRCEEN_BUFF_SEQ, Self.END_SRCEEN_BUFF_SEQ.count)
        disableRawMode()
    }
    
    private func drawHorizotalChar(_ flush: Bool = true) {
        drawString(Self.HORIZONTAL_LINE, flush: flush)
    }
    
    private func drawFullHorizonalLine() {
        drawString(Self.VERTICAL_LINE, flush: false)
        for _ in 0 ..< (width - 2) {
            drawString(Self.HORIZONTAL_LINE, flush: false)
        }
        drawString(Self.VERTICAL_LINE, flush: false)
        flushOut(true)
    }
    
    private func drawFirstLine(title: String = "") {
        drawString(Self.UPPER_LEFT_CORNER, flush: false)
        for n in 0..<(self.width - 1) {
            let currentCharIndex = n
            
            if currentCharIndex < title.count {
                let currentChar = title.utf8CString[currentCharIndex]
                drawChar( currentChar , flush: false )
            } else {
                drawHorizotalChar(false)
            }
        }
        drawString(Self.UPPER_RIGHT_CORNER, flush: true)
    }
    
    mutating func startWindow() {
        guard !started else { return }
        started = true
        startWindowedSession()
    }
    
    mutating func endWindow() {
        guard started else { return }
        started = false
        endWindowedSession()
    }
    
    func setCursorAt(line: Int, column: Int, flush: Bool = true) {
        guard started else { return }
        print("\u{001B}[\(line);\(column)f", terminator: "")
        flushOut(flush)
    }
    
    func nextLine(currentLine: Int, flush: Bool = true) {
        setCursorAt(line: currentLine + 1, column: 0, flush: flush)
    }
    
    func drawString(_ s: String, flush: Bool = true) {
        guard started else { return }
        print("\(s)", terminator: "")
        flushOut(flush)
    }
    
    func drawChar(_ c: CChar, flush: Bool = true) {
        putc(Int32(c), stdout)
        flushOut(flush)
    }
    
    func redrawEmpty() {
        guard started else { return }
        
        setCursorAt(line: 0, column: 0, flush: true)
        let size = size
        for _ in 0..<(size.line * self.width) {
            drawString(" ", flush: false)
        }
        setCursorAt(line: 0, column: 0)
        flushOut(true)
    }
    
    func drawItem(items: [String], startAt: Int = 0, title: String = "") {
        guard started else { return }
        let elementCount = items.count
        self.redrawEmpty()
        var currentLine = 0
        if startAt == 0 {
            currentLine = 1
            drawFirstLine(title: title)
            nextLine(currentLine: currentLine)
        }
        // currentLine points to the next line to draw: Therefore, this line is empty
        let numberOfDrawLine = min( items.count - startAt, (size.line - currentLine) / 2 )
        for n in 0..<numberOfDrawLine {
            let effectiveIndex = (n + startAt) % elementCount
            let currentStringLine = items[effectiveIndex]
            drawString(currentStringLine)
            nextLine(currentLine: currentLine)
            currentLine += 1
            drawFullHorizonalLine()
            nextLine(currentLine: currentLine)
            currentLine += 1
        }
    }
}
