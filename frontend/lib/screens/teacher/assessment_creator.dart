import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/assessment_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/question_paper.dart';
import '../../widgets/translated_text.dart';
import '../../widgets/translated_text_field.dart';
import '../../services/translation_loader_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:translator/translator.dart' as google_translator;
import 'package:intl/intl.dart';

class AssessmentCreator extends StatefulWidget {
  const AssessmentCreator({super.key});

  @override
  State<AssessmentCreator> createState() => _AssessmentCreatorState();
}

class SubtopicData {
  final String name;
  int questionsAssigned;
  bool isLocked;

  SubtopicData({
    required this.name,
    required this.questionsAssigned,
    this.isLocked = false,
  });
}

class _AssessmentCreatorState extends State<AssessmentCreator> {
  final _formKey = GlobalKey<FormState>();
  String? selectedClass;
  String? selectedSubject;
  String? selectedChapter;
  int? totalQuestions;
  DateTime? startTime;
  DateTime? endTime;
  Map<String, SubtopicData> subtopicQuestions = {};
  Set<String> selectedSubtopics = {};
  List<QuestionPaper> availablePapers = [];
  bool showPapers = false;

  // These will be populated from backend
  List<String> classes = [];
  List<String> subjects = [];
  List<String> chapters = [];
  List<String> subtopics = [];

  // Add translator instance
  late google_translator.GoogleTranslator translator;

  // Add these state variables
  bool isLoading = false;
  Map<String, dynamic> mcqAvailability = {};

