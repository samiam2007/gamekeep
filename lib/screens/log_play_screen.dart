import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_model.dart';
import '../models/play_session_model.dart';
import '../services/play_tracking_service.dart';
import '../utils/theme.dart';

class LogPlayScreen extends StatefulWidget {
  final GameModel game;

  const LogPlayScreen({Key? key, required this.game}) : super(key: key);

  @override
  State<LogPlayScreen> createState() => _LogPlayScreenState();
}

class _LogPlayScreenState extends State<LogPlayScreen> {
  late PlayTrackingService _playService;
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final _durationController = TextEditingController();
  final _locationController = TextEditingController(text: 'Home');
  final _notesController = TextEditingController();
  final List<PlayerController> _playerControllers = [
    PlayerController(name: 'You', isYou: true),
  ];
  String? _winner;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initService();
    // Set default duration based on game's typical play time
    _durationController.text = widget.game.playTime.toString();
  }

  Future<void> _initService() async {
    _playService = await PlayTrackingService.getInstance();
  }

  @override
  void dispose() {
    _durationController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    for (final controller in _playerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addPlayer() {
    setState(() {
      _playerControllers.add(PlayerController());
    });
  }

  void _removePlayer(int index) {
    if (_playerControllers.length > 1 && index > 0) {
      setState(() {
        _playerControllers[index].dispose();
        _playerControllers.removeAt(index);
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _savePlaySession() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Combine date and time
      final playDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      
      // Create players list
      final players = _playerControllers.map((pc) => Player(
        name: pc.nameController.text.trim(),
        score: int.tryParse(pc.scoreController.text),
        isWinner: pc.nameController.text.trim() == _winner,
      )).toList();
      
      // Find your score
      final yourScore = _playerControllers.first.scoreController.text.isNotEmpty
          ? int.tryParse(_playerControllers.first.scoreController.text)
          : null;
      
      // Find high score
      int? highScore;
      for (final pc in _playerControllers) {
        final score = int.tryParse(pc.scoreController.text);
        if (score != null && (highScore == null || score > highScore)) {
          highScore = score;
        }
      }
      
      // Create play session
      final session = PlaySession(
        sessionId: 'play_${DateTime.now().millisecondsSinceEpoch}',
        gameId: widget.game.gameId,
        gameTitle: widget.game.title,
        userId: 'demo_user',
        playDate: playDate,
        duration: int.parse(_durationController.text),
        players: players,
        winner: _winner,
        yourScore: yourScore,
        highScore: highScore,
        location: _locationController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty 
            ? _notesController.text.trim() 
            : null,
        createdAt: DateTime.now(),
      );
      
      // Save the session
      final success = await _playService.logPlay(session);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Play session logged successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving play session: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text('Log Play: ${widget.game.title}'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _savePlaySession,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date and Time
            _buildDateTimeSection(),
            const SizedBox(height: 24),
            
            // Duration and Location
            _buildDetailsSection(),
            const SizedBox(height: 24),
            
            // Players
            _buildPlayersSection(),
            const SizedBox(height: 24),
            
            // Winner
            _buildWinnerSection(),
            const SizedBox(height: 24),
            
            // Notes
            _buildNotesSection(),
            const SizedBox(height: 40),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _savePlaySession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Log Play Session',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'When did you play?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInputCard(
                onTap: _selectDate,
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInputCard(
                onTap: _selectTime,
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      _selectedTime.format(context),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Game Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Duration (minutes)',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.timer, color: AppTheme.primaryColor),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter duration';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _locationController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Location',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.location_on, color: AppTheme.primaryColor),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter location';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Players',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: _addPlayer,
              icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._playerControllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: controller.nameController,
                    enabled: !controller.isYou,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Player ${index + 1}',
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: Icon(
                        Icons.person,
                        color: controller.isYou ? Colors.green : AppTheme.primaryColor,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Name required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: controller.scoreController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Score',
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                if (index > 0) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _removePlayer(index),
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildWinnerSection() {
    final playerNames = _playerControllers
        .map((pc) => pc.nameController.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Who won?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<String>(
            isExpanded: true,
            value: _winner,
            hint: const Text(
              'Select winner',
              style: TextStyle(color: Colors.grey),
            ),
            dropdownColor: const Color(0xFF2A2A2A),
            style: const TextStyle(color: Colors.white),
            underline: const SizedBox(),
            items: playerNames.map((name) {
              return DropdownMenuItem(
                value: name,
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: name == _winner ? Colors.amber : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(name),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _winner = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes (Optional)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _notesController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Any memorable moments or strategies?',
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard({required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }
}

class PlayerController {
  final TextEditingController nameController;
  final TextEditingController scoreController;
  final bool isYou;
  
  PlayerController({String? name, this.isYou = false})
      : nameController = TextEditingController(text: name ?? ''),
        scoreController = TextEditingController();
  
  void dispose() {
    nameController.dispose();
    scoreController.dispose();
  }
}