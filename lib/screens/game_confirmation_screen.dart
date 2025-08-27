import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../services/bgg_service.dart';
import '../models/game_model.dart';

class GameConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> extractedData;
  final String? imagePath;

  const GameConfirmationScreen({
    Key? key,
    required this.extractedData,
    this.imagePath,
  }) : super(key: key);

  @override
  State<GameConfirmationScreen> createState() => _GameConfirmationScreenState();
}

class _GameConfirmationScreenState extends State<GameConfirmationScreen> {
  late TextEditingController _titleController;
  late TextEditingController _publisherController;
  late TextEditingController _playersController;
  late TextEditingController _playTimeController;
  late double _confidence;
  
  final BGGService _bggService = BGGService();
  List<BGGGameMatch> _bggMatches = [];
  BGGGameMatch? _selectedMatch;
  bool _isSearching = false;
  bool _autoSearchCompleted = false;

  @override
  void initState() {
    super.initState();
    _confidence = (widget.extractedData['confidence'] ?? 0.0) * 100;
    _titleController = TextEditingController(text: widget.extractedData['title'] ?? '');
    _publisherController = TextEditingController(text: widget.extractedData['publisher'] ?? '');
    _playersController = TextEditingController(text: widget.extractedData['players'] ?? '');
    _playTimeController = TextEditingController(text: widget.extractedData['playTime'] ?? '');
    
    // Automatically search BGG when screen loads
    _searchBGG();
  }
  
  Future<void> _searchBGG() async {
    if (_titleController.text.isEmpty) return;
    
    setState(() {
      _isSearching = true;
      _bggMatches = [];
    });
    
    try {
      final matches = await _bggService.searchGames(
        _titleController.text,
        publisher: _publisherController.text,
      );
      
      setState(() {
        _bggMatches = matches;
        _isSearching = false;
        _autoSearchCompleted = true;
        
        // Auto-select if high confidence match
        if (matches.isNotEmpty && matches.first.matchConfidence >= 0.8) {
          _selectMatch(matches.first);
        }
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _autoSearchCompleted = true;
      });
    }
  }
  
  Future<void> _selectMatch(BGGGameMatch match) async {
    setState(() {
      _selectedMatch = match;
      _isSearching = true;
    });
    
    // Get full details
    final details = await _bggService.getGameDetails(match.bggId);
    
    if (details != null) {
      setState(() {
        _titleController.text = details['title'] ?? match.title;
        _publisherController.text = details['publisher'] ?? '';
        
        final minPlayers = details['minPlayers'] ?? 1;
        final maxPlayers = details['maxPlayers'] ?? 4;
        _playersController.text = minPlayers == maxPlayers 
            ? '$minPlayers' 
            : '$minPlayers-$maxPlayers';
            
        final playTime = details['playTime'] ?? 0;
        _playTimeController.text = playTime > 0 ? '$playTime min' : '';
        
        _isSearching = false;
      });
    } else {
      setState(() {
        _isSearching = false;
      });
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _publisherController.dispose();
    _playersController.dispose();
    _playTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Confirm Game Details'),
        actions: [
          if (_selectedMatch != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(
                label: Text(
                  'BGG #${_selectedMatch!.bggId}',
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                side: BorderSide(color: AppTheme.primaryColor),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // OCR confidence indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _confidence >= 80 
                        ? AppTheme.successColor.withOpacity(0.2)
                        : _confidence >= 60
                            ? AppTheme.warningColor.withOpacity(0.2)
                            : AppTheme.errorColor.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.analytics,
                    color: _confidence >= 80 
                        ? AppTheme.successColor
                        : _confidence >= 60
                            ? AppTheme.warningColor
                            : AppTheme.errorColor,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OCR Confidence: ${_confidence.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _confidence >= 80 
                            ? 'High confidence match'
                            : _confidence >= 60
                                ? 'Moderate confidence - verify details'
                                : 'Low confidence - manual review needed',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // BGG Matches Section
            if (_bggMatches.isNotEmpty || _isSearching) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'BGG Database Matches',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (_isSearching)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    if (_bggMatches.isNotEmpty)
                      Container(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _bggMatches.length,
                          itemBuilder: (context, index) {
                            final match = _bggMatches[index];
                            final isSelected = _selectedMatch?.bggId == match.bggId;
                            
                            return GestureDetector(
                              onTap: () => _selectMatch(match),
                              child: Container(
                                width: 200,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? AppTheme.primaryColor.withOpacity(0.2)
                                      : const Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected 
                                        ? AppTheme.primaryColor
                                        : Colors.grey.shade800,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      match.title,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: isSelected 
                                            ? FontWeight.w600 
                                            : FontWeight.normal,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    if (match.publisher != null)
                                      Text(
                                        match.publisher!,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${(match.matchConfidence * 100).toInt()}% match',
                                            style: TextStyle(
                                              color: AppTheme.primaryColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (match.year > 0) ...[
                                          const Spacer(),
                                          Text(
                                            '${match.year}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
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
            
            // Game Details Form
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Game Information',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Game Title',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.casino, color: AppTheme.primaryColor),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _searchBGG,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _publisherController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Publisher',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.business, color: AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _playersController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Players',
                            labelStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: Icon(Icons.people, color: AppTheme.primaryColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _playTimeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Play Time',
                            labelStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: Icon(Icons.timer, color: AppTheme.primaryColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade600),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Add game to collection
                            Navigator.pop(context);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${_titleController.text} added to collection!'),
                                backgroundColor: AppTheme.successColor,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add, size: 20),
                              const SizedBox(width: 8),
                              const Text('Add to Library'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
