import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  static const String _themeKey = 'selected_theme';
  int _themeIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_themeKey) ?? 0;
      if (mounted) {
        setState(() {
          _themeIndex = saved;
        });
      }
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  Future<void> _saveTheme(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, index);
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  void _changeTheme(int index) {
    setState(() {
      _themeIndex = index;
    });
    _saveTheme(index);
  }

  ThemeData _buildTheme() {
    switch (_themeIndex) {
      case 1:
        return _darkTheme();
      case 2:
        return _babyBlueTheme();
      case 3:
        return _greenTheme();
      default:
        return _darkRedTheme();
    }
  }

  ThemeData _darkRedTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8B0000),
        primary: const Color(0xFF8B0000),
        secondary: const Color(0xFF89CFF0),
        surface: const Color(0xFFF0F8FF),
      ),
      useMaterial3: true,
      fontFamily: 'Segoe UI',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF8B0000),
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
      ),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A1A1A),
        brightness: Brightness.dark,
        primary: const Color(0xFFE0E0E0),
        secondary: const Color(0xFF89CFF0),
        surface: const Color(0xFF121212),
        onSurface: const Color(0xFFE0E0E0),
      ),
      useMaterial3: true,
      fontFamily: 'Segoe UI',
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: const Color(0xFFE0E0E0),
        elevation: 4,
        centerTitle: true,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
    );
  }

  ThemeData _babyBlueTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF89CFF0),
        brightness: Brightness.light,
        primary: const Color(0xFF89CFF0),
        secondary: const Color(0xFF8B0000),
        surface: const Color(0xFFF0F8FF),
        onSurface: const Color(0xFF2C3E50),
      ),
      useMaterial3: true,
      fontFamily: 'Segoe UI',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF89CFF0),
        foregroundColor: Color(0xFF1A1A1A),
        elevation: 4,
        centerTitle: true,
      ),
      scaffoldBackgroundColor: const Color(0xFFF0F8FF),
    );
  }

  ThemeData _greenTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E7D32),
        brightness: Brightness.light,
        primary: const Color(0xFF2E7D32),
        secondary: const Color(0xFF81C784),
        surface: const Color(0xFFE8F5E9),
        onSurface: const Color(0xFF1B5E20),
      ),
      useMaterial3: true,
      fontFamily: 'Segoe UI',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
      ),
      scaffoldBackgroundColor: const Color(0xFFE8F5E9),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: TodoHomePage(
        themeIndex: _themeIndex,
        onThemeChanged: _changeTheme,
      ),
    );
  }
}

class TodoHomePage extends StatefulWidget {
  final int themeIndex;
  final ValueChanged<int> onThemeChanged;

