import 'package:the_game/constants/numbers.dart';
import 'package:the_game/data/types.dart';
import 'package:the_game/screens/GamePage/game_database_service.dart';

// Describes the hand of a single player
class PlayerHand {
  late String playerUid;
  bool isDone = false;
  List<int> cards = [];
}

// Describes a single center deck
class CenterDeck {
  // Only store the topmost card (since none of the others matter)
  late int extremeValue;
  late bool isAscending;
  bool isValidMove(int num) {
    if (isAscending) {
      if (num >= extremeValue || num == extremeValue - BACKWARDS_DIFF) {
        return true;
      }
    } else {
      if (num <= extremeValue || num == extremeValue + BACKWARDS_DIFF) {
        return true;
      }
    }
    return false;
  }
}

// Describes the object used to hold the state of the game
class GameState {
  late int numPlayers;
  late List<PlayerHand> playersHands;
  late List<CenterDeck> centerDecks;
  late List<int> drawPile;
  late String whoseTurn;
  late int handLimit;
  late GameStatusEnum gameStatus;
  late int numMovesDone;
  late GameDatabaseService gameDatabaseService;

  GameState(int tempNumPlayers) {
    playersHands = [];
    centerDecks = [];
    drawPile = [];
    whoseTurn = "";
    numMovesDone = 0;
    gameStatus = GameStatusEnum.SETUP;
    assignHandLimit(tempNumPlayers);
    initializeCenterDecks();
  }

  // Switch case to generate hand limit based on number of players
  void assignHandLimit(int tempNumPlayers) {
    numPlayers = tempNumPlayers;
    switch (tempNumPlayers) {
      case 1:
        handLimit = 8;
        break;
      case 2:
        handLimit = 7;
        break;
      case 3:
      case 4:
      case 5:
        handLimit = 6;
        break;
      default:
        handLimit = 0;
    }
  }

  // Initialize center decks
  void initializeCenterDecks() {
    for (var i = 0; i < NUM_CENTER_PILES; i++) {
      CenterDeck tempCenterDeck = CenterDeck();
      // Assigning first half as ascending, and next half as descending
      if (i < NUM_CENTER_PILES / 2) {
        tempCenterDeck.isAscending = true;
        tempCenterDeck.extremeValue = CENTER_START_NUM;
      } else {
        tempCenterDeck.isAscending = false;
        tempCenterDeck.extremeValue = CENTER_END_NUM;
      }
      centerDecks.add(tempCenterDeck);
    }
  }

  // Updates to next players turn
  void updateWhoseTurn() {
    print("updateWhoseTurn: whose turn before change:${whoseTurn}");
    for (var index = 0; index < playersHands.length; index++) {
      var tempUid = playersHands[index].playerUid;
      if (tempUid == whoseTurn) {
        int nextPlayerIdx = index;
        // Skip players who are done
        do {
          // If current player is last page in list, loop around
          if (index == playersHands.length - 1) {
            nextPlayerIdx = 0;
          }
          // Assign next player
          else {
            nextPlayerIdx = index + 1;
          }
        } while (playersHands[nextPlayerIdx].isDone);
        whoseTurn = playersHands[nextPlayerIdx].playerUid;
        print("updateWhoseTurn: index = $index: ${whoseTurn} turn now");
        break;
      }
    }
    print("updateWhoseTurn: whose turn after change:${whoseTurn}");
  }

  // Removes player from game state
  void removePlayerFromGame(String playerUid) {
    for (var index = 0; index < playersHands.length; index++) {
      var tempUid = playersHands[index].playerUid;
      if (tempUid == playerUid) {
        playersHands.removeAt(index);
        index--;
      }
    }
  }

  // Marks player as done in game state
  void markPlayerAsDone(String playerUid) {
    for (var index = 0; index < playersHands.length; index++) {
      var tempUid = playersHands[index].playerUid;
      if (tempUid == playerUid) {
        playersHands[index].isDone = true;
      }
    }
  }

  // Updates numMovesDone locally and in DB
  void updateNumMovesDone(int newNumMoves) {
    this.numMovesDone = newNumMoves;
  }

  void restartGameState() {
    // TODO: Start a new game from scratch, keep game code though
  }
}
