# data

Raw data of URLs and hierchial information of Shaar Hayichud classes

Parse the data file, one line at a time, and create an app data file.
### Syntax
Everything following a section is in that section, until the next section of the
same level.

a # Starts a top level section.

a ## Starts a second level section.

a ### Starts a third level section.

The section title follows the section marker and a space.

Lines in a 2nd or 3rd level section are URL for particular classes.
A dash (-) marks the title for the class on the line which follows.
If a file doesn't have a name, it is simply Part 1 Part 2 etc, as per it's place
in the 3rd level section.

### Program Execution
1. Create Site object
2. Open file
3. Go through each line of the file
  * If its a #: Create a new section, mark it as being a top level section
    * Clear the saved current 2nd and 3rd level sections.
  * If its a ##: Add it to the last created top section.
    * Clear the saved current 2nd and 3rd level sections
  * If its a ###: Add it to the last created 2nd level section
    * Clear the saved current 3rd level section.
  * If its a >: Set the top level media base URL
  * If there's no starting marker on the line
    * If there's a current media being built, set it's URL, then clear the saved current.
    * If there isn't a current media being built, create one and set URL. The title is `'Part ${index + 1}'`
  * If its a dash (-): Create a new media, set the title.
