import 'package:firebase_database/firebase_database.dart';
import 'game_state.dart';
import 'package:the_game/constants/numbers.dart';
import 'package:the_game/data/models.dart';
import 'package:the_game/data/types.dart';

class GameDatabaseService {
  late String _gameCode;
  late String _playerUid;
  late Function _getPlayerListCallback;
  late Function _getGameStateCallback;
  late Function _centerDecksChangedCallback;
  late Function _turnChangedCallback;
  late Function _gameStatusChangedCallback;
  late Function _numMovesDoneChangedCallback;
  late List<PlayerInfo> playerList = [];
  static bool isWriting =
      false; // To keep track if this device is currently writing to DB

  GameDatabaseService({
    required String gameCode,
    required String playerUid,
    required Function getPlayerListCallback,
    required Function turnChangedCallback,
    required Function getGameStateCallback,
    required Function centerDecksChangedCallback,
    required Function gameStatusChangedCallback,
    required Function numMovesDoneChangedCallback,
  }) {
    _gameCode = gameCode;
    _playerUid = playerUid;
    _getPlayerListCallback = getPlayerListCallback;
    _turnChangedCallback = turnChangedCallback;
    _getGameStateCallback = getGameStateCallback;
    _centerDecksChangedCallback = centerDecksChangedCallback;
    _gameStatusChangedCallback = gameStatusChangedCallback;
    _numMovesDoneChangedCallback = numMovesDoneChangedCallback;
    _performInitialDBOperations();
  }

  // Does some initial setup interactions with DB
  void _performInitialDBOperations() async {
    await updateGameStatus(GameStatusEnum.SETUP);
    await _getPlayerList();
    await _setUpListeners();
  }

  // Set up initial listeners
  Future<void> _setUpListeners() async {
    _setUpWhoseTurnListener();
    _setUpCenterDecksListener();
    _setUpGameStatusListener();
    _setUpNumMovesDoneListener();
    // await _setUpDrawPileListeners();
    // await _playersHandsListeners();
  }

  // Set up listener for change in whose turn
  Future<void> _setUpWhoseTurnListener() async {
    var tempWhoseTurn;
    DatabaseReference gameRef =
        FirebaseDatabase.instance.ref("games/$_gameCode/whose_turn");
    gameRef.onValue.listen((DatabaseEvent event) {
      tempWhoseTurn = event.snapshot.value;
      print(
          "_setUpWhoseTurnListener: Whose Turn changed to $tempWhoseTurn in DB");
      if (!isWriting && tempWhoseTurn != null) {
        _turnChangedCallback(tempWhoseTurn);
      }
    });
  }

  // Set up listener for change in center deck
  Future<void> _setUpCenterDecksListener() async {
    var tempCenterDecks;
    DatabaseReference gameRef =
        FirebaseDatabase.instance.ref("games/$_gameCode/center_decks");
    gameRef.onValue.listen((DatabaseEvent event) {
      print("_setUpCenterDecksListener: isWriting = ${isWriting}");
      tempCenterDecks = event.snapshot.value;
      if (!isWriting && tempCenterDecks != null) {
        print(
            "_setUpCenterDecksListener: Center Decks changed to ${tempCenterDecks.toString()} in DB");
        _centerDecksChangedCallback(tempCenterDecks as List);
      }
    });
  }

  // Set up listener for game status
  Future<void> _setUpGameStatusListener() async {
    var tempStatus;
    DatabaseReference gameRef =
        FirebaseDatabase.instance.ref("games/$_gameCode/game_status");
    gameRef.onValue.listen((DatabaseEvent event) {
      tempStatus = event.snapshot.value;
      print("game state changed to $tempStatus");
      if (!isWriting && tempStatus != null) {
        _gameStatusChangedCallback(GameStatusEnum.values[tempStatus]);
      }
    });
  }

  // Set up listener for numMovesDone
  Future<void> _setUpNumMovesDoneListener() async {
    var tempNumMovesDone;
    DatabaseReference numMovesDoneRef =
    FirebaseDatabase.instance.ref("games/$_gameCode/num_moves_done");
    numMovesDoneRef.onValue.listen((DatabaseEvent event) {
      tempNumMovesDone = event.snapshot.value;
      print("numMovesDone changed to $tempNumMovesDone");
      if (!isWriting && tempNumMovesDone != null) {
        _numMovesDoneChangedCallback(tempNumMovesDone);
      }
    });
  }

  // Updates game state in DB
  Future<void> updateGameStatus(GameStatusEnum status) async {
    isWriting = true;
    DatabaseReference gameRef =
        FirebaseDatabase.instance.ref("games/$_gameCode/game_status");
    await gameRef.set(status.index);
    isWriting = false;
  }

  // Fetches player list from DB
  Future<void> _getPlayerList() async {
    DatabaseReference playersRef =
        FirebaseDatabase.instance.ref("games/$_gameCode/players");
    var event = await playersRef.once(DatabaseEventType.value);
    var tempPlayersList = Map.from(event.snapshot.value as Map);
    tempPlayersList.forEach((key, value) {
      PlayerInfo tempPlayerInfo = PlayerInfo();
      tempPlayerInfo.uid = key as String;
      tempPlayerInfo.name = value as String;
      playerList.add(tempPlayerInfo);
    });
    _getPlayerListCallback(playerList);
  }

