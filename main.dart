import 'dart:convert';
import 'dart:io';

import 'package:inside_api/models.dart';
import 'package:inside_api/site.dart';

final idGenerator = IDGenerator();
const urlBase = 'http://d35zpkccrlbazl.cloudfront.net';

final site = Site();
Section currentTopSection;
Section currentSection;
MediaSection currentMediaSection;
Media currentMedia;
String currentTopUrlPart;

/// Parse the data file, one line at a time, and create an app data file.
/// ### Syntax
/// Everything following a section is in that section, until the next section of the
/// same level.
///
/// a # Starts a top level section.
///
/// a ## Starts a second level section.
///
/// a ### Starts a third level section.
///
/// The section title follows the section marker and a space.
/// The line after a second level ## section is the base URL for all content of that section.
///
/// Lines in a 2nd or 3rd level section are URL for particular classes.
/// A dash (-) marks the title for the class on the line which follows.
/// If a file doesn't have a name, it is simply Part 1 Part 2 etc, as per it's place
/// in the 3rd level section.
///
/// ### Program Execution
/// 1. Create Site object
/// 2. Open file
/// 3. Go through each line of the file
///   * If its a #: Create a new section, mark it as being a top level section
///     * Clear the saved current 2nd and 3rd level sections.
///   * If its a ##: Add it to the last created top section.
///     * Clear the saved current 2nd and 3rd level sections
///   * If its a ###: Add it to the last created 2nd level section
///     * Clear the saved current 3rd level section.
///   * If there's no starting marker on the line
///     * If we're in a second level section and URL hasn't been set, set URL.
///     * If there's a current media being built, set it's URL, then clear the saved current.
///     * If there isn't a current media being built, create one and set URL. The title is `'Part ${index + 1}'`
///   * If its a dash (-): Create a new media, set the title.
void main() {
  final dataFile = File('data.txt').readAsLinesSync();
  dataFile.forEach(useLineToFormSite);
  print(jsonEncode(site));
}

void useLineToFormSite(String line) {
  switch (line.split(' ')[0]) {
    case '#':
      currentSection = null;
      currentMediaSection = null;
      currentMedia = null;

      currentTopSection =
          Section(id: idGenerator.next(), title: extractTitle(line));

      site.sections[currentTopSection.id] = currentTopSection;
      site.topItems.add(TopItem(
          sectionId: currentTopSection.id, title: currentTopSection.title));
      break;
    case '##':
      currentMediaSection = null;
      currentMedia = null;

      currentSection = Section(
          id: idGenerator.next(),
          parentId: currentTopSection.id,
          title: extractTitle(line));

      currentTopSection.content
          .add(SectionContent(sectionId: currentSection.id));
      break;
    case '###':
      currentMedia = null;

      currentMediaSection =
          MediaSection(parentId: currentSection.id, title: extractTitle(line));
      break;
    case '-':
      currentMedia = Media(
          title: extractTitle(line),
          id: idGenerator.next(),
          parentId: currentMediaSection.id);
      break;
    default:
      if (currentSection.content.isEmpty) {
        // The first line afer a 2nd level section is the base URL of content in
        // that section.
        currentTopUrlPart = line;
      } else {
        // Either we have a finished media, which was already added, and we can make a new one
        // Or we're in the middle of making one, and all we have so far is the title.
        // If the source isn't set, we know that we're in the middle of making one.
        if (currentMedia.source == null) {
          currentMedia = currentMedia.copyWith(source: line);
        } else {
          currentMedia = Media(
              parentId: currentMediaSection.id,
              title: 'Part ${currentMediaSection.media.length + 1}');
        }

        currentMediaSection.media.add(currentMedia);
        currentMedia = null;
      }
  }
}

String extractTitle(String line) => line.substring(line.indexOf(' ') + 1);
String getUrl(String endUrlPart) => '$urlBase/$currentTopUrlPart/$endUrlPart';

class IDGenerator {
  int _currentId = 0;

  int next() {
    ++_currentId;
    return _currentId;
  }
}