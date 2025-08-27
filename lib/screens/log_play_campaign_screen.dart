import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/game_model.dart';
import '../models/campaign_data.dart';
import '../services/play_tracking_service.dart';
import '../services/campaign_service.dart';
import '../utils/theme.dart';

class LogPlayCampaignScreen extends StatefulWidget {
  final GameModel game;
  final CampaignData? campaign;

  const LogPlayCampaignScreen({
    Key? key, 
    required this.game,
    this.campaign,
  }) : super(key: key);

  @override
  State<LogPlayCampaignScreen> createState() => _LogPlayCampaignScreenState();
}

class _LogPlayCampaignScreenState extends State<LogPlayCampaignScreen> {
  late PlayTrackingService _playService;
  late CampaignService _campaignService;
  final _formKey = GlobalKey<FormState>();
  
  // Basic session info
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final _durationController = TextEditingController();
  final _locationController = TextEditingController(text: 'Home');
  final _notesController = TextEditingController();
  
  // Campaign tracking
  bool _isCampaignSession = false;
  final _scenarioController = TextEditingController();
  final _mapController = TextEditingController();
  final _objectivesController = TextEditingController();
  
  // Player tracking
  final List<CampaignPlayerController> _playerControllers = [
    CampaignPlayerController(name: 'You', isYou: true),
  ];
  String? _winner;
  
  // Resources & Items
  final Map<String, TextEditingController> _resourceControllers = {};
  final Map<String, List<String>> _playerItems = {};
  
  // Photos
  final List<File> _photos = [];
  final ImagePicker _imagePicker = ImagePicker();
  
  // Game state
  final Map<String, dynamic> _customFields = {};
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initServices();
    _durationController.text = widget.game.playTime.toString();
    
