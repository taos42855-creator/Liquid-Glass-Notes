import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const LiquidNotesApp());
}

class LiquidNotesApp extends StatelessWidget {
  const LiquidNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liquid Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const NotesScreen(),
    );
  }
}

class Note {
  String id;
  String title;
  String content;
  DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Note.fromMap(Map<String, dynamic> map) => Note(
        id: map['id'],
        title: map['title'],
        content: map['content'],
        updatedAt: DateTime.parse(map['updatedAt']),
      );
}

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Note> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList('saved_notes') ?? [];
    setState(() {
      _notes = rawList
          .map((item) => Note.fromMap(jsonDecode(item)))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = _notes.map((n) => jsonEncode(n.toMap())).toList();
    await prefs.setStringList('saved_notes', rawList);
  }

  void _addOrEditNote([Note? note]) {
    final titleController = TextEditingController(text: note?.title ?? '');
    final contentController = TextEditingController(text: note?.content ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: LiquidGlassCard(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: '标题...',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                  ),
                ),
                const Divider(color: Colors.white12),
                TextField(
                  controller: contentController,
                  maxLines: 6,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: '写下你的灵感...',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消', style: TextStyle(color: Colors.white54)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        if (titleController.text.isEmpty && contentController.text.isEmpty) {
                          Navigator.pop(ctx);
                          return;
                        }
                        setState(() {
                          if (note != null) {
                            note.title = titleController.text;
                            note.content = contentController.text;
                            note.updatedAt = DateTime.now();
                          } else {
                            _notes.insert(
                              0,
                              Note(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                title: titleController.text.isEmpty ? '未命名便签' : titleController.text,
                                content: contentController.text,
                                updatedAt: DateTime.now(),
                              ),
                            );
                          }
                        });
                        _saveNotes();
                        Navigator.pop(ctx);
                      },
                      child: const Text('保存', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteNote(int index) {
    setState(() {
      _notes.removeAt(index);
    });
    _saveNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景液态流动色彩球
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.8, -0.6),
                radius: 1.2,
                colors: [Color(0xFF7928CA), Colors.black],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [const Color(0xFFFF0080).withOpacity(0.4), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '便签',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 28, color: Colors.white),
                        onPressed: () => _addOrEditNote(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _notes.isEmpty
                      ? const Center(
                          child: Text('点击右上角 + 开始记录', style: TextStyle(color: Colors.white38)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _notes.length,
                          itemBuilder: (context, index) {
                            final item = _notes[index];
                            final dateStr = DateFormat('MM-dd HH:mm').format(item.updatedAt);
                            return Dismissible(
                              key: Key(item.id),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) => _deleteNote(index),
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.delete, color: Colors.redAccent),
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: LiquidGlassCard(
                                  borderRadius: BorderRadius.circular(20),
                                  padding: const EdgeInsets.all(16),
                                  onTap: () => _addOrEditNote(item),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.content,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        dateStr,
                                        style: const TextStyle(fontSize: 11, color: Colors.white38),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 核心组件：苹果液态毛玻璃容器 (Glassmorphism)
class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);
    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18), // 高斯模糊
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08), // 半透明液态白
              borderRadius: radius,
              border: Border.all(
                color: Colors.white.withOpacity(0.18), // 苹果特有的微光细边框
                width: 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
