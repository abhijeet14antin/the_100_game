import 'package:the_game/constants/numbers.dart';
import 'package:the_game/data/types.dart';

// Class that holds all info for a given player
class Player {
  String playerUid;
  bool isPlayerDone = false;
  List<num> cards = [];
  num minMoves = INITIAL_MIN_MOVES_PER_TURN;
  num movesRemaining = INITIAL_MIN_MOVES_PER_TURN;

  // Constructor that takes player UID compulsorily
  Player(this.playerUid);
}

// Class that holds info/methods for a center deck
class CenterDeck {
  List<num> cards = [];
  bool isAscending;
  num extremeValue = 0;

  // Constructor that takes whether this pile is going up or down
  CenterDeck(this.isAscending) {
    extremeValue = isAscending ? 1 : TOTAL_CARD_NUMBERS;
  }

  // Returns true if the number passed is a valid next move
  bool isValidMove(num moveNumber) {
    if (isAscending) {
      if (moveNumber >= extremeValue ||
          moveNumber == extremeValue - BACKWARDS_DIFF) {
        return true;
      }
    } else {
      if (moveNumber <= extremeValue ||
          moveNumber == extremeValue + BACKWARDS_DIFF) {
        return true;
      }
    }
    return false;
  }
}

class GameState {
  GameStatusEnum gameStatus = GameStatusEnum.WAITING;
  num numPlayers;
  List<num> drawPile = [];
  List<Player> players = [];
  List<CenterDeck> centerDecks = [];
  String whoseTurn = "";
  late num handLimit;

  GameState(this.numPlayers) {
    readPlayersFromDB();
    assignHandLimit();
    generateNewGame();
  }

  // Switch case to generate hand limit based on number of players
  void assignHandLimit() {
    switch (numPlayers) {
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

  // Callback when we receive starting player from DB
  void onReceiveStartingPlayerFromDB(String startingPlayerUid) {
    whoseTurn = startingPlayerUid;
  }

  // Function that gets all players from DB
  void readPlayersFromDB() {

  }

  // Function that generates a new game and assigns cards to players
  void generateNewGame() {

  }
}
