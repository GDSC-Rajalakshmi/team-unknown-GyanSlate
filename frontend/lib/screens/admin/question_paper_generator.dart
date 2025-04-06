import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/assessment_provider.dart';
import '../../models/question.dart';
import '../../models/question_paper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class QuestionPaperGenerator extends StatefulWidget {
  const QuestionPaperGenerator({super.key});

  @override
  State<QuestionPaperGenerator> createState() => _QuestionPaperGeneratorState();
}

class _QuestionPaperGeneratorState extends State<QuestionPaperGenerator> {
  final _formKey = GlobalKey<FormState>();
  int? selectedClass;
  String? selectedSubject;
  String? selectedChapter;
  PlatformFile? uploadedFile;
  List<String> extractedSubtopics = [];
  Set<String> selectedSubtopics = {};
  bool isRegionalTransformationNeeded = false;
  double numberOfQuestions = 25; // Default value
  bool isLoading = false;
  
  List<Question> generatedQuestions = [];
  List<Question> selectedQuestions = [];
  bool questionsGenerated = false;

  // Updated data structures
  final List<int> classes = [4,5,6,7,8,9,10];
  
  // Add ScrollController
  final ScrollController _scrollController = ScrollController();
  // Add a key to identify the generated questions section
  final GlobalKey _generatedQuestionsKey = GlobalKey();

  // Add this map to store the number of questions for each subtopic
  Map<String, int> subtopicQuestionCount = {};

  double examplePercentage = 0; // New variable for example percentage

  // Add state-specific questions
  Map<String, List<Question>> stateQuestions = {};
  String? selectedState;

  String? accessToken; // Add this variable to store the access token

  // Replace the hardcoded state list with translation keys
  final List<String> stateTranslationKeys = ['Tamil Nadu', 'Andhra Pradesh', 'Delhi'];

  // Add this variable to track the currently selected state for viewing questions
  String? selectedViewState = 'common';

  // Add this to your class state
  Set<int> unselectedQuestionIndices = {}; // Track unselected questions by index

  // Add this variable to store selected states
  Set<String> selectedStates = {};

  @override
  void initState() {
    super.initState();
  }

