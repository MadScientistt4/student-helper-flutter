import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

void main() {
  runApp(StudentApp());
}

class StudentApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Helper',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    ToDoListScreen(),
    DiscussionForumScreen(),
    PomodoroTimerScreen(),
    NotesOrganizerScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Student Helper')),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'To-Do'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Forum'),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Pomodoro'),
          BottomNavigationBarItem(icon: Icon(Icons.note), label: 'Notes'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

// ---------------------- To-Do List ----------------------
class ToDoListScreen extends StatefulWidget {
  @override
  _ToDoListScreenState createState() => _ToDoListScreenState();
}

class _ToDoListScreenState extends State<ToDoListScreen> {
  List tasks = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    final response = await http.get(Uri.parse('http://127.0.0.1:5000/tasks'));
    if (response.statusCode == 200) {
      setState(() {
        tasks = json.decode(response.body);
      });
    }
  }

  Future<void> addTask(String title) async {
    if (title.isEmpty) return;
    await http.post(
      Uri.parse('http://127.0.0.1:5000/tasks'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'title': title}),
    );
    _controller.clear();
    fetchTasks();
  }

  Future<void> deleteTask(int taskId) async {
    await http.delete(Uri.parse('http://127.0.0.1:5000/tasks/$taskId'));
    fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Input for new task
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(hintText: 'Enter a task'),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () => addTask(_controller.text),
              ),
            ],
          ),
        ),
        // Display the tasks
        Expanded(
          child: ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return ListTile(
                title: Text(task['title']),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => deleteTask(task['id']),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------- Discussion Forum ---------------------
class DiscussionForumScreen extends StatefulWidget {
  @override
  _DiscussionForumScreenState createState() => _DiscussionForumScreenState();
}

class _DiscussionForumScreenState extends State<DiscussionForumScreen> {
  List forums = [];
  final TextEditingController _forumController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchForums();
  }

  Future<void> fetchForums() async {
    final response = await http.get(Uri.parse('http://127.0.0.1:5000/forums'));
    if (response.statusCode == 200) {
      setState(() {
        forums = json.decode(response.body);
      });
    }
  }

  Future<void> createForum(String name) async {
    if (name.isEmpty) return;
    await http.post(
      Uri.parse('http://127.0.0.1:5000/forums'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name}),
    );
    _forumController.clear();
    fetchForums();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Input for new forum
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _forumController,
                  decoration: InputDecoration(hintText: 'Enter forum name'),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () => createForum(_forumController.text),
              ),
            ],
          ),
        ),
        // List of forums
        Expanded(
          child: ListView.builder(
            itemCount: forums.length,
            itemBuilder: (context, index) {
              final forum = forums[index];
              return ListTile(
                title: Text(forum['name']),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        forumId: forum['id'],
                        forumName: forum['name'],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// Chat screen for a specific forum
class ChatScreen extends StatefulWidget {
  final int forumId;
  final String forumName;

  ChatScreen({required this.forumId, required this.forumName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List messages = [];
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  Future<void> fetchMessages() async {
    final response = await http.get(Uri.parse(
        'http://127.0.0.1:5000/forums/${widget.forumId}/messages'));
    if (response.statusCode == 200) {
      setState(() {
        messages = json.decode(response.body);
      });
    }
  }

  Future<void> sendMessage() async {
    if (_messageController.text.isEmpty) return;
    await http.post(
      Uri.parse('http://127.0.0.1:5000/forums/${widget.forumId}/messages'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'content': _messageController.text}),
    );
    _messageController.clear();
    fetchMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.forumName)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(messages[index]['content']));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(hintText: 'Enter message'),
                  ),
                ),
                IconButton(icon: Icon(Icons.send), onPressed: sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- Pomodoro Timer ---------------------
class PomodoroTimerScreen extends StatefulWidget {
  @override
  _PomodoroTimerScreenState createState() => _PomodoroTimerScreenState();
}

class _PomodoroTimerScreenState extends State<PomodoroTimerScreen>
    with AutomaticKeepAliveClientMixin {
  static const int workTime = 25 * 60;
  static const int breakTime = 5 * 60;
  int _timeLeft = workTime;
  bool _isRunning = false;
  Timer? _timer;
  DateTime? _startTime;

  @override
  bool get wantKeepAlive => true; // Keeps the widget alive when switching tabs

  void _startTimer() {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      _startTime = DateTime.now();
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          timer.cancel();
          _isRunning = false;
          _timeLeft = breakTime;
        }
      });
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _timeLeft = workTime;
      _startTime = null;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "${(_timeLeft ~/ 60).toString().padLeft(2, '0')}:${(_timeLeft % 60).toString().padLeft(2, '0')}",
            style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
          ),
          if (_isRunning && _startTime != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                "Started at: ${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:${_startTime!.second.toString().padLeft(2, '0')}",
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
            ),
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _startTimer,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text("Start", style: TextStyle(fontSize: 18)),
              ),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: _resetTimer,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text("Reset", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------- Notes Organizer ---------------------
class NotesOrganizerScreen extends StatefulWidget {
  @override
  _NotesOrganizerScreenState createState() => _NotesOrganizerScreenState();
}

class _NotesOrganizerScreenState extends State<NotesOrganizerScreen> {
  List notes = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchNotes();
  }

  Future<void> fetchNotes() async {
    final response = await http.get(Uri.parse('http://127.0.0.1:5000/notes'));
    if (response.statusCode == 200) {
      setState(() {
        notes = json.decode(response.body);
      });
    }
  }

  Future<void> addTextNote() async {
    String title = _titleController.text;
    if (title.isEmpty) return;
    await http.post(
      Uri.parse('http://127.0.0.1:5000/notes'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'title': title, 'content': _contentController.text}),
    );
    _titleController.clear();
    _contentController.clear();
    fetchNotes();
  }

  Future<void> deleteNote(int noteId) async {
    await http.delete(Uri.parse('http://127.0.0.1:5000/notes/$noteId'));
    fetchNotes();
  }

  Future<void> uploadPdfNote() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      var file = result.files.first;
      var uri = Uri.parse('http://127.0.0.1:5000/notes');
      var request = http.MultipartRequest('POST', uri);
      request.fields['title'] = _titleController.text.isNotEmpty
          ? _titleController.text
          : 'Untitled';

      if (file.bytes != null) {
        // On web, use bytes
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ));
      } else if (file.path != null) {
        // On mobile/desktop, use file path
        request.files.add(await http.MultipartFile.fromPath('file', file.path!));
      }

      var response = await request.send();
      if (response.statusCode == 201) {
        _titleController.clear();
        _contentController.clear();
        fetchNotes();
      } else {
        print('Failed to upload PDF note');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Note input fields and buttons
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Note Title'),
              ),
              TextField(
                controller: _contentController,
                decoration: InputDecoration(labelText: 'Note Content'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: addTextNote,
                    child: Text('Add Text Note'),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: uploadPdfNote,
                    child: Text('Upload PDF'),
                  ),
                ],
              ),
            ],
          ),
        ),
        // List of notes
        Expanded(
          child: ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              bool isPdfNote = note['pdf_filename'] != null && note['pdf_filename'] != '';
              return ListTile(
                title: Text(note['title']),
                subtitle: Text(isPdfNote
                    ? 'PDF: ${note['pdf_filename']}'
                    : (note['content'] ?? '')),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => deleteNote(note['id']),
                ),
                onTap: isPdfNote
                    ? () {
                  // Navigate to PDF viewer screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfViewerScreen(
                        pdfUrl: 'http://127.0.0.1:5000/uploads/${note['pdf_filename']}',
                      ),
                    ),
                  );
                }
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------- PDF Viewer Screen ---------------------
class PdfViewerScreen extends StatelessWidget {
  final String pdfUrl;

  PdfViewerScreen({required this.pdfUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("PDF Viewer")),
      body: SfPdfViewer.network(
        pdfUrl,
        key: GlobalKey(),  // Ensure proper state management
      ),
    );
  }
}