    if (widget.campaign != null) {
      _isCampaignSession = true;
      _loadCampaignData();
    }
  }

  Future<void> _initServices() async {
    _playService = await PlayTrackingService.getInstance();
    _campaignService = await CampaignService.getInstance();
  }

  void _loadCampaignData() {
    if (widget.campaign != null) {
      _scenarioController.text = widget.campaign!.currentScenario ?? '';
      _mapController.text = widget.campaign!.currentMap ?? '';
      
      // Load player data from campaign
      for (var entry in widget.campaign!.playerProgress.entries) {
        if (entry.key != 'You') {
          _playerControllers.add(
            CampaignPlayerController(
              name: entry.key,
              characterName: entry.value.characterName,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _scenarioController.dispose();
    _mapController.dispose();
    _objectivesController.dispose();
    
    for (final controller in _playerControllers) {
      controller.dispose();
    }
    
    for (final controller in _resourceControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
  }

  void _addPlayer() {
    setState(() {
      _playerControllers.add(CampaignPlayerController());
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _photos.add(File(image.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addResource(String resource) {
    if (!_resourceControllers.containsKey(resource)) {
      setState(() {
        _resourceControllers[resource] = TextEditingController(text: '0');
      });
    }
  }

  void _showAddResourceDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Resource'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Resource Name',
            hintText: 'e.g., Gold, XP, Victory Points',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _addResource(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(String playerName) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Item for $playerName'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Item Name',
            hintText: 'e.g., Sword of Fire, Health Potion',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  if (!_playerItems.containsKey(playerName)) {
                    _playerItems[playerName] = [];
                  }
                  _playerItems[playerName]!.add(controller.text);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
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
        characterName: pc.characterController.text.trim().isNotEmpty 
            ? pc.characterController.text.trim() 
            : null,
      )).toList();
      
      // Process resources
      final resourcesGained = <String, int>{};
      for (var entry in _resourceControllers.entries) {
        final value = int.tryParse(entry.value.text);
        if (value != null && value != 0) {
          resourcesGained[entry.key] = value;
        }
      }
      
      // Process objectives
      final objectives = _objectivesController.text
          .split(',')
          .map((o) => o.trim())
          .where((o) => o.isNotEmpty)
          .toList();
      
      // Upload photos and get URLs (placeholder for now)
      final photoUrls = <String>[];
      for (final photo in _photos) {
        // In production, upload to cloud storage and get URL
        photoUrls.add(photo.path);
      }
      
      // Create enhanced play session
      final session = EnhancedPlaySession(
        sessionId: 'play_${DateTime.now().millisecondsSinceEpoch}',
        gameId: widget.game.gameId,
        gameTitle: widget.game.title,
        userId: 'demo_user',
        playDate: playDate,
        duration: int.parse(_durationController.text),
        players: players,
        winner: _winner,
        location: _locationController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty 
            ? _notesController.text.trim() 
            : null,
        photos: photoUrls,
        status: _isCampaignSession 
            ? PlaySessionStatus.inProgress 
            : PlaySessionStatus.completed,
        campaignId: widget.campaign?.campaignId,
        isCampaignSession: _isCampaignSession,
        sessionNumber: widget.campaign?.currentSession,
        scenario: _scenarioController.text.trim().isNotEmpty 
            ? _scenarioController.text.trim() 
            : null,
        map: _mapController.text.trim().isNotEmpty 
            ? _mapController.text.trim() 
            : null,
        completedObjectives: objectives.isNotEmpty ? objectives : null,
        resourcesGained: resourcesGained.isNotEmpty ? resourcesGained : null,
        itemsFound: _playerItems.isNotEmpty ? _playerItems : null,
        createdAt: DateTime.now(),
      );
      
      // Save the session
      final success = await _campaignService.saveEnhancedSession(session);
      
      // Update campaign if needed
      if (_isCampaignSession && widget.campaign != null) {
        await _campaignService.updateCampaignProgress(
          widget.campaign!.campaignId,
          session,
        );
      }
      
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
            // Campaign Toggle
            _buildCampaignToggle(),
            const SizedBox(height: 24),
            
            // Date and Time
            _buildDateTimeSection(),
            const SizedBox(height: 24),
            
            // Duration and Location
            _buildDetailsSection(),
            const SizedBox(height: 24),
            
            // Campaign-specific fields
            if (_isCampaignSession) ...[
              _buildCampaignSection(),
              const SizedBox(height: 24),
            ],
            
            // Players
            _buildPlayersSection(),
            const SizedBox(height: 24),
            
            // Resources & Items
            if (_isCampaignSession) ...[
              _buildResourcesSection(),
              const SizedBox(height: 24),
              _buildItemsSection(),
              const SizedBox(height: 24),
            ],
            
            // Winner
            _buildWinnerSection(),
            const SizedBox(height: 24),
            
            // Photos
            _buildPhotosSection(),
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

  Widget _buildCampaignToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isCampaignSession 
              ? AppTheme.primaryColor.withOpacity(0.5)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.fort, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Campaign Session',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Track progress, items, and story',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isCampaignSession,
            onChanged: (value) {
              setState(() {
                _isCampaignSession = value;
              });
            },
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Campaign Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _scenarioController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Scenario/Mission',
            labelStyle: TextStyle(color: Colors.grey[600]),
            hintText: 'e.g., Black Barrow, Mission 12',
            prefixIcon: const Icon(Icons.flag, color: AppTheme.primaryColor),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _mapController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Map/Location',
            labelStyle: TextStyle(color: Colors.grey[600]),
            hintText: 'e.g., Gloomhaven, Dungeon Level 3',
            prefixIcon: const Icon(Icons.map, color: AppTheme.primaryColor),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _objectivesController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Completed Objectives',
            labelStyle: TextStyle(color: Colors.grey[600]),
            hintText: 'Comma separated: Kill boss, Find treasure',
            prefixIcon: const Icon(Icons.check_circle, color: AppTheme.primaryColor),
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

  Widget _buildResourcesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Resources Gained',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: _showAddResourceDialog,
              icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_resourceControllers.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Tap + to track resources',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          )
        else
          ..._resourceControllers.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      controller: entry.value,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF2A2A2A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        entry.value.dispose();
                        _resourceControllers.remove(entry.key);
                      });
                    },
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Items Found',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._playerControllers.map((pc) {
          final playerName = pc.nameController.text.trim();
          if (playerName.isEmpty) return const SizedBox.shrink();
          
          final items = _playerItems[playerName] ?? [];
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      playerName,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showAddItemDialog(playerName),
                      icon: const Icon(Icons.add, color: AppTheme.primaryColor, size: 20),
                    ),
                  ],
                ),
                if (items.isEmpty)
                  Text(
                    'No items',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: items.map((item) {
                      return Chip(
                        label: Text(item),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            _playerItems[playerName]!.remove(item);
                          });
                        },
                        backgroundColor: Colors.blue.withOpacity(0.2),
                        labelStyle: const TextStyle(color: Colors.white),
                      );
                    }).toList(),
                  ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Session Photos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: _showPhotoOptions,
              icon: const Icon(Icons.add_a_photo, color: AppTheme.primaryColor),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_photos.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.photo_camera, color: Colors.grey[600], size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Add photos to remember this session',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: FileImage(_photos[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _photos.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
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
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
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
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (time != null) {
                    setState(() => _selectedTime = time);
                  }
                },
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
            child: Column(
              children: [
                Row(
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
                if (_isCampaignSession) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: controller.characterController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Character Name',
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      hintText: 'e.g., Mindthief, Red Guard',
                      prefixIcon: const Icon(Icons.badge, color: AppTheme.primaryColor),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
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
              'Select winner (optional)',
              style: TextStyle(color: Colors.grey),
            ),
            dropdownColor: const Color(0xFF2A2A2A),
            style: const TextStyle(color: Colors.white),
            underline: const SizedBox(),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('No winner / Cooperative'),
              ),
              ...playerNames.map((name) {
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
            ],
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
          'Session Notes',
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
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Story progress, memorable moments, strategy notes...',
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

class CampaignPlayerController {
  final TextEditingController nameController;
  final TextEditingController scoreController;
  final TextEditingController characterController;
  final bool isYou;
  
  CampaignPlayerController({
    String? name, 
    String? characterName,
    this.isYou = false,
  }) : nameController = TextEditingController(text: name ?? ''),
       scoreController = TextEditingController(),
       characterController = TextEditingController(text: characterName ?? '');
  
  void dispose() {
    nameController.dispose();
    scoreController.dispose();
    characterController.dispose();
  }
}