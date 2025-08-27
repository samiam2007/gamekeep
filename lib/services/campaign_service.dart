import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/campaign_data.dart';

class CampaignService {
  static CampaignService? _instance;
  static const String _campaignsKey = 'campaigns';
  static const String _sessionsKey = 'enhanced_sessions';
  late SharedPreferences _prefs;

  CampaignService._();

  static Future<CampaignService> getInstance() async {
    if (_instance == null) {
      _instance = CampaignService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    await _initializeDemoData();
  }

  Future<void> _initializeDemoData() async {
    final existingCampaigns = _prefs.getString(_campaignsKey);
    if (existingCampaigns == null) {
      // Create demo campaign for Gloomhaven
      final demoCampaign = CampaignData(
        campaignId: 'campaign_gloomhaven_001',
        gameId: '5',  // Gloomhaven game ID
        campaignName: 'The Black Barrow Campaign',
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        currentSession: 3,
        currentScenario: 'Black Barrow',
        currentMap: 'Gloomhaven Map Tile 1A',
        playerProgress: {
          'You': PlayerCampaignData(
            playerName: 'You',
            characterName: 'Brute',
            characterClass: 'Tank',
            level: 2,
            experience: 45,
            stats: {'HP': 10, 'Gold': 30, 'XP': 45},
            inventory: ['Leather Armor', 'Iron Helmet', 'Healing Potion x2'],
            abilities: ['Shield Bash', 'Grab and Go', 'Leaping Cleave'],
            perks: ['Remove two -1 cards', 'Add one +3 card'],
            achievements: {'First Blood': true, 'Barrow Lair': false},
          ),
          'Sarah': PlayerCampaignData(
            playerName: 'Sarah',
            characterName: 'Spellweaver',
            characterClass: 'Mage',
            level: 2,
            experience: 42,
            stats: {'HP': 6, 'Gold': 25, 'XP': 42},
            inventory: ['Cloak of Invisibility', 'Minor Mana Potion'],
            abilities: ['Fire Orbs', 'Impaling Eruption', 'Aid from the Ether'],
            perks: ['Add one +1 card'],
            achievements: {'First Blood': true},
          ),
        },
        gameState: {
          'city_prosperity': 1,
          'reputation': 2,
          'party_achievements': ['First Steps', 'Barrow Lair'],
          'unlocked_scenarios': [2, 3],
        },
        completedScenarios: ['Tutorial', 'Black Barrow (attempt 1)'],
        unlockedContent: ['Scenario 2', 'Scenario 3', 'City Event 03'],
        globalAchievements: {'City Rule: Economic': 1},
      );

      await saveCampaign(demoCampaign);
    }
  }

  // Campaign Management
  Future<bool> saveCampaign(CampaignData campaign) async {
    try {
      final campaigns = await getAllCampaigns();
      campaigns[campaign.campaignId] = campaign;
      
      final json = campaigns.map((key, value) => 
        MapEntry(key, value.toJson()));
      
      return await _prefs.setString(_campaignsKey, jsonEncode(json));
    } catch (e) {
      print('Error saving campaign: $e');
      return false;
    }
  }

  Future<Map<String, CampaignData>> getAllCampaigns() async {
    try {
      final String? data = _prefs.getString(_campaignsKey);
      if (data == null) return {};
      
      final Map<String, dynamic> json = jsonDecode(data);
      return json.map((key, value) => 
        MapEntry(key, CampaignData.fromJson(value)));
    } catch (e) {
      print('Error loading campaigns: $e');
      return {};
    }
  }

  Future<CampaignData?> getCampaignById(String campaignId) async {
    final campaigns = await getAllCampaigns();
    return campaigns[campaignId];
  }

  Future<List<CampaignData>> getCampaignsForGame(String gameId) async {
    final campaigns = await getAllCampaigns();
    return campaigns.values
        .where((c) => c.gameId == gameId)
        .toList();
  }

  Future<List<CampaignData>> getActiveCampaigns() async {
    final campaigns = await getAllCampaigns();
    return campaigns.values
        .where((c) => c.isActive)
        .toList();
  }

  // Enhanced Session Management
  Future<bool> saveEnhancedSession(EnhancedPlaySession session) async {
    try {
      final sessions = await getAllEnhancedSessions();
      sessions.add(session);
      
      // Sort by date
      sessions.sort((a, b) => b.playDate.compareTo(a.playDate));
      
      final json = sessions.map((s) => s.toJson()).toList();
      return await _prefs.setString(_sessionsKey, jsonEncode(json));
    } catch (e) {
      print('Error saving enhanced session: $e');
      return false;
    }
  }

  Future<List<EnhancedPlaySession>> getAllEnhancedSessions() async {
    try {
      final String? data = _prefs.getString(_sessionsKey);
      if (data == null) return [];
      
      final List<dynamic> json = jsonDecode(data);
      return json.map((j) => EnhancedPlaySession.fromJson(j)).toList();
    } catch (e) {
      print('Error loading enhanced sessions: $e');
      return [];
    }
  }

  Future<List<EnhancedPlaySession>> getSessionsForCampaign(String campaignId) async {
    final sessions = await getAllEnhancedSessions();
    return sessions
        .where((s) => s.campaignId == campaignId)
        .toList();
  }

  Future<List<EnhancedPlaySession>> getSessionsForGame(String gameId) async {
    final sessions = await getAllEnhancedSessions();
    return sessions
        .where((s) => s.gameId == gameId)
        .toList();
  }

  // Update campaign progress based on session
  Future<bool> updateCampaignProgress(
    String campaignId, 
    EnhancedPlaySession session,
  ) async {
    final campaign = await getCampaignById(campaignId);
    if (campaign == null) return false;

    // Update campaign with session data
    final updatedCampaign = campaign.copyWith(
      currentScenario: session.scenario,
      currentMap: session.map,
      completedScenarios: [
        ...campaign.completedScenarios,
        if (session.scenario != null) session.scenario!,
      ],
    );

    // Update player progress if items were found
    if (session.itemsFound != null) {
      final updatedPlayerProgress = Map<String, PlayerCampaignData>.from(
        campaign.playerProgress,
      );
      
      for (var entry in session.itemsFound!.entries) {
        final playerName = entry.key;
        final items = entry.value;
        
        if (updatedPlayerProgress.containsKey(playerName)) {
          final currentPlayer = updatedPlayerProgress[playerName]!;
          updatedPlayerProgress[playerName] = currentPlayer.copyWith(
            inventory: [...currentPlayer.inventory, ...items],
          );
        }
      }
      
      return await saveCampaign(updatedCampaign.copyWith(
        playerProgress: updatedPlayerProgress,
      ));
    }

    return await saveCampaign(updatedCampaign);
  }

  // Create new campaign
  Future<CampaignData> createCampaign({
    required String gameId,
    required String campaignName,
    required List<String> playerNames,
  }) async {
    final campaign = CampaignData(
      campaignId: 'campaign_${DateTime.now().millisecondsSinceEpoch}',
      gameId: gameId,
      campaignName: campaignName,
      startDate: DateTime.now(),
      playerProgress: Map.fromEntries(
        playerNames.map((name) => MapEntry(
          name,
          PlayerCampaignData(playerName: name),
        )),
      ),
      gameState: {},
    );

    await saveCampaign(campaign);
    return campaign;
  }

  // End campaign
  Future<bool> endCampaign(String campaignId) async {
    final campaign = await getCampaignById(campaignId);
    if (campaign == null) return false;

    final ended = campaign.copyWith(
      isActive: false,
      endDate: DateTime.now(),
    );

    return await saveCampaign(ended);
  }

  // Campaign Statistics
  Future<Map<String, dynamic>> getCampaignStatistics(String campaignId) async {
    final sessions = await getSessionsForCampaign(campaignId);
    final campaign = await getCampaignById(campaignId);
    
    if (campaign == null) return {};

    int totalPlayTime = 0;
    int totalSessions = sessions.length;
    Set<String> uniquePlayers = {};
    Map<String, int> resourcesTotal = {};

    for (final session in sessions) {
      totalPlayTime += session.duration;
      uniquePlayers.addAll(session.players.map((p) => p.name));
      
      if (session.resourcesGained != null) {
        session.resourcesGained!.forEach((key, value) {
          resourcesTotal[key] = (resourcesTotal[key] ?? 0) + value;
        });
      }
    }

    final daysSinceStart = DateTime.now().difference(campaign.startDate).inDays;

    return {
      'totalSessions': totalSessions,
      'totalPlayTime': totalPlayTime,
      'averageSessionLength': totalSessions > 0 ? totalPlayTime ~/ totalSessions : 0,
      'uniquePlayers': uniquePlayers.length,
      'daysSinceStart': daysSinceStart,
      'completedScenarios': campaign.completedScenarios.length,
      'resourcesTotal': resourcesTotal,
      'isActive': campaign.isActive,
    };
  }

  // Clear all data (for testing)
  Future<bool> clearAllData() async {
    await _prefs.remove(_campaignsKey);
    await _prefs.remove(_sessionsKey);
    return true;
  }
}