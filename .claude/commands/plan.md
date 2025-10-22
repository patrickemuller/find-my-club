UNDERSTAND the code structure, the current features, and code style
THEN plan the implementation of the feature $ARGUMENTS
THEN create or update a markdown file with the name of the current branch inside the ".claude/tasks/" folder

A few things to considering during the planning:

- Reuse as much of the code as possible, even if you new classes should be created to encapsulate current behavior and features
- Plan simply, trying as much as possible to reduce code
- Don't worry about performance or security issues
- Plan simple code, and as less change to the current code as possible 
- For Ruby or Rails files, try as much as possible to use standard from the framework instead of using external gems
- For JavaScript code, always use Hotwire, Turbo, or StimulusJS code and standards
- Do not try to use caching mechanisms
- Do not try to optimize without necessity (put comments on top of the code that can be problematic in the format of "TODO: my comment")
- Do not make time estimates
- Do not make line created/updated/removed estimates
- Include at most 3 edge-cases at the bottom of the document
- Do not include "design" decisions
