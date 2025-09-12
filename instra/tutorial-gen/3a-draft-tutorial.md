# draft a tutorial

Use the example commands and output in cli-workflow.md to generate a tutorial, with a section for each group of related commands, and sections on prerequisites and next steps. Include guidance before and after every code block, even if it's just one sentence. reference the content in golden-tutorial.md as an example of a good tutorial. If content in the prerequisites section of the golden tutorial applies to this tutorial, reuse it. Name the output file 3-tutorial-draft.md.

## links

The tutorial may be published in the service guide, so don't include any general links to the guide or documentation landing page. In the next steps section, link to a topic in the service guide for each feature or use case listed. The prerequisites section can also have links, but avoid adding links to the core sections of the tutorial where readers are following instructions. Links in these sections can pull the reader away from the tutorial unnecessarily. 

## formatting

Only use two levels of headers. H1 for the topic title, and H2 for the sections. To add a title to a code block or procedure, just use bold text.

Use sentence case for all headers and titles.
Use present tense and active voice as much as possible.

Don't add linebreaks in the middle of a paragraph. Keep all of the text in the paragraph on one line. Ensure that there is an empty line between all headers, paragraphs, example titles, and code blocks.

**List formatting:**
- Always use hyphens (-) for unordered lists, never asterisks (*) or bullet characters (•)
- Maintain consistent indentation for nested lists
- Example: `- First item` not `* First item` or `• First item`

For any relative path links, replace the './' with the full path that it represents.

## portability

Omit the --region option in example commands, unless it is required because by the specific use case or the service API. For example, if a command requires you to specify an availability zone, you need to ensure that you are calling the service in the same AWS Region as the availability zone. Otherwise, assume that the reader wants to create resources in the Region that they configured when they set up the AWS CLI, or write a script that they can run in any Region.

## naming rules

**account ids** - Replace 12 digit AWS account numbers with 123456789012. For examples with two account numbers, use 234567890123 for the second number. 

**GUIDs** - Obfuscate GUIDs by making the second character sequence in the guid "xmpl". 

**resource IDs** - For hex sequences, replace characters in the example with "abcd1234". For other numeric IDs, renumber starting with 1234. For alphanumric ID strings, replace characters 5-8 with "xmpl". 

**timestamps** - Replace timestamps with a value representing January 13th of the current year. 

**IP addresses** - Replace public IP addresses with fictitious addresses such as 203.0.113.75 or another address in the 203.0.113

**bucket names** - For S3 buckets, the name in the tutorial must start with "amzn-s3-demo". The script can't use this name because it's reserved for documentation. Leave the script as is but replace the prefix used by the script with "amzn-s3-demo" in the tutorial.