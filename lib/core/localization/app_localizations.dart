import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[Locale('en'), Locale('km')];

  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(localizations != null, 'AppLocalizations was not found in context.');
    return localizations!;
  }

  bool get isKhmer => locale.languageCode == 'km';

  String get appTitle =>
      isKhmer ? 'ផ្ទាំងគ្រប់គ្រងគ្រូ Trellis' : 'Trellis Teachers Portal';

  String get splashTitle => 'Trellis';

  String get splashTagline => isKhmer
      ? 'គ្រប់គ្រងថ្នាក់ និងឯកសាររបស់គ្រូនៅកន្លែងតែមួយ'
      : 'A calm, responsive workspace for classes and teaching folders';

  String get splashLoading =>
      isKhmer ? 'កំពុងរៀបចំផ្ទាំងការងារ...' : 'Preparing your workspace...';

  String get overview => isKhmer ? 'ទិដ្ឋភាពទូទៅ' : 'Overview';
  String get folders => isKhmer ? 'Folder' : 'Folders';
  String get settings => isKhmer ? 'ការកំណត់' : 'Settings';
  String get classes => isKhmer ? 'ថ្នាក់' : 'Classes';
  String get students => isKhmer ? 'សិស្ស' : 'Students';
  String get girls => isKhmer ? 'សិស្សស្រី' : 'Girls';

  String get workspaceTitle =>
      isKhmer ? 'Teacher Workspace' : 'Teacher Workspace';

  String get workspaceSubtitle => isKhmer
      ? 'បង្កើតថ្នាក់ រៀបចំវាទៅក្នុង Folder និងបើកការងារបង្រៀនពីផ្ទាំងតែមួយ'
      : 'Create classes, organize them into folders, and open your teaching tools from one responsive portal';

  String get workspaceHighlight => isKhmer
      ? 'រចនាសម្ព័ន្ធថ្មីលែងមានជំហានសាលាទៀតហើយ'
      : 'The new flow removes the school step entirely';

  String get createClass => isKhmer ? 'បង្កើតថ្នាក់' : 'Create Class';
  String get createFolder => isKhmer ? 'បង្កើត Folder' : 'Create Folder';
  String get allClasses => isKhmer ? 'ថ្នាក់ទាំងអស់' : 'All Classes';
  String get unassignedClasses =>
      isKhmer ? 'ថ្នាក់មិនទាន់ដាក់ Folder' : 'Unassigned Classes';
  String get openClass => isKhmer ? 'បើកថ្នាក់' : 'Open Class';
  String get moveToFolder => isKhmer ? 'ផ្លាស់ទៅ Folder' : 'Move To Folder';
  String get removeFromFolder =>
      isKhmer ? 'ដកចេញពី Folder' : 'Remove From Folder';
  String get viewAll => isKhmer ? 'មើលទាំងអស់' : 'View All';

  String get classesSectionTitle => isKhmer ? 'ថ្នាក់របស់អ្នក' : 'Your Classes';

  String get classesSectionSubtitle => isKhmer
      ? 'ប្លង់កាត និងបណ្ដាញនឹងប្ដូរទៅតាមទំហំអេក្រង់ដោយស្វ័យប្រវត្តិ'
      : 'Cards and grids automatically adapt between mobile and wide web layouts';

  String get foldersSectionTitle =>
      isKhmer ? 'ការរៀបចំតាម Folder' : 'Folder Organization';

  String get foldersSectionSubtitle => isKhmer
      ? 'ប្រើ Folder ដើម្បីបំបែកថ្នាក់តាមវេន កម្រិត ឬគម្រោង'
      : 'Group classes by shift, level, or any teaching workflow that suits you';

  String get settingsSectionTitle =>
      isKhmer ? 'ភាសា និងបទពិសោធន៍' : 'Language and Experience';

  String get settingsSectionSubtitle => isKhmer
      ? 'ផ្លាស់ប្ដូរភាសា និងគ្រប់គ្រងផ្ទាំងគ្រប់គ្រងថ្មី'
      : 'Switch languages and control the new teacher-first shell';

  String get languageTitle => isKhmer ? 'ភាសា' : 'Language';

  String get languageSubtitle => isKhmer
      ? 'អង់គ្លេសត្រូវបានកំណត់ជាលំនាំដើមពេលបើកកម្មវិធី'
      : 'English is the default language when the app loads';

  String get english => 'English';
  String get khmer => isKhmer ? 'ខ្មែរ' : 'Khmer';

  String get aboutTitle => isKhmer ? 'អំពី UI ថ្មី' : 'About The New UI';

  String get aboutBody => isKhmer
      ? 'ស្ទីលថ្មីប្រើពណ៌ទន់ ប្លង់ស្អាត និងការឆ្លើយតបល្អសម្រាប់ទូរស័ព្ទ និង Web។'
      : 'The refreshed shell uses a soft editorial palette, simplified structure, and responsive surfaces for both mobile and web.';

  String get noClassesTitle =>
      isKhmer ? 'មិនទាន់មានថ្នាក់នៅឡើយទេ' : 'No classes yet';

  String get noClassesBody => isKhmer
      ? 'បង្កើតថ្នាក់ដំបូងរបស់អ្នក ហើយបន្ទាប់មកដាក់វាចូល Folder តាមរបៀបដែលអ្នកចង់បាន'
      : 'Create your first class, then sort it into folders that match your teaching workflow';

  String get noFoldersTitle =>
      isKhmer ? 'មិនទាន់មាន Folder នៅឡើយទេ' : 'No folders yet';

  String get noFoldersBody => isKhmer
      ? 'Folder ជួយអោយផ្ទាំងការងាររបស់គ្រូស្អាត និងងាយស្រួលស្វែងរកថ្នាក់'
      : 'Folders keep the teacher portal clean and make classes easier to find across devices';

  String get createClassDialogTitle =>
      isKhmer ? 'បង្កើតថ្នាក់ថ្មី' : 'Create a new class';

  String get createFolderDialogTitle =>
      isKhmer ? 'បង្កើត Folder ថ្មី' : 'Create a new folder';

  String get classNameLabel => isKhmer ? 'ឈ្មោះថ្នាក់' : 'Class name';
  String get folderNameLabel => isKhmer ? 'ឈ្មោះ Folder' : 'Folder name';

  String get classNameHint =>
      isKhmer ? 'ឧ. Grade 7 Morning' : 'For example: Grade 7 Morning';

  String get folderNameHint =>
      isKhmer ? 'ឧ. Morning Shift' : 'For example: Morning Shift';

  String get academicYearLabel => isKhmer ? 'ឆ្នាំសិក្សា' : 'Academic year';

  String get academicYearHint =>
      isKhmer ? 'ឧ. 2025-2026' : 'For example: 2025-2026';

  String get classTypeLabel => isKhmer ? 'ប្រភេទថ្នាក់' : 'Class type';

  String get adviserClassLabel =>
      isKhmer ? 'ថ្នាក់គ្រូបន្ទុក' : 'Adviser class';

  String get standardClassLabel => isKhmer ? 'ថ្នាក់ទូទៅ' : 'Standard class';

  String get subjectsLabel => isKhmer ? 'មុខវិជ្ជា' : 'Subjects';
  String get cancel => isKhmer ? 'បោះបង់' : 'Cancel';
  String get create => isKhmer ? 'បង្កើត' : 'Create';
  String get save => isKhmer ? 'រក្សាទុក' : 'Save';

  String get createFolderHelp => isKhmer
      ? 'ដាក់ឈ្មោះ Folder មួយសម្រាប់តម្រៀបថ្នាក់របស់អ្នក'
      : 'Give your folder a name so your classes stay neatly grouped';

  String get createClassHelp => isKhmer
      ? 'បង្កើតថ្នាក់រួច អ្នកអាចដាក់វាចូល Folder ភ្លាមៗ'
      : 'After the class is created, you can assign it to a folder right away';

  String get classCreatedMessage =>
      isKhmer ? 'បានបង្កើតថ្នាក់រួចហើយ' : 'Class created';

  String folderCreatedMessage(String folderName) => isKhmer
      ? 'បានបង្កើត Folder "$folderName"'
      : 'Created folder "$folderName"';

  String classMovedMessage(String className, String folderName) => isKhmer
      ? 'បានផ្លាស់ $className ទៅក្នុង $folderName'
      : 'Moved $className into $folderName';

  String classUnassignedMessage(String className) => isKhmer
      ? 'បានដក $className ចេញពី Folder'
      : 'Removed $className from its folder';

  String totalClasses(int count) =>
      isKhmer ? '$count ថ្នាក់' : '$count classes';

  String totalFolders(int count) =>
      isKhmer ? '$count Folder' : '$count folders';

  String totalStudents(int count) =>
      isKhmer ? '$count សិស្ស' : '$count students';

  String studentsInClass(int count) =>
      isKhmer ? '$count សិស្ស' : '$count students';

  String classesInFolder(int count) =>
      isKhmer ? '$count ថ្នាក់' : '$count classes';

  String get adviser => isKhmer ? 'គ្រូបន្ទុក' : 'Adviser';
  String get standard => isKhmer ? 'ទូទៅ' : 'Standard';

  String folderChip(String name) => isKhmer ? 'Folder: $name' : 'Folder: $name';

  String get classWorkspaceSubtitle => isKhmer
      ? 'គ្រប់គ្រងសិស្ស មុខវិជ្ជា កិច្ចការ និងតារាងពិន្ទុ'
      : 'Manage students, subjects, assignments, and gradebook data';

  String get studentsTab => isKhmer ? 'សិស្ស' : 'Students';
  String get subjectsTab => isKhmer ? 'មុខវិជ្ជា' : 'Subjects';
  String get assignmentsTab => isKhmer ? 'កិច្ចការ' : 'Assignments';
  String get gradebookTab => isKhmer ? 'តារាងពិន្ទុ' : 'Gradebook';
  String get availableActions => isKhmer ? 'សកម្មភាព' : 'Available Actions';
  String get addStudent => isKhmer ? 'បន្ថែមសិស្ស' : 'Add Student';
  String get syncAdviserSubjects =>
      isKhmer ? 'បំពេញមុខវិជ្ជាគ្រូបន្ទុក' : 'Sync Adviser Subjects';
  String get exportSubjects => isKhmer ? 'នាំចេញមុខវិជ្ជា' : 'Export Subjects';
  String get importSubjects => isKhmer ? 'នាំចូលមុខវិជ្ជា' : 'Import Subjects';
  String get exportGradebook =>
      isKhmer ? 'នាំចេញតារាងពិន្ទុ' : 'Export Gradebook';
  String get importGradebook =>
      isKhmer ? 'នាំចូលតារាងពិន្ទុ' : 'Import Gradebook';

  List<String> get subjectCatalog => isKhmer
      ? const [
          'ភាសាខ្មែរ',
          'អង់គ្លេស',
          'គណិតវិទ្យា',
          'ជីវវិទ្យា',
          'រូបវិទ្យា',
          'គីមីវិទ្យា',
          'ប្រវត្តិវិទ្យា',
          'ភូមិវិទ្យា',
          'ICT',
          'សិល្បៈ',
        ]
      : const [
          'Khmer',
          'English',
          'Mathematics',
          'Biology',
          'Physics',
          'Chemistry',
          'History',
          'Geography',
          'ICT',
          'Art',
        ];
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}