  // Add this controller with the other class fields
  final _questionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    translator = google_translator.GoogleTranslator();
    _fetchMcqAvailability();
  }

  // Add translation helper method
  Future<String> _translateText(String text) async {
    try {
      final currentLang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
      
      // If current language is English, return original text
      if (currentLang == 'en') return text;
      
      final translation = await translator.translate(
        text,
        to: currentLang,
      );
      
      return translation.text;
    } catch (e) {
      print('Translation error: $e');
      return text; // Return original text if translation fails
    }
  }

  Future<void> _fetchMcqAvailability() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get the stored token
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      final response = await http.get(
        Uri.parse('http://192.168.255.209:5000/teacher/mcq_availability'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          mcqAvailability = json.decode(response.body);
          classes = List<String>.from(mcqAvailability.keys);
        });
      } else {
        throw 'Failed to fetch MCQ availability';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching MCQ availability: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchSubjects() async {
    if (selectedClass == null) return;
    
    setState(() {
      subjects = List<String>.from(mcqAvailability[selectedClass]?.keys ?? []);
    });
  }

  Future<void> _fetchChapters() async {
    if (selectedClass == null || selectedSubject == null) return;
    
    setState(() {
      chapters = List<String>.from(
        mcqAvailability[selectedClass]?[selectedSubject]?.keys ?? []
      );
    });
  }

  Future<void> _fetchSubtopics() async {
    if (selectedClass == null || selectedSubject == null || selectedChapter == null) return;
    
    setState(() {
      subtopics = List<String>.from(
        mcqAvailability[selectedClass]?[selectedSubject]?[selectedChapter] ?? []
      );
    });
    
    if (totalQuestions != null) {
      _initializeSubtopicQuestions();
    }
  }

  void _initializeSubtopicQuestions() {
    if (totalQuestions == null || subtopics.isEmpty) return;
    
    // Calculate base questions per subtopic
    int baseQuestions = totalQuestions! ~/ subtopics.length;
    int remainingQuestions = totalQuestions! % subtopics.length;
    
    Map<String, SubtopicData> newDistribution = {};
    
    // Initialize each subtopic with base distribution
    for (int i = 0; i < subtopics.length; i++) {
      String subtopic = subtopics[i];
      int questions = baseQuestions;
      
      // Add one extra question to the first few subtopics if there's a remainder
      if (i < remainingQuestions) {
        questions += 1;
      }
      
      newDistribution[subtopic] = SubtopicData(
        name: subtopic,
        questionsAssigned: questions,
        isLocked: false,
      );
    }
    
    // Update state with new distribution
    setState(() {
      subtopicQuestions = newDistribution;
    });
    
    // Debug print the distribution
    print('Initial distribution:');
    for (var s in subtopics) {
      print('$s: ${subtopicQuestions[s]?.questionsAssigned}');
    }
  }

  void _updateSubtopicQuestions(String subtopic, int newValue) {
    if (totalQuestions == null) return;

    // Store the old value before making any changes
    int oldValue = subtopicQuestions[subtopic]?.questionsAssigned ?? 0;
    
    print('Updating subtopic $subtopic from $oldValue to $newValue');

    // Validate if new value exceeds total questions
    if (newValue > totalQuestions!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot exceed total questions ($totalQuestions)',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      // Lock this subtopic and update its value
      subtopicQuestions[subtopic] = SubtopicData(
        name: subtopic,
        questionsAssigned: newValue,
        isLocked: true,
      );
      
      // Calculate total questions allocated to locked subtopics
      int lockedQuestions = subtopicQuestions.values
          .where((data) => data.isLocked)
          .fold(0, (sum, data) => sum + data.questionsAssigned);
      
      print('Locked questions: $lockedQuestions, Total questions: $totalQuestions');
      
      // Calculate remaining questions for unlocked subtopics
      int remainingQuestions = totalQuestions! - lockedQuestions;
      
      if (remainingQuestions < 0) {
        // Reset if we've exceeded total questions
        subtopicQuestions[subtopic] = SubtopicData(
          name: subtopic,
          questionsAssigned: oldValue,
          isLocked: false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid distribution. Exceeds total questions.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get list of unlocked subtopics
      List<String> unlockedSubtopics = subtopicQuestions.entries
          .where((entry) => !entry.value.isLocked)
          .map((entry) => entry.key)
          .toList();
      
      print('Unlocked subtopics: $unlockedSubtopics, Remaining questions: $remainingQuestions');

      // Distribute remaining questions among unlocked subtopics
      if (unlockedSubtopics.isNotEmpty) {
        int baseRemaining = remainingQuestions ~/ unlockedSubtopics.length;
        int extra = remainingQuestions % unlockedSubtopics.length;

        for (int i = 0; i < unlockedSubtopics.length; i++) {
          String s = unlockedSubtopics[i];
          int questions = baseRemaining + (i < extra ? 1 : 0);
          subtopicQuestions[s] = SubtopicData(
            name: s,
            questionsAssigned: questions,
            isLocked: false,
          );
        }
      }
    });

    // Show current distribution in debug console
    print('Current distribution:');
    for (var s in subtopics) {
      final data = subtopicQuestions[s]!;
      print('$s: ${data.questionsAssigned} (${data.isLocked ? "locked" : "unlocked"})');
    }
    
    // Check if we can submit now
    print('Can submit: ${_canSubmit()}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText('assessmentCreation.title'),
        centerTitle: true,
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildClassSelection(),
              if (selectedClass != null) _buildSubjectSelection(),
              if (selectedSubject != null) _buildChapterSelection(),
              if (selectedChapter != null) _buildTotalQuestionsInput(),
              if (totalQuestions != null) _buildSubtopicsSelection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TranslatedText(
              'assessmentCreation.sections.class.title',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: classes.map((className) {
                return FutureBuilder<String>(
                  future: _translateText(className),
                  builder: (context, snapshot) {
                    return ChoiceChip(
                      label: Text(snapshot.data ?? className),
                      selected: selectedClass == className,
                      onSelected: (selected) async {
                        setState(() {
                          selectedClass = selected ? className : null;
                          selectedSubject = null;
                          selectedChapter = null;
                          subtopics.clear();
                          selectedSubtopics.clear();
                          subtopicQuestions.clear();
                        });
                        if (selected) {
                          await _fetchSubjects();
                        }
                      },
                    );
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TranslatedText(
              'assessmentCreation.sections.subject.title',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: subjects.map((subject) {
                return FutureBuilder<String>(
                  future: _translateText(subject),
                  builder: (context, snapshot) {
                    return ChoiceChip(
                      label: Text(snapshot.data ?? subject),
                      selected: selectedSubject == subject,
                      onSelected: (selected) async {
                        setState(() {
                          selectedSubject = selected ? subject : null;
                          selectedChapter = null;
                          subtopics.clear();
                          selectedSubtopics.clear();
                          subtopicQuestions.clear();
                        });
                        if (selected) {
                          await _fetchChapters();
                        }
                      },
                    );
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TranslatedText(
              'assessmentCreation.sections.chapter.title',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: chapters.map((chapter) {
                return FutureBuilder<String>(
                  future: _translateText(chapter),
                  builder: (context, snapshot) {
                    return ChoiceChip(
                      label: Text(snapshot.data ?? chapter),
                      selected: selectedChapter == chapter,
                      onSelected: (selected) async {
                        setState(() {
                          selectedChapter = selected ? chapter : null;
                          subtopics.clear();
                          selectedSubtopics.clear();
                          subtopicQuestions.clear();
                          totalQuestions = null;
                        });
                      },
                    );
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildTotalQuestionsInput() {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TranslatedText(
            'assessmentCreation.sections.questions.title',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              ),
            ),
            child: TranslatedTextField(
              controller: _questionsController,
              hintKey: 'assessmentCreation.sections.questions.hint',
              errorKey: 'assessmentCreation.sections.questions.error',
              onSubmitted: (value) {
                int? parsedValue = int.tryParse(value);
                if (parsedValue != null && parsedValue > 0) {
                  setState(() {
                    totalQuestions = parsedValue;
                  });
                  _fetchSubtopics();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: TranslatedText('assessmentCreation.sections.questions.error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    ),
  );
}


  Widget _buildSubtopicsSelection() {
    // Calculate total allocated questions
    int allocatedQuestions = subtopicQuestions.values
        .fold(0, (sum, data) => sum + data.questionsAssigned);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TranslatedText(
              'assessmentCreation.sections.subtopics.title',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TranslatedText(
                    'assessmentCreation.sections.subtopics.total',
                    params: {'count': totalQuestions.toString()},
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subtopics.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final subtopic = subtopics[index];
                final data = subtopicQuestions[subtopic]!;
                return Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: FutureBuilder<String>(
                        future: _translateText(subtopic),
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.data ?? subtopic,
                            style: const TextStyle(fontSize: 16),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        initialValue: data.questionsAssigned.toString(),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          labelText: _getTranslatedText('assessmentCreation.sections.subtopics.questions'),
                          helperText: _getTranslatedText(
                            data.isLocked 
                              ? 'assessmentCreation.sections.subtopics.status.locked'
                              : 'assessmentCreation.sections.subtopics.status.unlocked'
                          ),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          alignLabelWithHint: true,
                        ),
                        onChanged: (value) {
                          int? newValue = int.tryParse(value);
                          if (newValue != null) {
                            _updateSubtopicQuestions(subtopic, newValue);
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const TranslatedText(
              'assessmentCreation.sections.schedule.title',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const TranslatedText('assessmentCreation.sections.schedule.startTime.title'),
                    subtitle: FutureBuilder<String>(
                      future: startTime != null 
                          ? _translateText('Date: ${DateFormat('MMM dd, yyyy').format(startTime!)} at ${DateFormat('hh:mm a').format(startTime!)}')
                          : _translateText('Start time not set'),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ?? (startTime != null 
                              ? 'Date: ${DateFormat('MMM dd, yyyy').format(startTime!)} at ${DateFormat('hh:mm a').format(startTime!)}'
                              : 'Start time not set'),
                          style: TextStyle(
                            color: startTime == null ? Colors.red : null,
                          ),
                        );
                      },
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDateTime(isStartTime: true),
                  ),
                  const Divider(),
                  ListTile(
                    title: const TranslatedText('assessmentCreation.sections.schedule.endTime.title'),
                    subtitle: FutureBuilder<String>(
                      future: endTime != null 
                          ? _translateText('Date: ${DateFormat('MMM dd, yyyy').format(endTime!)} at ${DateFormat('hh:mm a').format(endTime!)}')
                          : _translateText('End time not set'),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ?? (endTime != null 
                              ? 'Date: ${DateFormat('MMM dd, yyyy').format(endTime!)} at ${DateFormat('hh:mm a').format(endTime!)}'
                              : 'End time not set'),
                          style: TextStyle(
                            color: endTime == null ? Colors.red : null,
                          ),
                        );
                      },
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDateTime(isStartTime: false),
                  ),
                ],
              ),
            ),
            if (_canSubmit()) ...[
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  onPressed: _submitAssessment,
                  child: const TranslatedText(
                    'assessmentCreation.actions.create',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _canSubmit() {
    bool canSubmit = true;
    String missingFields = '';
    
    if (selectedClass == null) {
      canSubmit = false;
      missingFields += 'Class, ';
    }
    
    if (selectedSubject == null) {
      canSubmit = false;
      missingFields += 'Subject, ';
    }
    
    if (selectedChapter == null) {
      canSubmit = false;
      missingFields += 'Chapter, ';
    }
    
    if (totalQuestions == null) {
      canSubmit = false;
      missingFields += 'Total Questions, ';
    }
    
    if (startTime == null) {
      canSubmit = false;
      missingFields += 'Start Time, ';
    }
    
    if (endTime == null) {
      canSubmit = false;
      missingFields += 'End Time, ';
    }

    if (canSubmit) {
      int allocatedQuestions = subtopicQuestions.values
          .fold(0, (sum, data) => sum + data.questionsAssigned);
      
      print('Total questions: $totalQuestions, Allocated questions: $allocatedQuestions');
      
      if (allocatedQuestions != totalQuestions) {
        canSubmit = false;
        missingFields += 'Question allocation mismatch (Total: $totalQuestions, Allocated: $allocatedQuestions)';
      }
    }
    
    if (!canSubmit) {
      print('Cannot submit: Missing fields - $missingFields');
    }
    
    return canSubmit;
  }

  bool _canCheckPapers() {
    return selectedClass != null &&
        selectedSubject != null &&
        selectedChapter != null &&
        startTime != null &&
        endTime != null;
  }

  void _fetchAvailablePapers() {
    final provider = Provider.of<AssessmentProvider>(context, listen: false);
    
    // Filter papers based on selected criteria
    final papers = provider.questionPapers.where((paper) {
      bool matchesBasicCriteria = paper.className == selectedClass &&
                                 paper.subject == selectedChapter;

      // Check if paper contains questions from selected topics
      bool hasMatchingQuestions = paper.questions.any((question) =>
        selectedSubtopics.contains(question.chapter));

      return matchesBasicCriteria && hasMatchingQuestions;
    }).toList();

    setState(() {
      availablePapers = papers;
      showPapers = true;
    });

    if (papers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No matching question papers found for the selected criteria.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // void _viewPaper(BuildContext context, QuestionPaper paper) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => QuestionPaperView(
  //         paper: paper,
  //         isTeacherView: true,
  //       ),
  //     ),
  //   );
  // }

  void _selectPaper(QuestionPaper paper) async {
    try {
      // Validate time
      if (endTime == null || startTime == null) {
        throw await _translateText('assessmentCreation.validation.selectTimes');
      }
      
      if (endTime!.isBefore(startTime!)) {
        throw await _translateText('assessmentCreation.validation.endTimeAfterStart');
      }

      final provider = Provider.of<AssessmentProvider>(context, listen: false);
      await provider.createAssessment(
        className: selectedClass!,
        subject: selectedChapter!,
        topics: selectedSubtopics.join(', '),
        chapter: selectedChapter!,
        startTime: startTime!,
        endTime: endTime!,
        selectedSubtopics: selectedSubtopics.toList(),
        questionPaper: paper,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assessment created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating assessment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDateTime({required bool isStartTime}) async {
    DateTime currentDate = DateTime.now();
    DateTime initialDate = isStartTime ? startTime ?? currentDate : endTime ?? currentDate;

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: currentDate,
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (pickedTime == null) return;

    DateTime selectedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStartTime) {
        startTime = selectedDateTime;
        if (endTime != null && endTime!.isBefore(startTime!)) {
          endTime = null; // Reset end time if it's before start time
        }
      } else {
        if (startTime == null || selectedDateTime.isAfter(startTime!)) {
          endTime = selectedDateTime;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: TranslatedText('assessmentCreation.sections.schedule.endTime.error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  void _submitAssessment() async {
    if (!_canSubmit()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getTranslatedText('assessmentCreation.messages.error.incomplete')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true; // Set loading state to true before API call
    });

    try {
      // Get the stored token
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      
      if (token == null) {
        throw 'Authentication token not found. Please log in again.';
      }

      // Prepare subtopic data
      Map<String, int> subtopicData = {};
      subtopicQuestions.forEach((subtopic, data) {
        subtopicData[subtopic] = data.questionsAssigned;
      });

      // Extract only the numeric part from selectedClass
      String classNumber = selectedClass!.replaceAll(RegExp(r'[^0-9]'), '');
      
      if (classNumber.isEmpty) {
        throw 'Invalid class number format';
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        "class": int.parse(classNumber), // Now parsing only the numeric part
        "subject": selectedSubject,
        "chapter": selectedChapter,
        "start": startTime!.toIso8601String(),
        "end": endTime!.toIso8601String(),
        "subtopic": subtopicData,
      };

      print('Submitting assessment with data: $requestBody'); // Debug log

      // Send POST request
      final response = await http.post(
        Uri.parse('http://192.168.255.209:5000/teacher/assignment_schedule'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assessment Created Successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form
        setState(() {
          selectedClass = null;
          selectedSubject = null;
          selectedChapter = null;
          totalQuestions = null;
          startTime = null;
          endTime = null;
          subtopics.clear();
          selectedSubtopics.clear();
          subtopicQuestions.clear();
          isLoading = false; // Reset loading state
        });

        _fetchMcqAvailability();
      } else if (response.statusCode == 401) {
        throw 'Authentication failed. Please log in again.';
      } else if (response.statusCode == 400) {
        // Try to parse error message from response
        try {
          final errorData = json.decode(response.body);
          throw errorData['message'] ?? 'Invalid request data';
        } catch (e) {
          throw 'Invalid request data: ${response.body}';
        }
      } else {
        throw 'Server error (${response.statusCode}): ${response.body}';
      }
    } catch (e) {
      print('Error creating assessment: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating assessment: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          isLoading = false; // Reset loading state on error
        });
      }
    }
  }

  // Add the _getTranslatedText method
  String _getTranslatedText(String key) {
    // This is a synchronous version for static text
    // For dynamic text, use _translateText instead
    return key;  // Return the key as-is for now, you can integrate with your translation system later
  }

  // Add dispose method if it doesn't exist
  @override
  void dispose() {
    _questionsController.dispose();
    super.dispose();
  }
} 