import 'package:firebase_database/firebase_database.dart';
import 'package:the_game/data/models.dart';
import 'package:the_game/data/types.dart';

class LobbyDatabaseService {
  late Function _playerUidGeneratedCallback;
  late Function _playerAddedCallback;
  late Function _playerRemovedCallback;
  late Function _playerChangedCallback;
  late Function _cardsDealtCallback;
  late Function _lobbyPrivacyCallback;
  String _playerUid = "";
  late String _playerName;
  late String _gameCode;

  LobbyDatabaseService({
    required void playerUidGeneratedCallback(String playerUid),
    required void playerAddedCallback(PlayerInfo playerInfo),
    required void playerRemovedCallback(PlayerInfo playerInfo),
    required void playerChangedCallback(PlayerInfo playerInfo),
    required void cardsDealtCallback(),
    required void lobbyPrivacyCallback(bool newIsPublic),
    required String gameCode,
    required String playerName,
  }) {
    _playerUidGeneratedCallback = playerUidGeneratedCallback;
    _playerAddedCallback = playerAddedCallback;
    _playerRemovedCallback = playerRemovedCallback;
    _playerChangedCallback = playerChangedCallback;
    _cardsDealtCallback = cardsDealtCallback;
    _lobbyPrivacyCallback = lobbyPrivacyCallback;
    _playerName = playerName;
    _gameCode = gameCode;
    _performInitialDBOperations();
  }

  // Does some initial setup interactions with DB
  void _performInitialDBOperations() async {
    await _updateInitialPlayerName();
    await _setUpListeners();
  }

  // Updates default player name in DB
  Future<void> _updateInitialPlayerName() async {
    DatabaseReference gameRef =
        FirebaseDatabase.instance.ref("games/$_gameCode/players");
    // Only create UID and push to DB if this player was not written to DB
    if (_playerUid == "") {
      DatabaseReference playersRef = gameRef.push();
      playersRef.set(_playerName);
      // Storing unique key for usage later
      _playerUid = playersRef.key.toString();
      _playerUidGeneratedCallback(_playerUid);
    }
  }

  // Changes the status of game
  void updateGameStatus(GameStatusEnum status) async {
    DatabaseReference gameRef =
        FirebaseDatabase.instance.ref("games/$_gameCode/game_status");
    gameRef.set(status.index);
  }

  // Sets up all required listeners
  Future<void> _setUpListeners() async {
    await _setupPlayersListener();
    await _setupGameStatusListener();
    await _setupGamePrivacyListener();
  }

  // Creates listener for any change in player list
  Future<void> _setupPlayersListener() async {
    // Player added
    DatabaseReference gameRef =
        FirebaseDatabase.instance.ref("games/$_gameCode/players");
    gameRef.onChildAdded.listen((event) {
      PlayerInfo playerInfo = PlayerInfo();
      playerInfo.name = event.snapshot.value as String;
      playerInfo.uid = event.snapshot.key as String;
      _playerAddedCallback(playerInfo);
      print("player added: ${playerInfo.name}");
    });

    // Player removed
    gameRef.onChildRemoved.listen((event) {
      PlayerInfo playerInfo = PlayerInfo();
      playerInfo.name = event.snapshot.value as String;
      playerInfo.uid = event.snapshot.key as String;
      _playerRemovedCallback(playerInfo);
      print("player added: ${playerInfo.name}");
    });

    // Player changed
    gameRef.onChildChanged.listen((event) {
      PlayerInfo playerInfo = PlayerInfo();
      playerInfo.name = event.snapshot.value as String;
      playerInfo.uid = event.snapshot.key as String;
      _playerChangedCallback(playerInfo);
      print("player added: ${playerInfo.name}");
    });
  }

  Future<void> _setupGameStatusListener() async {
    var tempStatus;
    DatabaseReference gameRef =
        FirebaseDatabase.instance.ref("games/$_gameCode/game_status");
    gameRef.onValue.listen((DatabaseEvent event) {
      tempStatus = event.snapshot.value;
      print("game state changed to $tempStatus");
      if (tempStatus == GameStatusEnum.SETUP.index) {
        _cardsDealtCallback();
      }
    });
  }

  Future<void> _setupGamePrivacyListener() async {
    var tempPrivacy;
    DatabaseReference gameRef =
        FirebaseDatabase.instance.ref("games/$_gameCode/is_public");
    gameRef.onValue.listen((DatabaseEvent event) {
      tempPrivacy = event.snapshot.value;
      print("lobby privacy changed to $tempPrivacy");
      _lobbyPrivacyCallback(tempPrivacy);
    });
  }

  // Writes edited player name to DB
  void updatePlayerNameInDB(String newName) {
    DatabaseReference gameRef =
        FirebaseDatabase.instance.ref("games/$_gameCode/players");
    gameRef.child(_playerUid).set(newName);
  }

  // Changes the privacy of the lobby
  void updateLobbyPrivacy(bool isLobbyPublic) {
    DatabaseReference gameRef =
        FirebaseDatabase.instance.ref("games/$_gameCode/is_public");
    gameRef.set(isLobbyPublic);
  }

  // Removes this player from game DB, deletes game if this is the only player
  void removePlayerFromDb(String playerUidToRemove) async {
    print("removePlayerFromDb: started, game code = $_gameCode");
    // Read players from DB and remove said player
    DatabaseReference gameRef =
        FirebaseDatabase.instance.ref("games/$_gameCode");
    TransactionResult result = await gameRef.runTransaction((Object? game) {
      if (game == null) {
        print("removePlayerFromDb: game is null");
        return Transaction.success(game);
      }
      Map<String, dynamic> _game = Map<String, dynamic>.from(game as Map);
      print("removePlayerFromDb: game map = ${_game}");
      // Removing player from map
      var playersMap = Map<String, dynamic>.from(game["players"] as Map);
      print("removePlayerFromDb: players map = ${playersMap}");
      playersMap.remove(playerUidToRemove);
      _game["players"] = playersMap;
      // If no players, delete the game
      if (playersMap.isEmpty) {
        _game = {};
      }
      return Transaction.success(_game);
    });
    print("removePlayerFromDb: result.committed = ${result.committed}");
  }
}
