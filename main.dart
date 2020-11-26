import 'dart:convert';
import 'dart:io';

import 'package:inside_api/models.dart';
import 'package:inside_api/site.dart';

final idGenerator = IDGenerator();
const urlBase = 'http://d35zpkccrlbazl.cloudfront.net';

final site = Site(createdDate: DateTime.now());
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
///   * If its a >: Set the top level media base URL
///   * If there's no starting marker on the line
///     * If there's a current media being built, set it's URL, then clear the saved current.
///     * If there isn't a current media being built, create one and set URL. The title is `'Part ${index + 1}'`
///   * If its a dash (-): Create a new media, set the title.
void main() {
  final dataFile = File('data.txt').readAsLinesSync();
  dataFile.forEach(useLineToFormSite);
  site.setAudioCount();
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

      site.sections[currentSection.id] = currentSection;

      currentTopSection.content
          .add(SectionContent(sectionId: currentSection.id));
      break;
    case '###':
      currentMedia = null;

      // A ### by itself marks the end of the current media section.
      if (!line.contains(' ')) {
        currentMediaSection = null;
        break;
      }

      currentMediaSection = MediaSection(
          parentId: currentSection.id, title: extractTitle(line), media: []);
      currentSection.content
          .add(SectionContent(mediaSection: currentMediaSection));
      break;
    case '-':
      currentMedia = Media(
          title: extractTitle(line),
          id: idGenerator.next(),
          parentId: getCurrentMediaParentId());
      break;
    case '>':
      currentTopUrlPart = extractTitle(line);
      break;
    default:
      // Either we have a finished media, which was already added, and we can make a new one
      // Or we're in the middle of making one, and all we have so far is the title.
      // If the source isn't set, we know that we're in the middle of making one.
      currentMedia = currentMedia?.copyWith(source: getUrl(line)) ??
          Media(
              parentId: getCurrentMediaParentId(),
              title: 'Part ${getCurrentMediaParentLength() + 1}',
              source: getUrl(line));

      addMediaToCurrent(currentMedia);
      currentMedia = null;
  }
}

String extractTitle(String line) => line.substring(line.indexOf(' ') + 1);

String getUrl(String endUrlPart) =>
    Uri.parse('$urlBase/$currentTopUrlPart/$endUrlPart').toString();

SiteDataItem getCurrentMediaParent() =>
    currentMediaSection ?? currentSection ?? currentTopSection;

int getCurrentMediaParentId() => getCurrentMediaParent().id;

void addMediaToCurrent(Media media) {
  final currentParent = getCurrentMediaParent();
  if (currentParent is MediaSection) {
    currentParent.media.add(media);
  } else if (currentParent is Section) {
    currentParent.content.add(SectionContent(media: media));
  }
}

int getCurrentMediaParentLength() {
  final currentParent = getCurrentMediaParent();
  if (currentParent is MediaSection) {
    return currentParent.media?.length ?? 0;
  } else if (currentParent is Section) {
    return currentParent.content?.length ?? 0;
  }

  throw ArgumentError('Not valid parent');
}

class IDGenerator {
  int _currentId = 0;

  int next() {
    ++_currentId;
    return _currentId;
  }
}
