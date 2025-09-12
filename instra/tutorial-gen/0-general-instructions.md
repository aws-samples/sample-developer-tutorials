# GENERAL INSTRUCTIONS

these instructions take a tutorial URL as input. get the URL from the user if they didn't provide one already.

you also need an identifier for this tutorial. prefix all filenames with the identifier. If the user didn't provide an identifier, use the name of the current directory.

if the output files for some or all steps already exist in the current directory, use these as input. Limit modifications to existing docs to changes that improve the functionality or guidance.

note the wall time when you start processing a prompt and when you return control to the user. show the actual time elapsed.

## ⚠️ REQUIRED REFERENCE MATERIALS ⚠️
When creating tutorials for specific AWS services:
1. CRITICAL FOR VPC CREATION:
   - Use the architecture defined in vpc-example.md as reference
   - This step is mandatory before creating any VPC resources
2. CRITICAL FOR MARKDOWN FORMATTING:
   - Follow the markdown-formatting-guide.md for consistent formatting
   - Always use hyphens (-) for lists, never asterisks (*) or bullet characters (•)
