import 'package:flutter/material.dart';

class CreateAssessmentPage extends StatefulWidget {
  const CreateAssessmentPage({super.key});

  @override
  State<CreateAssessmentPage> createState() => _CreateAssessmentPageState();
}

class _CreateAssessmentPageState extends State<CreateAssessmentPage> {
  // Static data for demonstration
  final List<String> _classes = ['Class 10', 'Class 11', 'Class 12'];
  final Map<String, List<String>> _sections = {
    'Class 10': ['Section A', 'Section B', 'Section C'],
    'Class 11': ['Section A', 'Section B'],
    'Class 12': ['Section A', 'Section B', 'Section C'],
  };
  final Map<String, List<String>> _subjects = {
    'Section A': ['Mathematics', 'Physics', 'Chemistry'],
    'Section B': ['Mathematics', 'Biology', 'Chemistry'],
    'Section C': ['Mathematics', 'Computer Science', 'Physics'],
  };
  final Map<String, List<String>> _chapters = {
    'Mathematics': ['Algebra', 'Geometry', 'Calculus', 'Statistics'],
    'Physics': ['Mechanics', 'Thermodynamics', 'Electromagnetism', 'Optics'],
    'Chemistry': ['Atomic Structure', 'Chemical Bonding', 'Thermodynamics', 'Organic Chemistry'],
    'Biology': ['Cell Biology', 'Genetics', 'Ecology', 'Human Physiology'],
    'Computer Science': ['Programming', 'Data Structures', 'Algorithms', 'Database'],
  };
  final Map<String, List<String>> _subtopics = {
    'Algebra': ['Linear Equations', 'Quadratic Equations', 'Polynomials', 'Matrices'],
    'Geometry': ['Triangles', 'Circles', 'Polygons', '3D Geometry'],
    'Calculus': ['Limits', 'Derivatives', 'Integration', 'Differential Equations'],
    'Statistics': ['Probability', 'Data Analysis', 'Hypothesis Testing'],
    'Mechanics': ['Kinematics', 'Dynamics', 'Work and Energy', 'Rotational Motion'],
    'Thermodynamics': ['Laws of Thermodynamics', 'Heat Transfer', 'Entropy'],
    'Electromagnetism': ['Electric Fields', 'Magnetic Fields', 'Electromagnetic Induction'],
    'Optics': ['Reflection', 'Refraction', 'Interference', 'Diffraction'],
  };

  String? _selectedClass;
  String? _selectedSection;
  String? _selectedSubject;
  Set<String> _selectedChapters = {};
  Map<String, bool> _selectedSubtopics = {};
  DateTime? _startTime;
  DateTime? _endTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Assessment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // TODO: Implement profile
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 35, color: Colors.blue),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Teacher Name',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'teacher@educationguide.com',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Create Assessment'),
              selected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Student Analysis'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800), // Constrain width
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, // Center content
              children: [
                const Text(
                  'Create New Assessment',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                _buildClassSelection(),
                if (_selectedClass != null) ...[
                  const SizedBox(height: 16),
                  _buildSectionSelection(),
                ],
                if (_selectedSection != null) ...[
                  const SizedBox(height: 16),
                  _buildSubjectSelection(),
                ],
                if (_selectedSubject != null) ...[
                  const SizedBox(height: 16),
                  _buildChapterSelection(),
                ],
                if (_selectedChapters.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSubtopicSelection(),
                  const SizedBox(height: 16),
                  _buildDateTimeSelection(),
                  const SizedBox(height: 24),
                  _buildGenerateButton(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassSelection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Class',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _classes.map((className) {
                return ChoiceChip(
                  label: Text(className),
                  selected: _selectedClass == className,
                  onSelected: (selected) {
                    setState(() {
                      _selectedClass = selected ? className : null;
                      _selectedSection = null;
                      _selectedSubject = null;
                      _selectedChapters = {};
                      _selectedSubtopics = {};
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionSelection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Section',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _sections[_selectedClass!]!.map((section) {
                return ChoiceChip(
                  label: Text(section),
                  selected: _selectedSection == section,
                  onSelected: (selected) {
                    setState(() {
                      _selectedSection = selected ? section : null;
                      _selectedSubject = null;
                      _selectedChapters = {};
                      _selectedSubtopics = {};
                    });
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
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Subject',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _subjects[_selectedSection!]!.map((subject) {
                return ChoiceChip(
                  label: Text(subject),
                  selected: _selectedSubject == subject,
                  onSelected: (selected) {
                    setState(() {
                      _selectedSubject = selected ? subject : null;
                      _selectedChapters = {};
                      _selectedSubtopics = {};
                    });
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
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Chapters',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _chapters[_selectedSubject!]!.map((chapter) {
                final isSelected = _selectedChapters.contains(chapter);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedChapters.remove(chapter);
                        // Remove all subtopics of this chapter
                        for (var subtopic in _subtopics[chapter]!) {
                          _selectedSubtopics.remove(subtopic);
                        }
                      } else {
                        _selectedChapters.add(chapter);
                        // Add all subtopics of this chapter
                        for (var subtopic in _subtopics[chapter]!) {
                          _selectedSubtopics[subtopic] = true;
                        }
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          chapter,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_selectedChapters.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '${_selectedChapters.length} chapter(s) selected',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubtopicSelection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Selected Subtopics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_selectedSubtopics.values.where((selected) => selected).length} subtopic(s) selected',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._selectedChapters.map((chapter) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      chapter,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _subtopics[chapter]!.map((subtopic) {
                      final isSelected = _selectedSubtopics[subtopic] ?? false;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSubtopics[subtopic] = !isSelected;
                            // If no subtopics are selected for a chapter, remove the chapter
                            if (!isSelected && _selectedChapters.contains(chapter)) {
                              bool hasSelectedSubtopics = _subtopics[chapter]!
                                  .any((st) => _selectedSubtopics[st] ?? false);
                              if (!hasSelectedSubtopics) {
                                _selectedChapters.remove(chapter);
                              }
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue[100] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                subtopic,
                                style: TextStyle(
                                  color: isSelected ? Colors.blue[900] : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.blue[700],
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSelection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assessment Duration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Start Time'),
                    subtitle: Text(_startTime?.toString() ?? 'Not selected'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            _startTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('End Time'),
                    subtitle: Text(_endTime?.toString() ?? 'Not selected'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startTime ?? DateTime.now(),
                        firstDate: _startTime ?? DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            _endTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _startTime != null && _endTime != null
            ? () {
                // TODO: Implement assessment generation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Assessment generated successfully!'),
                  ),
                );
              }
            : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
        child: const Text(
          'Generate Assessment',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}