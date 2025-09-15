# Markdown Formatting Guide

This guide ensures consistent markdown formatting across all tutorials to prevent rendering issues.

## List Formatting Rules

**REQUIRED:** Always use hyphens (-) for unordered lists
- ✅ Correct: `- First item`
- ❌ Incorrect: `* First item`
- ❌ Incorrect: `• First item`

**Consistency:** Use the same list marker throughout the entire document
- All lists in a single file must use hyphens (-)
- Never mix asterisks (*) and hyphens (-) in the same document
- Never use bullet characters (•) which are not standard markdown

## Whitespace Rules

**Trailing whitespace:** Remove all trailing whitespace from lines
- Use `sed -i 's/[[:space:]]*$//' filename.md` to clean up

**Line endings:** Use Unix line endings (LF) not Windows (CRLF)
- Use `sed -i 's/\r$//' filename.md` to convert if needed

## Validation Checklist

Before submitting any tutorial, verify:
- [ ] All lists use hyphens (-) consistently
- [ ] No bullet characters (•) are present
- [ ] No trailing whitespace on any lines
- [ ] Unix line endings are used
- [ ] Consistent indentation for nested lists