  Future<void> _uploadAndProcessPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          uploadedFile = result.files.first;
          isLoading = true;
        });

        // Show loading dialog
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Processing PDF...'),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }

        // Prepare the file for upload
        final fileBytes = uploadedFile?.bytes;
        if (fileBytes == null) {
          throw Exception('File bytes are null');
        }

        // Get the stored token
        final storage = const FlutterSecureStorage();
        final token = await storage.read(key: 'token');

        final uri = Uri.parse('https://dharsan-rural-edu-101392092221.asia-south1.run.app/admin/subtopic_generation');
        final request = http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer $token'
          ..files.add(http.MultipartFile.fromBytes(
            'file',
            fileBytes,
            filename: uploadedFile!.name,
          ));

        // Send the request
        final response = await request.send();

        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
        }

        if (response.statusCode == 200) {
          final responseData = await response.stream.bytesToString();
          final extractedData = jsonDecode(responseData)['subtopics'].cast<String>();

          setState(() {
            extractedSubtopics = extractedData;
            selectedSubtopics = Set.from(extractedData); // Select all by default
            isLoading = false;
          });
        } else {
          throw Exception('Failed to process PDF');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  void _scrollToGeneratedQuestions() {
    // Wait for the UI to be built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Find the generated questions position using the key
      final RenderBox renderBox = _generatedQuestionsKey.currentContext?.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      
      // Scroll to the position with some padding at the top
      _scrollController.animateTo(
        position.dy - 100, // Subtract some padding (100 pixels) from the top
        duration: const Duration(milliseconds: 800), // Increased duration for smoother scroll
        curve: Curves.easeInOut, // Changed curve for smoother animation
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Don't forget to dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Generate MCQs',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF2C3E50)),
      ),
      backgroundColor: Color(0xFFF8FAFB), // Same as authorization page
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Class Selection
                  DropdownButtonFormField<int>(
                    value: selectedClass,
                    decoration: const InputDecoration(
                      labelText: 'Select Class',
                    ),
                    items: classes.map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedClass = value;
                        selectedSubject = null;
                        selectedChapter = null;
                      });
                    },
                    validator: (value) => value == null ? 'Please select a class' : null,
                  ),
                  const SizedBox(height: 16),

                  // Subject Selection
                  if (selectedClass != null)
                    TextFormField(
                      initialValue: selectedSubject,
                      decoration: const InputDecoration(
                        labelText: 'Select Subject',
                      ),
                      onChanged: (value) {
                        setState(() {
                          selectedSubject = value;
                          selectedChapter = null;
                        });
                      },
                      validator: (value) => value == null || value.isEmpty ? 'Please select a subject' : null,
                    ),

                  // Chapter Selection
                  if (selectedSubject != null) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: selectedChapter,
                      decoration: const InputDecoration(
                        labelText: 'Select Chapter',
                      ),
                      onChanged: (value) => setState(() => selectedChapter = value),
                      validator: (value) => value == null || value.isEmpty ? 'Please select a chapter' : null,
                    ),
                  ],

                  // Number of Questions and Example Percentage
                  if (selectedChapter != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Number of Questions',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    numberOfQuestions.round().toString(),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Slider(
                              value: numberOfQuestions,
                              min: 0,
                              max: 50,
                              divisions: 50,
                              label: numberOfQuestions.round().toString(),
                              onChanged: (value) {
                                setState(() {
                                  numberOfQuestions = value;
                                });
                              },
                            ),
                            const SizedBox(height: 24), // Increased spacing between sections
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Example Percentage',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '${examplePercentage.round()}%',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Slider(
                              value: examplePercentage,
                              min: 0,
                              max: 100,
                              divisions: 100,
                              label: '${examplePercentage.round()}%',
                              onChanged: (value) {
                                setState(() {
                                  examplePercentage = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // PDF Upload
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _uploadAndProcessPDF,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Chapter PDF'),
                    ),

                    // Subtopics Selection
                    if (extractedSubtopics.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Set Questions Per Subtopic',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...extractedSubtopics.map((subtopic) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: Text(
                                    subtopic,
                                    style: const TextStyle(fontSize: 14),
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: TextFormField(
                                  initialValue: '0',
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Questions',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      int count = int.tryParse(value) ?? 0;
                                      subtopicQuestionCount[subtopic] = count;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      // Regional Transformation Option
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('Regional Transformation'),
                        value: isRegionalTransformationNeeded,
                        onChanged: (bool? value) {
                          setState(() {
                            isRegionalTransformationNeeded = value ?? false;
                          });
                        },
                      ),

                      // State Selection
                      const SizedBox(height: 24),
                      Text(
                        'Select States',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        children: stateTranslationKeys.map((stateKey) {
                          return FilterChip(
                            label: Text(stateKey),
                            selected: selectedStates.contains(stateKey),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  selectedStates.add(stateKey);
                                } else {
                                  selectedStates.remove(stateKey);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),

                      // Generate Button
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: extractedSubtopics.isNotEmpty
                            ? () async {
                                if (_formKey.currentState!.validate()) {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      return Center(
                                        child: Card(
                                          child: Padding(
                                            padding: const EdgeInsets.all(32.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const CircularProgressIndicator(),
                                                const SizedBox(height: 20),
                                                Text(
                                                  'Generating Questions...',
                                                  style: Theme.of(context).textTheme.titleMedium,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Estimated time: 4 minutes',
                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );

                                  await _generateQuestions();
                                  
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                    Future.delayed(const Duration(milliseconds: 100), () {
                                      _scrollToFirstQuestion();
                                    });
                                  }
                                }
                              }
                            : null,
                        child: const Text('Generate Questions'),
                      ),
                    ],
                  ],

                  // Display Questions
                  if (questionsGenerated) ...[
                    const SizedBox(height: 24),
                    Card(
                      key: _generatedQuestionsKey,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              spacing: 16,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Questions for ${selectedViewState == 'common' ? 'Common Pool' : (selectedViewState ?? 'Common Pool')}',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (BuildContext context) {
                                        return Center(
                                          child: Card(
                                            child: Padding(
                                              padding: const EdgeInsets.all(32.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const CircularProgressIndicator(),
                                                  const SizedBox(height: 20),
                                                  Text(
                                                    'Processing PDF...',
                                                    style: Theme.of(context).textTheme.titleMedium,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );

                                    await _generateQuestions();
                                    
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                      Future.delayed(const Duration(milliseconds: 100), () {
                                        _scrollToFirstQuestion();
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Regenerate'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // State filter dropdown
                            if (questionsGenerated && (stateQuestions.isNotEmpty || generatedQuestions.isNotEmpty)) 
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Filter by State:',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade300),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              isExpanded: true,
                                              value: selectedViewState,
                                              hint: const Text('Select State'),
                                              items: [
                                                DropdownMenuItem<String>(
                                                  value: 'common',
                                                  child: Text('Common Pool'),
                                                ),
                                                ...stateQuestions.keys.map((state) {
                                                  return DropdownMenuItem<String>(
                                                    value: state,
                                                    child: Text(state),
                                                  );
                                                }).toList(),
                                              ],
                                              onChanged: (String? newValue) {
                                                if (newValue != null) {
                                                  setState(() {
                                                    selectedViewState = newValue;
                                                    unselectedQuestionIndices.clear(); // Clear unselected indices when changing states
                                                    if (newValue == 'common') {
                                                      selectedQuestions = List.from(generatedQuestions);
                                                    } else {
                                                      selectedQuestions = List.from(stateQuestions[newValue] ?? []);
                                                    }
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              
                            const SizedBox(height: 16),
                            
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                children: [
                                  Text(
                                    'Selected: ${selectedQuestions.length} out of ${generatedQuestions.length}',
                                    style: Theme.of(context).textTheme.titleMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: selectedQuestions.length,
                              itemBuilder: (context, index) {
                                final question = selectedQuestions[index];
                                final isUnselected = unselectedQuestionIndices.contains(index);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isUnselected ? Colors.grey.shade200 : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Q${index + 1}: ${question.questionText}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: isUnselected ? Colors.grey : Colors.black,
                                              ),
                                            ),
                                          ),
                                          Checkbox(
                                            value: !isUnselected,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                if (value == false) {
                                                  unselectedQuestionIndices.add(index);
                                                } else {
                                                  unselectedQuestionIndices.remove(index);
                                                }
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                      if (!isUnselected) ...[
                                        const SizedBox(height: 8),
                                        ...question.options.map((option) {
                                          final isCorrect = option == question.answer;
                                          return ListTile(
                                            dense: true,
                                            leading: Icon(
                                              isCorrect ? Icons.check_circle : Icons.circle_outlined,
                                              color: isCorrect ? Colors.green : Colors.grey,
                                              size: 20,
                                            ),
                                            title: Text(option),
                                          );
                                        }).toList(),
                                      ] else ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Question Unselected',
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            if (selectedQuestions.isNotEmpty)
                              ElevatedButton(
                                onPressed: _generatePaper,
                                child: const Text('Create Question Paper'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _generateQuestions() async {
    if (selectedClass == null || selectedSubject == null || selectedChapter == null) {
      return;
    }

    // Add validation for subtopic question counts
    int totalSubtopicQuestions = subtopicQuestionCount.values.fold(0, (sum, count) => sum + count);
    if (totalSubtopicQuestions != numberOfQuestions.round()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Total questions mismatch: $totalSubtopicQuestions selected, ${(numberOfQuestions.round())} expected'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Get the stored token
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      final fileBytes = uploadedFile?.bytes;
      if (fileBytes == null) {
        throw Exception('File bytes are null');
      }

      final uri = Uri.parse('https://dharsan-rural-edu-101392092221.asia-south1.run.app/admin/mcq_generation');
      
      // Create the request data
      final requestData = {
        "access": "admin_key##",
        "class": selectedClass,
        "subject": selectedSubject,
        "chapter": selectedChapter,
        "subtopic_q_count": subtopicQuestionCount,
        "example_percentage": examplePercentage / 100,
        "is_region_transform": isRegionalTransformationNeeded ? 1 : 0,
        "choose_regions": ['common', ...selectedStates],
      };
      
      // Print the request data for debugging
      print('MCQ Generation Request: ${jsonEncode(requestData)}');
      
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['data'] = jsonEncode(requestData)
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: uploadedFile!.name,
        ));

      final response = await request.send();

      // Handle the response to extract the access key
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final decodedData = jsonDecode(responseData);
        
        // Store the access key for future use
        accessToken = decodedData['access']; // Store the access key

        // Log the access key for debugging
        print('Access Key: $accessToken');

        setState(() {
          // Clear previous data
          generatedQuestions = [];
          stateQuestions = {};
          
          // Process common questions
          if (decodedData['common'] != null) {
            generatedQuestions = (decodedData['common'] as List).map((q) => 
              Question.fromApiResponse(
                q,
                subject: selectedSubject!,
                chapter: selectedChapter!,
                className: selectedClass!.toString(),
              )
            ).toList();
          }
          
          // Process state-specific questions
          decodedData.forEach((key, value) {
            if (key != 'access' && key != 'common' && value is List && value.isNotEmpty) {
              stateQuestions[key] = value.map((q) => 
                Question.fromApiResponse(
                  q,
                  subject: selectedSubject!,
                  chapter: selectedChapter!,
                  className: selectedClass!.toString(),
                )
              ).toList();
            }
          });
          
          // Set default view to common questions
          selectedViewState = 'common';
          selectedQuestions = List.from(generatedQuestions);
          
          questionsGenerated = true;
        });

        _scrollToGeneratedQuestions();
      } else {
        throw Exception('Failed to generate questions. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error generating questions: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating questions: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _generatePaper() async {
    if (selectedQuestions.isEmpty) return;

    print('Starting question paper generation...'); // Debug log

    try {
      // Show loading dialog
      print('Showing loading dialog...'); // Debug log
      
      // Use a BuildContext that's guaranteed to be valid
      final scaffoldContext = context;
      
      if (scaffoldContext.mounted) {
        showDialog(
          context: scaffoldContext,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            print('Building loading dialog...'); // Debug log
            return WillPopScope(
              onWillPop: () async => false, // Prevent back button from dismissing
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        Text(
                          'Creating Question Paper...',
                          style: Theme.of(dialogContext).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please wait while we process your request',
                          style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
        print('Loading dialog shown'); // Debug log
      } else {
        print('Context not mounted, cannot show dialog'); // Debug log
      }

      // Get the stored token
      print('Getting authentication token...'); // Debug log
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      print('Token retrieved: ${token != null ? 'Yes' : 'No'}'); // Debug log

      print('Submitting MCQ generation...'); // Debug log
      final submitUri = Uri.parse('https://dharsan-rural-edu-101392092221.asia-south1.run.app/admin/mcq_generation/submit');
      final submitResponse = await http.post(
        submitUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'access': accessToken,
          'submit': 1
        }),
      );

      print('Submit response status: ${submitResponse.statusCode}'); // Debug log
      print('Submit response body: ${submitResponse.body}'); // Debug log

      if (submitResponse.statusCode != 200) {
        throw Exception('Failed to submit MCQ generation status');
      }

      final submitData = jsonDecode(submitResponse.body);
      print('Submission status: ${submitData['status']}'); // Debug log

      print('Creating question paper object...'); // Debug log
      final questionPaper = QuestionPaper(
        title: 'Generated Questions ${DateTime.now()}',
        subject: selectedSubject!,
        className: selectedClass!.toString(),
        questions: selectedQuestions,
        description: 'Automatically generated questions',
      );

      print('Adding question paper to provider...'); // Debug log
      final provider = Provider.of<AssessmentProvider>(context, listen: false);
      await provider.addQuestionPaper(questionPaper);
      print('Question paper added to provider'); // Debug log

      // Close the loading dialog
      print('Closing loading dialog...'); // Debug log
      if (scaffoldContext.mounted) {
        Navigator.of(scaffoldContext).pop(); // Close the loading dialog
        print('Loading dialog closed'); // Debug log
      } else {
        print('Context not mounted, cannot close dialog'); // Debug log
      }

      if (!mounted) return;

      print('Showing success message...'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Question paper generated successfully'),
          backgroundColor: Color(0xFF4A90E2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(10),
        ),
      );

      print('Navigating back...'); // Debug log
      Navigator.pop(context); // Go back to previous screen
    } catch (e) {
      print('Error in _generatePaper: $e'); // Debug log
      
      // Close the loading dialog if it's open
      if (context.mounted) {
        Navigator.of(context).pop(); // Close the loading dialog
        print('Loading dialog closed after error'); // Debug log
      } else {
        print('Context not mounted after error, cannot close dialog'); // Debug log
      }
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating questions: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _scrollToFirstQuestion() {
    if (selectedQuestions.isNotEmpty) {
      final RenderBox renderBox = _generatedQuestionsKey.currentContext?.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      
      _scrollController.animateTo(
        position.dy - 100, // Subtract some padding from the top
        duration: const Duration(milliseconds: 800), // Increased duration for smoother scroll
        curve: Curves.easeInOut, // Changed curve for smoother animation
      );
    }
  }
}