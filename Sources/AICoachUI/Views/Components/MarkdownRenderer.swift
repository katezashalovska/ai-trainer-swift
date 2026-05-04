import SwiftUI

// MARK: - Block Types

/// Represents a parsed block-level Markdown element.
private enum MarkdownBlock {
    case heading(level: Int, content: String)
    case paragraph(content: String)
    case thematicBreak
    case unorderedListItem(content: String, indent: Int)
    case orderedListItem(number: String, content: String, indent: Int)
    case blockquote(content: String)
    case codeBlock(content: String)
    case table(headers: [String], rows: [[String]])
}

// MARK: - MarkdownRenderer View

/// A zero-dependency Markdown renderer that converts a Markdown string into
/// native SwiftUI views. Supports headings, tables, lists, blockquotes,
/// code blocks, thematic breaks, and inline styles (bold, italic, code, links).
///
/// Inline styles are handled by `AttributedString(markdown:)` so all
/// CommonMark inline syntax is supported without custom parsing.
struct MarkdownRenderer: View {
    let content: String
    @Environment(\.aiCoachTheme) private var theme

    var body: some View {
        let blocks = Self.parseBlocks(from: content)
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                renderBlock(block)
            }
        }
    }

    // MARK: - Block Rendering

    @ViewBuilder
    private func renderBlock(_ block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let content):
            renderHeading(level: level, content: content)
        case .paragraph(let content):
            renderParagraph(content)
        case .thematicBreak:
            Divider()
                .overlay(theme.borderColor)
                .padding(.vertical, 6)
        case .unorderedListItem(let content, let indent):
            renderUnorderedListItem(content: content, indent: indent)
        case .orderedListItem(let number, let content, let indent):
            renderOrderedListItem(number: number, content: content, indent: indent)
        case .blockquote(let content):
            renderBlockquote(content)
        case .codeBlock(let content):
            renderCodeBlock(content)
        case .table(let headers, let rows):
            renderTable(headers: headers, rows: rows)
        }
    }

    // MARK: - Heading

    private func renderHeading(level: Int, content: String) -> some View {
        let (size, weight): (CGFloat, Font.Weight) = {
            switch level {
            case 1:  return (22, .bold)
            case 2:  return (19, .bold)
            case 3:  return (17, .semibold)
            case 4:  return (16, .semibold)
            case 5:  return (15, .semibold)
            default: return (14, .medium)
            }
        }()

        return inlineMarkdown(content)
            .font(.system(size: size, weight: weight))
            .foregroundStyle(level <= 5 ? theme.textColor : theme.secondaryTextColor)
            .padding(.top, level <= 2 ? 8 : 4)
            .padding(.bottom, 2)
    }

    // MARK: - Paragraph

    private func renderParagraph(_ content: String) -> some View {
        inlineMarkdown(content)
            .font(.system(size: 16))
            .foregroundStyle(theme.textColor)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 2)
    }

    // MARK: - Lists

    private func renderUnorderedListItem(content: String, indent: Int) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(theme.textColor)

            inlineMarkdown(content)
                .font(.system(size: 16))
                .foregroundStyle(theme.textColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, CGFloat(indent))
        .padding(.vertical, 1)
    }

    private func renderOrderedListItem(number: String, content: String, indent: Int) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Text("\(number).")
                .font(.system(size: 16))
                .foregroundStyle(theme.secondaryTextColor)
                .frame(minWidth: 20, alignment: .trailing)

            inlineMarkdown(content)
                .font(.system(size: 16))
                .foregroundStyle(theme.textColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, CGFloat(indent))
        .padding(.vertical, 1)
    }

    // MARK: - Blockquote

    private func renderBlockquote(_ content: String) -> some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(theme.primaryColor.opacity(0.6))
                .frame(width: 3)

            inlineMarkdown(content)
                .font(.system(size: 16))
                .italic()
                .foregroundStyle(theme.secondaryTextColor)
                .padding(.leading, 10)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Code Block

    private func renderCodeBlock(_ content: String) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(content)
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(theme.textColor)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.secondaryBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.vertical, 4)
    }

    // MARK: - Table

    @ViewBuilder
    private func renderTable(headers: [String], rows: [[String]]) -> some View {
        let columnCount = headers.count

        ScrollView(.horizontal, showsIndicators: false) {
            Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
                // Header row
                GridRow {
                    ForEach(0..<columnCount, id: \.self) { col in
                        inlineMarkdown(headers[col])
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(theme.textColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .background(theme.secondaryBackgroundColor.opacity(0.8))

                Divider().overlay(theme.borderColor)
                    .gridCellUnsizedAxes(.horizontal)

                // Data rows
                ForEach(0..<rows.count, id: \.self) { rowIndex in
                    GridRow {
                        ForEach(0..<columnCount, id: \.self) { col in
                            let cellContent = col < rows[rowIndex].count ? rows[rowIndex][col] : ""
                            inlineMarkdown(cellContent)
                                .font(.system(size: 13))
                                .foregroundStyle(theme.textColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .background(
                        rowIndex.isMultiple(of: 2)
                            ? Color.clear
                            : theme.secondaryBackgroundColor.opacity(0.35)
                    )

                    if rowIndex < rows.count - 1 {
                        Divider().overlay(theme.borderColor.opacity(0.5))
                            .gridCellUnsizedAxes(.horizontal)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(theme.borderColor, lineWidth: 0.5)
            )
        }
        .padding(.vertical, 4)
    }

    // MARK: - Inline Markdown (bold, italic, code, links, strikethrough)

    /// Uses Apple's built-in `AttributedString(markdown:)` for inline syntax.
    private func inlineMarkdown(_ text: String) -> Text {
        guard let attr = try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) else {
            return Text(text)
        }
        return Text(attr)
    }
}

// MARK: - Block Parser

extension MarkdownRenderer {

    /// Parses a Markdown string into an array of block-level elements.
    fileprivate static func parseBlocks(from text: String) -> [MarkdownBlock] {
        let lines = text.components(separatedBy: "\n")
        var blocks: [MarkdownBlock] = []
        var index = 0

        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Empty line — skip
            if trimmed.isEmpty {
                index += 1
                continue
            }

            // Code block (fenced with ```)
            if trimmed.hasPrefix("```") {
                var codeLines: [String] = []
                index += 1
                while index < lines.count {
                    let codeLine = lines[index]
                    if codeLine.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                        index += 1
                        break
                    }
                    codeLines.append(codeLine)
                    index += 1
                }
                blocks.append(.codeBlock(content: codeLines.joined(separator: "\n")))
                continue
            }

            // Heading (# ... ######)
            if let heading = parseHeading(trimmed) {
                blocks.append(heading)
                index += 1
                continue
            }

            // Thematic break (---, ***, ___)
            if isThematicBreak(trimmed) {
                blocks.append(.thematicBreak)
                index += 1
                continue
            }

            // Table: current line has pipes AND next line is a separator
            if isTableRow(trimmed),
               index + 1 < lines.count,
               isTableSeparator(lines[index + 1].trimmingCharacters(in: .whitespaces)) {
                let headers = splitTableCells(trimmed)
                index += 2 // skip header + separator
                var rows: [[String]] = []
                while index < lines.count {
                    let rowLine = lines[index].trimmingCharacters(in: .whitespaces)
                    guard isTableRow(rowLine) else { break }
                    rows.append(splitTableCells(rowLine))
                    index += 1
                }
                blocks.append(.table(headers: headers, rows: rows))
                continue
            }

            // Blockquote
            if trimmed.hasPrefix("> ") || trimmed == ">" {
                let content = trimmed.hasPrefix("> ") ? String(trimmed.dropFirst(2)) : ""
                blocks.append(.blockquote(content: content))
                index += 1
                continue
            }

            // Unordered list item (- , * , + )
            if let item = parseUnorderedListItem(line) {
                blocks.append(.unorderedListItem(content: item.content, indent: item.indent))
                index += 1
                continue
            }

            // Ordered list item (1. , 2. , etc.)
            if let item = parseOrderedListItem(line) {
                blocks.append(.orderedListItem(number: item.number, content: item.content, indent: item.indent))
                index += 1
                continue
            }

            // Paragraph — collect consecutive non-special lines
            var paragraphLines: [String] = [trimmed]
            index += 1
            while index < lines.count {
                let nextLine = lines[index]
                let nextTrimmed = nextLine.trimmingCharacters(in: .whitespaces)
                if nextTrimmed.isEmpty
                    || nextTrimmed.hasPrefix("```")
                    || parseHeading(nextTrimmed) != nil
                    || isThematicBreak(nextTrimmed)
                    || (isTableRow(nextTrimmed) && index + 1 < lines.count && isTableSeparator(lines[index + 1].trimmingCharacters(in: .whitespaces)))
                    || nextTrimmed.hasPrefix("> ")
                    || nextTrimmed == ">"
                    || parseUnorderedListItem(nextLine) != nil
                    || parseOrderedListItem(nextLine) != nil {
                    break
                }
                paragraphLines.append(nextTrimmed)
                index += 1
            }
            blocks.append(.paragraph(content: paragraphLines.joined(separator: " ")))
        }

        return blocks
    }

    // MARK: - Line Classifiers

    private static func parseHeading(_ line: String) -> MarkdownBlock? {
        var level = 0
        for char in line {
            if char == "#" { level += 1 } else { break }
        }
        guard level >= 1, level <= 6, line.count > level, line[line.index(line.startIndex, offsetBy: level)] == " " else {
            return nil
        }
        let content = String(line.dropFirst(level + 1))
        return .heading(level: level, content: content)
    }

    private static func isThematicBreak(_ line: String) -> Bool {
        let stripped = line.replacingOccurrences(of: " ", with: "")
        guard stripped.count >= 3 else { return false }
        let chars = Set(stripped)
        return chars.count == 1 && (chars.contains("-") || chars.contains("*") || chars.contains("_"))
    }

    private static func isTableRow(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("|") && trimmed.hasSuffix("|") && trimmed.count >= 3
    }

    private static func isTableSeparator(_ line: String) -> Bool {
        guard isTableRow(line) else { return false }
        let cells = splitTableCells(line)
        guard !cells.isEmpty else { return false }
        return cells.allSatisfy { cell in
            let c = cell.trimmingCharacters(in: .whitespaces)
            return !c.isEmpty && c.contains("-") && c.allSatisfy { $0 == "-" || $0 == ":" || $0 == " " }
        }
    }

    private static func splitTableCells(_ line: String) -> [String] {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        // Remove leading/trailing pipe, then split
        var inner = trimmed
        if inner.hasPrefix("|") { inner = String(inner.dropFirst()) }
        if inner.hasSuffix("|") { inner = String(inner.dropLast()) }
        return inner.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private static func parseUnorderedListItem(_ line: String) -> (content: String, indent: Int)? {
        let indent = line.prefix(while: { $0 == " " }).count
        let trimmed = String(line.dropFirst(indent))
        for marker in ["- ", "* ", "+ "] {
            if trimmed.hasPrefix(marker) {
                return (String(trimmed.dropFirst(marker.count)), indent)
            }
        }
        return nil
    }

    private static func parseOrderedListItem(_ line: String) -> (number: String, content: String, indent: Int)? {
        let indent = line.prefix(while: { $0 == " " }).count
        let trimmed = String(line.dropFirst(indent))
        guard let dotIndex = trimmed.firstIndex(of: "."), dotIndex != trimmed.startIndex else { return nil }
        let numberStr = String(trimmed[..<dotIndex])
        guard numberStr.allSatisfy(\.isNumber) else { return nil }
        let afterDot = trimmed.index(after: dotIndex)
        guard afterDot < trimmed.endIndex, trimmed[afterDot] == " " else { return nil }
        let content = String(trimmed[trimmed.index(after: afterDot)...])
        return (numberStr, content, indent)
    }
}
