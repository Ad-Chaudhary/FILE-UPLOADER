import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';

void main() {
  runApp(const MyApp());
}

// ================= MODEL =================

class NoteFile {
  final String name;
  final int size;
  final DateTime date;
  final String path;

  NoteFile({
    required this.name,
    required this.size,
    required this.date,
    required this.path,
  });
}

// ================= APP =================

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<NoteFile> notes = [];

  void addNote(NoteFile note) {
    setState(() {
      notes.insert(0, note);
    });
  }

  void deleteNote(int index) {
    setState(() {
      notes.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Notes App",
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: HomePage(
        notes: notes,
        addNote: addNote,
        deleteNote: deleteNote,
      ),
    );
  }
}

// ================= HOME =================

class HomePage extends StatefulWidget {
  final List<NoteFile> notes;
  final Function(NoteFile) addNote;
  final Function(int) deleteNote;

  const HomePage({
    super.key,
    required this.notes,
    required this.addNote,
    required this.deleteNote,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String search = "";

  @override
  Widget build(BuildContext context) {
    final filtered = widget.notes
        .where((n) =>
            n.name.toLowerCase().contains(search.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("📂 My Notes"),
        centerTitle: true,
        elevation: 2,
      ),

      // ================= BODY =================
      body: Column(
        children: [
          // 🔍 Search Box
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search files...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() => search = val);
              },
            ),
          ),

          // 📄 File List
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      "No files uploaded yet 📭",
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final note = filtered[index];

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),

                          leading: CircleAvatar(
                            backgroundColor:
                                Colors.indigo.withOpacity(0.1),
                            child: const Icon(Icons.insert_drive_file,
                                color: Colors.indigo),
                          ),

                          title: Text(
                            note.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          subtitle: Text(
                            "${note.size} KB • ${note.date.toString().split(' ')[0]}",
                          ),

                          // 🔥 OPEN FILE
                          onTap: () async {
                            if (note.path.contains("/")) {
                              final result =
                                  await OpenFile.open(note.path);

                              if (result.type != ResultType.done) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text("Cannot open file")),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Opening not supported on Web")),
                              );
                            }
                          },

                          trailing: IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            onPressed: () {
                              widget.deleteNote(
                                  widget.notes.indexOf(note));
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // ➕ FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const UploadPage(),
            ),
          );

          if (result != null && result is NoteFile) {
            widget.addNote(result);
          }
        },
        icon: const Icon(Icons.upload_file),
        label: const Text("Upload"),
      ),
    );
  }
}

// ================= UPLOAD =================

class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

  Future<void> pickFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null) {
      final file = result.files.first;

      final note = NoteFile(
        name: file.name,
        size: file.size ~/ 1024,
        date: DateTime.now(),
        path: file.path ?? file.name, // ✅ WEB FIX
      );

      Navigator.pop(context, note);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No file selected")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload File")),
      body: Center(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => pickFile(context),
          icon: const Icon(Icons.attach_file),
          label: const Text("Choose File"),
        ),
      ),
    );
  }
}