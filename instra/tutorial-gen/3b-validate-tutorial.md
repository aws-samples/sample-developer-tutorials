# validate tutorial

Validating the content of the AWS CLI tutorial and surface issues about the generated content.
## formatting and style

Review the tutorial markdown for proper formatting:

**List formatting:**
- Verify all unordered lists use hyphens (-) consistently, never asterisks (*) or bullet characters (•)
- Check for consistent indentation in nested lists
- Flag any mixed list marker usage within the same document

**Backticks usage:**
- Use backticks for all inline code, commands, file paths, resource IDs, status values, and technical terms
- Examples: `aws s3 ls`, `my-bucket-name`, `ACTIVE`, `~/path/to/file`, `us-east-1`
- Never use double quotes around backticked content (avoid `"~/file"`, use `~/file`)

**Tilde usage:**
- Use tildes (`~`) only in code blocks to represent home directory paths
- Replace tildes meaning "approximately" with the word "approximately" 
- Examples: "approximately $0.50/hour" not "~$0.50/hour"

**Quotes usage:**
- Avoid double quotes around technical terms, file names, or commands in descriptive text
- Use backticks instead: `filename.txt` not "filename.txt"
- Keep quotes only for actual quoted speech or JSON string values in code blocks

Document any formatting issues in 3-formatting.md.

## deprecated features

Generate a list of service features used in the tutorial. Store this list in 3-features.md, with the name of the service above the list. If there are multiple services used, include a separate list for each service.

Check the documentation for each feature and determine when the feature was released, when it was last updated, and whether it is deprecated. A feature can be marked deprecated, legacy, or not recommended in the feature guidance, API reference, or doc history topic. Each service guide has a doc history topic that has entries for service releases that had documentation updates. Some are more extensive than others. If you can't find all of the information for every feature that's ok. If a feature is deprecated, legacy, or not recommend, figure out which feature to use instead. There should be guidance on how to migrate from the old feature to the new one.

Capture all of this information in a CSV file named 3-features.csv with an entry for each feature and columns for service_name, feature_name, release_date, last_up_dated, deprecated_bool, replaced_by. For any deprecated features included in the tutorial, capture this information in an error report in 3-errors.md. Each error should have a separate entry with a header indicating the issue, a description, and links to relevant documentation.

## expensive resources

Check the pricing page for the service to determine the cost of running all of the resources created in the tutorial for one hour. Note the cost of each feature and the total cost for the tutorial in 3-cost.md. 

## unsecured resources

Check the tutorial for security risks, such as too permissive resource-based policies, or wildcard use in permission scopes. Note any issues in 3-security.md.

## architecture best practices

Check the tutorial for issues from an application architecure standpoint. Consider the AWS Well-Architeced framework, noting issues that would prevent the solution described from scaling. Note any issues in 3-architecture.md.

## improvements over baseline

Review the baseline tutorial for errors and omissions that were fixed by following the authoring instructions, or caught by validation. Note any issues in 3-baseline.md.