  const TodoHomePage({
    super.key,
    required this.themeIndex,
    required this.onThemeChanged,
  });

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  final List<TodoItem> _todos = [];
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  DateTime _currentTime = DateTime.now();
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadTodos();
    _currentTime = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startTimeTimer();
  }

  void _startTimeTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
      return mounted;
    });
  }

  double get _progress {
    if (_todos.isEmpty) return 0.0;
    final done = _todos.where((t) => t.isDone).length;
    return done / _todos.length;
  }

  String get _progressText {
    if (_todos.isEmpty) return '0%';
    final percent = (_progress * 100).round();
    return '$percent%';
  }

  int get _doneCount => _todos.where((t) => t.isDone).length;
  int get _pendingCount =>
      _todos.where((t) => !t.isDone && !t.isSkipped).length;
  int get _skippedCount => _todos.where((t) => t.isSkipped).length;

  bool _isSkipped(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    return diff.inDays >= 1;
  }

  Future<void> _loadTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? todosJson = prefs.getString('todos');
      if (todosJson != null && mounted) {
        final List<dynamic> decoded = json.decode(todosJson);
        setState(() {
          _todos.clear();
          _todos.addAll(decoded.map((item) => TodoItem.fromJson(item)));
          for (final todo in _todos) {
            if (!todo.isDone && !todo.isSkipped && _isSkipped(todo.createdAt)) {
              todo.isSkipped = true;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading todos: $e');
    }
  }

  Future<void> _saveTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded =
          json.encode(_todos.map((t) => t.toJson()).toList());
      await prefs.setString('todos', encoded);
    } catch (e) {
      debugPrint('Error saving todos: $e');
    }
  }

  void _addTodo(String title) {
    if (title.trim().isEmpty) return;
    setState(() {
      _todos.add(TodoItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title.trim(),
        createdAt: DateTime.now(),
      ));
    });
    _textController.clear();
    _focusNode.unfocus();
    _saveTodos();
  }

  void _toggleTodo(TodoItem item) {
    setState(() {
      item.isDone = !item.isDone;
    });
    _saveTodos();
  }

  void _skipTodo(TodoItem item) {
    setState(() {
      item.isSkipped = true;
    });
    _saveTodos();
  }

  void _deleteTodo(TodoItem item) {
    setState(() {
      _todos.remove(item);
    });
    _saveTodos();
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeOption(
              title: 'Red',
              subtitle: 'Classic dark red with baby blue accents',
              isSelected: widget.themeIndex == 0,
              onTap: () {
                widget.onThemeChanged(0);
                Navigator.pop(context);
              },
              color: const Color(0xFF8B0000),
            ),
            const SizedBox(height: 12),
            _ThemeOption(
              title: 'Dark',
              subtitle: 'Easy on the eyes dark mode',
              isSelected: widget.themeIndex == 1,
              onTap: () {
                widget.onThemeChanged(1);
                Navigator.pop(context);
              },
              color: const Color(0xFF1A1A1A),
            ),
            const SizedBox(height: 12),
            _ThemeOption(
              title: 'Baby Blue',
              subtitle: 'Light and fresh baby blue theme',
              isSelected: widget.themeIndex == 2,
              onTap: () {
                widget.onThemeChanged(2);
                Navigator.pop(context);
              },
              color: const Color(0xFF89CFF0),
            ),
            const SizedBox(height: 12),
            _ThemeOption(
              title: 'Green',
              subtitle: 'Fresh green nature theme',
              isSelected: widget.themeIndex == 3,
              onTap: () {
                widget.onThemeChanged(3);
                Navigator.pop(context);
              },
              color: const Color(0xFF2E7D32),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPrimaryColor() {
    final scheme = Theme.of(context).colorScheme;
    return scheme.primary;
  }

  Color _getSecondaryColor() {
    final scheme = Theme.of(context).colorScheme;
    return scheme.secondary;
  }

  Color _getSurfaceColor() {
    final scheme = Theme.of(context).colorScheme;
    return scheme.surface;
  }

  bool get _isDarkMode => widget.themeIndex == 1;

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getPrimaryColor();
    final secondaryColor = _getSecondaryColor();
    final surfaceColor = _getSurfaceColor();
    final isDark = _isDarkMode;

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: Text(
          'To-Do List',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: isDark ? const Color(0xFFE0E0E0) : Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.themeIndex == 1 ? Icons.light_mode : Icons.dark_mode,
              color: isDark ? const Color(0xFFE0E0E0) : Colors.white,
            ),
            onPressed: _showThemeDialog,
            tooltip: 'Change theme',
          ),
          if (_todos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFFE0E0E0) : Colors.white)
                        .withAlpha(51),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (isDark ? const Color(0xFFE0E0E0) : Colors.white)
                          .withAlpha(77),
                    ),
                  ),
                  child: Text(
                    '$_pendingCount pending',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFFE0E0E0) : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildDateTimeHeader(isDark: isDark),
          _buildProgressSection(
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            isDark: isDark,
          ),
          _buildFilterChips(primaryColor: primaryColor, isDark: isDark),
          _buildInputSection(
              primaryColor: primaryColor,
              secondaryColor: secondaryColor,
              isDark: isDark),
          Divider(
            height: 1,
            thickness: 1,
            color: secondaryColor.withAlpha(128),
          ),
          Expanded(
              child: _buildTodoList(
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                  isDark: isDark)),
        ],
      ),
    );
  }

  Widget _buildDateTimeHeader({required bool isDark}) {
    final dayName = _getDayName(_currentTime.weekday);
    final dateStr =
        '${_currentTime.day.toString().padLeft(2, '0')}/${_currentTime.month.toString().padLeft(2, '0')}/${_currentTime.year}';
    final timeStr =
        '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}:${_currentTime.second.toString().padLeft(2, '0')}';

    final titleColor =
        isDark ? const Color(0xFFE0E0E0) : const Color(0xFF8B0000);
    final subtitleColor =
        (isDark ? const Color(0xFFE0E0E0) : const Color(0xFF8B0000))
            .withAlpha(153);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dayName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 14,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF333333), const Color(0xFF1A1A1A)]
                    : [const Color(0xFF8B0000), const Color(0xFFB22222)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (isDark
                          ? const Color(0xFFE0E0E0)
                          : const Color(0xFF8B0000))
                      .withAlpha(102),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              timeStr,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFE0E0E0) : Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection({
    required Color primaryColor,
    required Color secondaryColor,
    required bool isDark,
  }) {
    final progress = _progress;
    final doneCount = _doneCount;
    final pendingCount = _pendingCount;
    final skippedCount = _skippedCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: secondaryColor.withAlpha(51),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              Text(
                _progressText,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: secondaryColor.withAlpha(51),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? secondaryColor : primaryColor,
              ),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatChip(
                label: 'Done',
                count: doneCount,
                color: secondaryColor,
                isDark: isDark,
              ),
              _buildStatChip(
                label: 'Left',
                count: pendingCount,
                color: primaryColor,
                isDark: isDark,
              ),
              _buildStatChip(
                label: 'Skipped',
                count: skippedCount,
                color: const Color(0xFFFF8C00),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required int count,
    required Color color,
    required bool isDark,
  }) {
    final textColor = isDark ? color.withAlpha(220) : color;
    final bgColor = isDark ? color.withAlpha(40) : color.withAlpha(25);
    final borderColor = isDark ? color.withAlpha(100) : color.withAlpha(77);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  Widget _buildFilterChips({
    required Color primaryColor,
    required bool isDark,
  }) {
    final filters = ['All', 'Done', 'Skipped'];
    final chipBg = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final selectedBg = primaryColor;
    final labelColor = isDark ? const Color(0xFFE0E0E0) : primaryColor;
    final borderColor = primaryColor.withAlpha(128);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _filter == filter;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _filter = filter;
                  });
                },
                selectedColor: selectedBg,
                labelStyle: TextStyle(
                  color: isSelected
                      ? (isDark ? const Color(0xFF121212) : Colors.white)
                      : labelColor,
                  fontWeight: FontWeight.w600,
                ),
                checkmarkColor: isDark ? const Color(0xFF121212) : Colors.white,
                backgroundColor: chipBg,
                side: BorderSide(color: borderColor),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputSection({
    required Color primaryColor,
    required Color secondaryColor,
    required bool isDark,
  }) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final hintColor = isDark
        ? const Color(0xFF89CFF0).withAlpha(179)
        : const Color(0xFF89CFF0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF121212), const Color(0xFF1A1A1A)]
              : [const Color(0xFFF0F8FF), const Color(0xFFE0F0FF)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: secondaryColor.withAlpha(isDark ? 26 : 51),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Add a new task...',
                  hintStyle: TextStyle(
                    color: hintColor,
                    fontSize: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: primaryColor,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  filled: true,
                  fillColor: cardColor,
                ),
                onSubmitted: _addTodo,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF333333), const Color(0xFF1A1A1A)]
                    : [const Color(0xFF8B0000), const Color(0xFFB22222)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withAlpha(isDark ? 77 : 102),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.add_circle,
                size: 28,
                color: isDark ? const Color(0xFFE0E0E0) : Colors.white,
              ),
              onPressed: () => _addTodo(_textController.text),
              tooltip: 'Add task',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoList({
    required Color primaryColor,
    required Color secondaryColor,
    required bool isDark,
  }) {
    final filteredTodos = _getFilteredTodos();

    if (filteredTodos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 100,
              color: secondaryColor.withAlpha(179),
            ),
            const SizedBox(height: 20),
            Text(
              _getEmptyMessage(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: primaryColor.withAlpha(153),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptySubMessage(),
              style: TextStyle(
                fontSize: 15,
                color: primaryColor.withAlpha(102),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: filteredTodos.length,
      itemBuilder: (context, index) {
        final todo = filteredTodos[index];
        final isSkipped = todo.isSkipped;
        return Dismissible(
          key: Key(todo.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF333333), const Color(0xFF1A1A1A)]
                    : [const Color(0xFF8B0000), const Color(0xFFB22222)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: Icon(
              Icons.delete_forever,
              color: isDark ? const Color(0xFFE0E0E0) : Colors.white,
              size: 28,
            ),
          ),
          onDismissed: (_) => _deleteTodo(todo),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isSkipped
                  ? (isDark ? const Color(0xFF3E2723) : const Color(0xFFFFF8E1))
                  : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: isSkipped
                  ? Border.all(
                      color: isDark
                          ? const Color(0xFFFF8C00).withAlpha(128)
                          : const Color(0xFFFF8C00).withAlpha(128),
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: secondaryColor.withAlpha(isDark ? 26 : 38),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: todo.isDone
                        ? secondaryColor
                        : isSkipped
                            ? const Color(0xFFFF8C00)
                            : primaryColor,
                    width: 2.5,
                  ),
                  color: todo.isDone ? secondaryColor : Colors.transparent,
                ),
                child: todo.isDone
                    ? Icon(
                        Icons.check,
                        size: 18,
                        color: isDark ? const Color(0xFF121212) : Colors.white,
                      )
                    : null,
              ),
              title: Text(
                todo.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: todo.isDone
                      ? primaryColor.withAlpha(isDark ? 130 : 89)
                      : (isDark
                          ? const Color(0xFFE0E0E0)
                          : const Color(0xFF2C3E50)),
                  decoration: todo.isDone ? TextDecoration.lineThrough : null,
                  decorationColor: secondaryColor,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Text(
                      _formatDate(todo.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: todo.isDone
                            ? primaryColor.withAlpha(isDark ? 100 : 64)
                            : secondaryColor,
                      ),
                    ),
                    if (isSkipped) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8C00).withAlpha(
                            isDark ? 64 : 51,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Skipped',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF8C00),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      todo.isDone ? Icons.undo : Icons.check_circle_outline,
                      size: 24,
                      color: todo.isDone ? secondaryColor : primaryColor,
                    ),
                    onPressed: () => _toggleTodo(todo),
                    tooltip: todo.isDone ? 'Undo' : 'Complete',
                  ),
                  if (!todo.isDone && !todo.isSkipped)
                    IconButton(
                      icon: Icon(
                        Icons.skip_next_rounded,
                        size: 24,
                        color: const Color(0xFFFF8C00),
                      ),
                      onPressed: () => _skipTodo(todo),
                      tooltip: 'Skip',
                    ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 22,
                      color: primaryColor,
                    ),
                    onPressed: () => _deleteTodo(todo),
                    tooltip: 'Delete',
                  ),
                ],
              ),
              onTap: () => _toggleTodo(todo),
            ),
          ),
        );
      },
    );
  }

  List<TodoItem> _getFilteredTodos() {
    switch (_filter) {
      case 'Done':
        return _todos.where((t) => t.isDone).toList();
      case 'Skipped':
        return _todos.where((t) => t.isSkipped).toList();
      default:
        return _todos.where((t) => !t.isDone && !t.isSkipped).toList();
    }
  }

  String _getEmptyMessage() {
    switch (_filter) {
      case 'Done':
        return 'No done tasks yet!';
      case 'Skipped':
        return 'No skipped tasks!';
      default:
        return 'No tasks yet!';
    }
  }

  String _getEmptySubMessage() {
    switch (_filter) {
      case 'Done':
        return 'Complete some tasks to see them here';
      case 'Skipped':
        return 'Tasks older than 1 day will appear here';
      default:
        return 'Add a task above to get started';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Colors.grey.withAlpha(128),
            width: isSelected ? 2.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? color.withAlpha(25) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 28),
          ],
        ),
      ),
    );
  }
}

class TodoItem {
  final String id;
  final String title;
  bool isDone;
  bool isSkipped;
  final DateTime createdAt;

  TodoItem({
    required this.id,
    required this.title,
    this.isDone = false,
    this.isSkipped = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isDone': isDone,
        'isSkipped': isSkipped,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        isDone: json['isDone'] as bool? ?? false,
        isSkipped: json['isSkipped'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
