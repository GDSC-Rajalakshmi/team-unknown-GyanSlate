import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/translation_loader_service.dart';
import 'package:provider/provider.dart';
import '../../../providers/language_provider.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({Key? key}) : super(key: key);

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  // Subject and chapter selection
  String? selectedSubject;
  String? selectedChapter;
  
  // Replace the static lists with translation keys
  final List<String> subjectKeys = [
    'general.doubt.subjects.mathematics',
    'general.doubt.subjects.physics',
    'general.doubt.subjects.chemistry',
    'general.doubt.subjects.biology'
  ];

  // Map for chapter translation keys - Updated to match JSON structure
  final Map<String, List<String>> chapterKeysBySubject = {
    'general.doubt.subjects.mathematics': [
      'general.doubt.chapters.mathematics.algebra',
      'general.doubt.chapters.mathematics.geometry',
      'general.doubt.chapters.mathematics.calculus',
      'general.doubt.chapters.mathematics.statistics'
    ],
    'general.doubt.subjects.physics': [
      'general.doubt.chapters.physics.mechanics',
      'general.doubt.chapters.physics.thermodynamics',
      'general.doubt.chapters.physics.electromagnetism',
      'general.doubt.chapters.physics.optics'
    ],
    'general.doubt.subjects.chemistry': [
      'general.doubt.chapters.chemistry.organic',
      'general.doubt.chapters.chemistry.inorganic',
      'general.doubt.chapters.chemistry.physical'
    ],
    'general.doubt.subjects.biology': [
      'general.doubt.chapters.biology.botany',
      'general.doubt.chapters.biology.zoology',
      'general.doubt.chapters.biology.physiology',
      'general.doubt.chapters.biology.genetics'
    ]
  };
  
  // Sample history data - Replace with your actual data
  final List<Map<String, dynamic>> historyItems = [
    {
      'id': '1',
      'question': 'Solve the equation: 2x + 5 = 15',
      'subject': 'Mathematics',
      'chapter': 'Algebra',
      'date': '2023-10-15',
      'thumbnail': 'assets/images/math_question.png',
    },
    {
      'id': '2',
      'question': 'Find the derivative of f(x) = x² + 3x - 2',
      'subject': 'Mathematics',
      'chapter': 'Calculus',
      'date': '2023-10-14',
      'thumbnail': 'assets/images/calculus_question.png',
    },
    {
      'id': '3',
      'question': 'Calculate the area of a circle with radius 5 cm',
      'subject': 'Mathematics',
      'chapter': 'Geometry',
      'date': '2023-10-13',
      'thumbnail': 'assets/images/geometry_question.png',
    },
    {
      'id': '4',
      'question': 'What is the law of conservation of energy?',
      'subject': 'Physics',
      'chapter': 'Thermodynamics',
      'date': '2023-10-12',
      'thumbnail': 'assets/images/physics_question.png',
    },
    {
      'id': '5',
      'question': 'Explain the structure of a cell membrane',
      'subject': 'Biology',
      'chapter': 'Human Physiology',
      'date': '2023-10-11',
      'thumbnail': 'assets/images/biology_question.png',
    },
  ];
  
  List<Map<String, dynamic>> get filteredHistory {
    if (selectedSubject == null) {
      return historyItems;
    }
    
    if (selectedChapter == null) {
      return historyItems.where((item) => item['subject'] == selectedSubject).toList();
    }
    
    return historyItems.where((item) => 
      item['subject'] == selectedSubject && item['chapter'] == selectedChapter
    ).toList();
  }

  // Add translation helper method
  String _getTranslatedText(String key) {
    return TranslationLoaderService().getTranslation(
      key,
      Provider.of<LanguageProvider>(context).currentLanguage
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Filter Section
          _buildFilterSection(),
          
          // History List
          Expanded(
            child: _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  // Filter Section Widget
  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF4A90E2).withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Color(0xFF4A90E2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.filter_list,
                  color: Color(0xFF4A90E2),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                _getTranslatedText('general.doubt.history.filter.title'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Dropdown Filters
          Row(
            children: [
              Expanded(
                child: _buildSubjectDropdown(),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildChapterDropdown(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Subject Dropdown Widget
  Widget _buildSubjectDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedSubject,
      isExpanded: true,
      decoration: _getDropdownDecoration(
        'general.doubt.history.filter.subject.label'
      ),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text(_getTranslatedText('general.doubt.history.filter.subject.all')),
        ),
        ...subjectKeys.map((String key) {
          return DropdownMenuItem(
            value: key,
            child: Text(_getTranslatedText(key)),
          );
        }).toList(),
      ],
      onChanged: (String? newValue) {
        setState(() {
          selectedSubject = newValue;
          selectedChapter = null;
        });
      },
    );
  }

  // Chapter Dropdown Widget
  Widget _buildChapterDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedChapter,
      isExpanded: true,
      decoration: _getDropdownDecoration(
        'general.doubt.history.filter.chapter.label'
      ),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text(_getTranslatedText('general.doubt.history.filter.chapter.all')),
        ),
        ...(selectedSubject != null
            ? (chapterKeysBySubject[selectedSubject] ?? []).map((String key) {
                return DropdownMenuItem(
                  value: key,
                  child: Text(_getTranslatedText(key)),
                );
              }).toList()
            : []),
      ],
      onChanged: (String? newValue) {
        setState(() {
          selectedChapter = newValue;
        });
      },
    );
  }

  // History List Widget
  Widget _buildHistoryList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredHistory.length,
      itemBuilder: (context, index) {
        final item = filteredHistory[index];
        return _buildHistoryItem(item);
      },
    );
  }

  // History Item Widget
  Widget _buildHistoryItem(Map<String, dynamic> item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color(0xFF4A90E2).withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: _buildHistoryItemContent(item),
    );
  }

  // History Item Content
  Widget _buildHistoryItemContent(Map<String, dynamic> item) {
    return InkWell(
      onTap: () => print('Tapped on history item: ${item['id']}'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHistoryItemThumbnail(item),
            SizedBox(width: 12),
            Expanded(
              child: _buildHistoryItemDetails(item),
            ),
          ],
        ),
      ),
    );
  }

  // Common Dropdown Decoration
  InputDecoration _getDropdownDecoration(String labelKey) {
    return InputDecoration(
      labelText: _getTranslatedText(labelKey),
      labelStyle: TextStyle(color: Color(0xFF4A90E2)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFF4A90E2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFF4A90E2).withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFF4A90E2)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      filled: true,
      fillColor: Color(0xFF4A90E2).withOpacity(0.05),
    );
  }

  Widget _buildHistoryItemThumbnail(Map<String, dynamic> item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.asset(
        item['thumbnail'],
        width: 70,
        height: 70,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 70,
            height: 70,
            color: Color(0xFF4A90E2).withOpacity(0.1),
            child: Icon(
              Icons.question_mark,
              color: Color(0xFF4A90E2),
              size: 30,
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryItemDetails(Map<String, dynamic> item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item['question'],
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C3E50),
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFF4A90E2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item['subject'],
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4A90E2),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFF4A90E2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item['chapter'],
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4A90E2),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Text(
          'Solved on ${_formatDate(item['date'])}',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF2C3E50).withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    final DateTime date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return _getTranslatedText('general.doubt.history.date.today');
    } else if (difference.inDays == 1) {
      return _getTranslatedText('general.doubt.history.date.yesterday');
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${_getTranslatedText('general.doubt.history.date.days_ago')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showOptionsMenu(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.visibility, color: Colors.blue),
                title: const Text('View Solution'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to solution view
                  print('View solution for: ${item['id']}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.green),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  // Share functionality
                  print('Share item: ${item['id']}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete from History'),
                onTap: () {
                  Navigator.pop(context);
                  // Delete functionality
                  print('Delete item: ${item['id']}');
                  _confirmDelete(item);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete from History'),
          content: Text(_getTranslatedText('general.doubt.history.options.delete.confirm')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Implement actual delete functionality here
                setState(() {
                  historyItems.removeWhere((element) => element['id'] == item['id']);
                });
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _getTranslatedText('general.doubt.history.empty.title'),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selectedSubject != null
                ? _getTranslatedText('general.doubt.history.empty.with_filter')
                : _getTranslatedText('general.doubt.history.empty.no_filter'),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}