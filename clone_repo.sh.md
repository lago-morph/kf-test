# Prompt

This is a reformatted version (by Claude) of the prompt used to create the shell script `clone_repo.sh`.

## Script Requirements: clone_repo.sh

### Purpose
Create a bash script that clones a Git repository from GitHub using SSH format.

### Script Name
`clone_repo.sh`

### Git URL Format
```
git@github.com:${GITHUB_ORGANIZATION}/${GITHUB_REPOSITORY}.git
```

### Clone Destination
- Base directory: `~/src/`
- Full path: `~/src/${GITHUB_REPOSITORY}`
- Example: If `GITHUB_REPOSITORY` is `some_name`, the cloned repository will be located at `~/src/some_name`

### Arguments

#### Required Arguments
- **REPOSITORY** (positional argument)
  - The name of the GitHub repository to clone
  - Must be provided as the first argument
  - Example: `clone_repo.sh my_repo`

#### Optional Arguments
- **--org ORGANIZATION**
  - Overrides the default GitHub organization
  - Example: `clone_repo.sh test_repo --org my_org`
  - This clones `git@github.com:my_org/test_repo`

### Default Values
- `GITHUB_ORGANIZATION`: Must have a default value defined in the script that is used when `--org` is not specified

### Error Handling
- Use strict error handling - script must exit with informative errors if any problems occur
- If invoked without required arguments, display an error message that includes:
  - Explanation of what went wrong
  - Example showing proper invocation with both mandatory and optional arguments
  - Proper usage format

### Examples

**With default organization:**
```bash
clone_repo.sh my_repo
```

**With custom organization:**
```bash
clone_repo.sh test_repo --org my_org
```

**Invalid invocation (no arguments):**
```bash
clone_repo.sh
# Should display error with usage examples
```

---

This reformatted version:
- Uses clear headings and hierarchy
- Separates different types of information (purpose, arguments, examples)
- Makes required vs optional arguments obvious
- Provides concrete examples in dedicated sections
- Uses formatting (bold, code blocks) to highlight important details