  // Writes entire game state to DB
  Future<void> writeGameState(GameState gameState) async {
    isWriting = true;
    print("writeGameState: isWriting at start = ${isWriting}");

    DatabaseReference gameRef =
        FirebaseDatabase.instance.ref("games/$_gameCode");

    // Writing player hands to DB
    for (int playerIdx = 0;
        playerIdx < gameState.playersHands.length;
        playerIdx++) {
      // If player is done, write their hand as "done"
      if (gameState.playersHands[playerIdx].isDone) {
        await gameRef
            .child("players_hands")
            .child(gameState.playersHands[playerIdx].playerUid)
            .set("done");
      } else {
        await gameRef
            .child("players_hands")
            .child(gameState.playersHands[playerIdx].playerUid)
            .set(gameState.playersHands[playerIdx].cards);
      }
    }

    // Writing center decks to DB
    print(
        "writeGameState: Writing center deck to DB = ${gameState.centerDecks.map((deck) => deck.extremeValue)}");
    for (int deckIndex = 0; deckIndex < NUM_CENTER_PILES; deckIndex++) {
      await gameRef
          .child("center_decks")
          .child("$deckIndex")
          .set(gameState.centerDecks[deckIndex].extremeValue);
    }

    // Writing draw pile to DB, removing old entries
    print("writeGameState: Writing draw pile to DB = ${gameState.drawPile}");
    await gameRef.child("draw_pile").set(gameState.drawPile);

    // Writing whose turn to DB
    // When whose turn is updated in DB, all the other info is already present
    await gameRef.child("whose_turn").set(gameState.whoseTurn);

    isWriting = false;
    print("writeGameState: isWriting at start = ${isWriting}");
  }

  // Reads entire game state from DB
  Future<void> readGameState(GameState gameState) async {
    DatabaseReference gameRef =
        FirebaseDatabase.instance.ref("games/$_gameCode");

    // Reading player hands from DB
    print("readGameState: reading player hands from DB");
    gameState.playersHands = [];
    var event =
        await gameRef.child("players_hands").once(DatabaseEventType.value);
    var tempPlayersHandsMap = Map.from(event.snapshot.value as Map);
    tempPlayersHandsMap.forEach((playerUid, playerHandList) {
      PlayerHand tempPlayerHand = PlayerHand();
      tempPlayerHand.playerUid = playerUid as String;
      // print("playerUid = ${tempPlayerHand.playerUid}");
      if (playerHandList == "done") {
        tempPlayerHand.isDone = true;
        tempPlayerHand.cards = [];
      } else {
        for (var cardValue in playerHandList) {
          tempPlayerHand.cards.add(cardValue);
        }
      }
      gameState.playersHands.add(tempPlayerHand);
      print("readGameState: tempPlayerHand = ${tempPlayerHand.cards}");
    });

    // Reading game status from DB
    event = await gameRef.child("game_status").once(DatabaseEventType.value);
    var tempStatus = event.snapshot.value as int;
    gameState.gameStatus = GameStatusEnum.values[tempStatus];

    // Reading draw pile from DB
    gameState.drawPile = [];
    event = await gameRef.child("draw_pile").once(DatabaseEventType.value);
    if (event.snapshot.exists) {
      var tempDrawPile = event.snapshot.value as List;
      for (var item in tempDrawPile) {
        gameState.drawPile.add(item);
      }
    }
    print("drawPile from DB = ${gameState.drawPile}");

    // Reading center decks from DB
    gameState.centerDecks = [];
    event = await gameRef.child("center_decks").once(DatabaseEventType.value);
    var tempCenterDecks = event.snapshot.value as List;
    for (int index = 0; index < tempCenterDecks.length; index++) {
      CenterDeck tempCenterDeck = new CenterDeck();
      tempCenterDeck.isAscending = index < NUM_CENTER_PILES / 2;
      tempCenterDeck.extremeValue = tempCenterDecks[index];
      gameState.centerDecks.add(tempCenterDeck);
    }

    // Reading whose turn from DB
    event = await gameRef.child("whose_turn").once(DatabaseEventType.value);
    var tempWhoseTurn = event.snapshot.value as String;
    if (tempWhoseTurn == _playerUid) {
      gameState.whoseTurn = _playerUid;
      //_myTurnCallback();
    }

    _getGameStateCallback(gameState);
  }

  // Function to attempt to start game
  Future<bool> tryStartGame(String tempUid) async {
    DatabaseReference gameRef =
        FirebaseDatabase.instance.ref("games/$_gameCode/whose_turn");
    TransactionResult result =
        await gameRef.runTransaction((Object? whoseTurnFromDb) {
      print("whoseTurnFromDb type = ${whoseTurnFromDb.runtimeType}");
      // If no one else has started the game
      if (whoseTurnFromDb == null) {
        whoseTurnFromDb = tempUid;
        return Transaction.success(whoseTurnFromDb);
      } else {
        print("whoseTurnFromDb = ${whoseTurnFromDb}");
        // If no one else has started the game
        if (whoseTurnFromDb == "") {
          whoseTurnFromDb = tempUid;
          return Transaction.success(whoseTurnFromDb);
        } else {
          return Transaction.abort();
        }
      }
    });
    return result.committed;
  }

  // Function to be called wen game is abandoned by any player
  void clearGameStateFromDB() {
    isWriting = true;

    DatabaseReference gameRef =
        FirebaseDatabase.instance.ref("games/$_gameCode");
    gameRef.child("center_decks").remove();
    gameRef.child("draw_pile").remove();
    gameRef.child("players_hands").remove();
    gameRef.child("whose_turn").remove();

    isWriting = false;
  }

  // Updates numMovesDone in DB
  void updateNumMovesDone(int newNumMovesDone) async {
    DatabaseReference numMovesDoneRef =
        FirebaseDatabase.instance.ref("games/$_gameCode/num_moves_done");
    await numMovesDoneRef.set(newNumMovesDone);
  }
}
