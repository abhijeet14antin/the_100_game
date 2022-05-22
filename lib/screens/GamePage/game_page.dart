import 'package:flutter/material.dart';
import 'package:the_game/data/models.dart';
import 'package:the_game/data/types.dart';
import 'package:the_game/screens/GamePage/dimensions.dart';
import 'game_database_service.dart';
import 'game_state.dart';
import 'package:the_game/constants/numbers.dart';
import 'package:the_game/constants/colors.dart';
import 'package:the_game/constants/strings.dart';
import 'package:the_game/theme/styles.dart';

late String gameCode;
late int numPlayers;
late String playerUid;
late bool isGameStarter;

class GamePage extends StatefulWidget {
  GamePage(
    String tempGameCode,
    int tempNumPlayers,
    String tempPlayerUid,
    bool tempIsGameStarter,
  ) {
    gameCode = tempGameCode;
    numPlayers = tempNumPlayers;
    playerUid = tempPlayerUid;
    isGameStarter = tempIsGameStarter;
  }

  @override
  _PlayerViewState createState() => _PlayerViewState();
}

class _PlayerViewState extends State<GamePage> {
  late BuildContext context;
  late Dimensions dimensions;
  late List<Widget> playerCardWidgets;
  late List<Widget> centerCardWidgets;
  late GameDatabaseService gameDatabaseService;
  late GameState gameState;
  List<PlayerInfo> playerList = [];
  late List<int> thisPlayerHand;
  int minMovesPerTurn = INITIAL_MIN_MOVES_PER_TURN;
  int highlightedCardIndex = -1;
  List<Color> cardColors = [];
  List<int> thisCenterDeck = [1, 1, TOTAL_CARD_NUMBERS, TOTAL_CARD_NUMBERS];
  bool initialHandPopulated = false;
  bool isPlayerStarter = false;
  Color textBoxColor = defaultTextColor;
  Color cardsRemainingTextBoxColor = defaultTextColor;
  List<Color> centerPilesBorderColors =
      List.filled(NUM_CENTER_PILES, defaultCardBorderColor);
  Color allPlayerCardsBorderColor = defaultCardBorderColor;

  _PlayerViewState() {
    // Setting up interaction with DB
    gameDatabaseService = GameDatabaseService(
      gameCode: gameCode,
      playerUid: playerUid,
      getPlayerListCallback: onReceivePlayerList,
      getGameStateCallback: onReceiveGameState,
      turnChangedCallback: onTurnChanged,
      centerDecksChangedCallback: onCenterDecksChanged,
      gameStatusChangedCallback: onGameStatusChanged,
      numMovesDoneChangedCallback: onNumMovesChanged,
    );
    gameState = GameState(numPlayers);
    thisPlayerHand = List.filled(gameState.handLimit, 0);
    generateCardColors();
  }

  @override
  Widget build(BuildContext context) {
    this.context = context;
    // Perform stuff that's dependent on context
    // Getting and calculating all dimensions for layout
    dimensions = Dimensions(context, numPlayers);

    return WillPopScope(
        onWillPop: onExitPressed,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: appBarColor,
            title: Text(
              gameAppBarString,
              style: appBarTextStyle,
            ),
            actions: <Widget>[
              // TODO: do we even need this refresh button?
              // IconButton(
              //   onPressed: onRestartPressed,
              //   icon: Icon(
              //     Icons.restart_alt,
              //     size: appBarIconSize,
              //   ),
              // ),
              // TODO: bring back exit button, with proper navigator pop
              // IconButton(
              //   onPressed: onExitPressed,
              //   icon: Icon(
              //     Icons.close,
              //     size: appBarIconSize,
              //   ),
              // ),
              IconButton(
                onPressed: onDonePressed,
                icon: Icon(
                  Icons.done,
                  size: appBarIconSize,
                ),
              ),
            ],
          ),
          body: getGamePage(),
          backgroundColor: appBackgroundColor,
        ));
  }

  void generateCardColors() {
    for (var i = 0; i < numColors; i++) {
      cardColors.add(HSLColor.fromColor(cardBaseColor)
          .withLightness(1 -
              ((i) / numColors * (colorRange[1] - colorRange[0]) +
                  colorRange[0]))
          .toColor());
    }
  }

  // Basic card widget
  Widget getCardWidget(
    double width,
    double height,
    int index,
    int number,
    Color? cardColor,
    CardTypeEnum callerType,
    Color cardBorderColor,
  ) {
    return InkWell(
      onTap: () => onCardPressed(callerType, index),
      child: Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: cardBorderColor,
            width: cardBorderWidth,
          ),
          borderRadius: BorderRadius.circular(cardBorderRadius),
        ),
        // Increase elevation if card is a selected card
        elevation: cardBorderColor == highlightCardBorderColor
            ? highlightedCardElevation
            : defaultCardElevation,
        child: Container(
          alignment: Alignment.center,
          width: width,
          height: height,
          child: Text(
            number.toString(),
            style: cardTextStyle,
          ),
        ),
        margin: const EdgeInsets.all(cardMargin),
        color: cardColor,
      ),
    );
  }

  void onDonePressed() {
    if (playerUid != gameState.whoseTurn) {
      flashTextBox();
    } else if (gameState.numMovesDone < minMovesPerTurn) {
      flashCardsRemainingTextBox();
      print("Can't be done with ${gameState.numMovesDone} moves");
    } else {
      print("$playerUid turn complete");
      gameState.updateNumMovesDone(0);
      gameDatabaseService.updateNumMovesDone(gameState.numMovesDone);
      gameState.updateWhoseTurn();
      // Updating game state with new player hand
      setState(() {
        drawCardsAtEndOfTurn();
        writeThisPlayerHandToGameState();
      });
      // gameDatabaseInteraction.updateWhoseTurn(gameState.whoseTurn);
      gameDatabaseService.writeGameState(gameState);
    }
  }

  // Handles restart game option
  void onRestartPressed() {
    // TODO: Dialog
    // TODO: Handle more things here
    // gameState.restartGameState();
    // gameDatabaseService.clearGameStateFromDB();
  }

  // Handles when each card is pressed
  void onCardPressed(CardTypeEnum callerType, int pressedIndex) {
    // If a player card is pressed
    if (callerType == CardTypeEnum.THIS_PLAYER) {
      onPlayerCardPressed(pressedIndex);
    } else if (callerType == CardTypeEnum.CENTER_DECK) {
      print("whoseTurn = ${gameState.whoseTurn}");
      if (gameState.whoseTurn == playerUid) {
        if (highlightedCardIndex == -1) {
          // No card selected
          flashAllPlayerCards();
        } else {
          validateAndPlayCard(pressedIndex);
        }
      } else {
        // Visually highlight whose turn it is
        flashTextBox();
      }
    } else if (callerType == CardTypeEnum.OTHER_PLAYER) {
      // Currently, other players' cards not visible
    }
  }

  // Changes highlighting of cards on player card pressed
  void onPlayerCardPressed(int pressedIndex) {
    setState(() {
      // Highlighting logic works only if cards are not duplicated
      // Unhighlight/highlight logic
      if (highlightedCardIndex == pressedIndex) {
        highlightedCardIndex = -1;
      } else {
        highlightedCardIndex = pressedIndex;
        allPlayerCardsBorderColor = defaultCardBorderColor;
      }
    });
    print("highlighted card index = $highlightedCardIndex");
  }

  // Active current player plays card
  void validateAndPlayCard(int pileIndex) {
    int selectedNum = thisPlayerHand[highlightedCardIndex];
    // Validation
    if (gameState.centerDecks[pileIndex].isValidMove(selectedNum)) {
      print("playing ${selectedNum} on pile $pileIndex is a valid move");
      // Performing move on local game state
      // Adding played card to center deck
      gameState.centerDecks[pileIndex].extremeValue = selectedNum;
      // Removing played card from local player hand
      setState(() {
        thisCenterDeck[pileIndex] = selectedNum;
        thisPlayerHand.removeAt(highlightedCardIndex);
      });
      // Updating game state with new player hand
      writeThisPlayerHandToGameState();
      // Incrementing moves done in this turn, stop if min required moves are played
      if (gameState.numMovesDone < minMovesPerTurn) {
        gameState.numMovesDone++;
        gameDatabaseService.updateNumMovesDone(gameState.numMovesDone);
      }
      // Check if game ended
      checkGameEndConditions();
      // Writing game state to DB
      gameDatabaseService.writeGameState(gameState);
      // Removing card highlight
      highlightedCardIndex = -1;
    } else {
      print("playing ${selectedNum} on pile $pileIndex is an invalid move");
      flashCardBorder(errorColor, pileIndex);
    }
  }

  // Move cards from draw pile to player's hand at end of turn
  void drawCardsAtEndOfTurn() {
    for (int i = thisPlayerHand.length; i < gameState.handLimit; i++) {
      if (gameState.drawPile.length == 0) {
        minMovesPerTurn = END_MIN_MOVES_PER_TURN;
        break;
      } else {
        // Handle rare case where DB draw pile reads zero for a moment =>
        // i.e., where minMovesPer turn gets wrongly changed to lower value
        minMovesPerTurn = INITIAL_MIN_MOVES_PER_TURN;
      }
      thisPlayerHand.add(gameState.drawPile.last);
      gameState.drawPile.removeLast();
    }
    // Handle case where this player finishes and no cards in draw pile
    if (thisPlayerHand.length == 0 && gameState.drawPile == 0) {
      setState(() {
        gameState.markPlayerAsDone(playerUid);
      });
    }
    gameDatabaseService.writeGameState(gameState);
    thisPlayerHand.sort();
    print(
        "drawCardsAtEndOfTurn: drawPile at end of turn = ${gameState.drawPile}");
    print(
        "drawCardsAtEndOfTurn: thisPlayerHand at end of turn = $thisPlayerHand");
  }

  // Check if game ended, and write status to DB if yes
  void checkGameEndConditions() {
    if (isGameWon()) {
      gameDatabaseService.updateGameStatus(GameStatusEnum.WON);
      gameState.gameStatus = GameStatusEnum.WON;
    } else if (isGameLost()) {
      gameDatabaseService.updateGameStatus(GameStatusEnum.LOST);
      gameState.gameStatus = GameStatusEnum.LOST;
    }
  }

  // Check if game is won
  bool isGameWon() {
    bool hasWon = false;
    // If draw pile and all player hands are empty
    if (gameState.drawPile.length == 0) {
      hasWon = true;
      for (var playerHand in gameState.playersHands) {
        if (playerHand.cards.length != 0) {
          hasWon = false;
          break;
        }
      }
    }
    return hasWon;
  }

  // Check if game is lost
  bool isGameLost() {
    bool hasLost;
    // If player hand is empty, or has played minimum number of moves in their
    // turn, don't evaluate lose condition
    if (thisPlayerHand.length == 0 ||
        gameState.numMovesDone >= minMovesPerTurn) {
      hasLost = false;
    } else {
      // If no possible moves for current player
      hasLost = true;
      for (var centerDeck in gameState.centerDecks) {
        for (var cardNum in thisPlayerHand) {
          if (centerDeck.isValidMove(cardNum)) {
            hasLost = false;
            break;
          }
        }
      }
    }
    return hasLost;
  }

  // Returns the populated page
  Column getGamePage() {
    // Generating card widgets
    centerCardWidgets = _generateCenterCards();
    playerCardWidgets = _generatePlayerCards();

    // Placing them in a view
    return Column(
      children: [
        Column(
          children: [
            // Displays starting button if needed
            Container(
              child: getStartingButtonIfNeeded(),
              margin: const EdgeInsets.all(textBoxMargin),
              alignment: Alignment.center,
            ),
            // Displays whose turn it is
            Container(
              child: Text(
                getTextForTextBox(),
                style: defaultTextStyleWithColor(textBoxColor),
                textAlign: TextAlign.center,
              ),
              margin: const EdgeInsets.all(textBoxMargin),
              alignment: Alignment.center,
            ),
            // Displays min number of moves remaining for this player
            Text(
              minMovesLeftString +
                  (minMovesPerTurn - gameState.numMovesDone).toString(),
              style: defaultTextStyleWithColor(cardsRemainingTextBoxColor),
            ),
          ],
          crossAxisAlignment: CrossAxisAlignment.center,
        ),
        _getCenterDecksRow(),
        _getPlayerCardsRows(),
      ],
      mainAxisAlignment: MainAxisAlignment.spaceAround,
    );
  }

  // Gets the choose starter button if needed, else returns empty view
  Widget getStartingButtonIfNeeded() {
    if (gameState.gameStatus == GameStatusEnum.SETUP) {
      return ElevatedButton(
        onPressed: () => onThisPlayerStarterPressed(),
        child: Text(starterButtonString),
        style: myButtonStyle,
      );
    } else {
      return SizedBox.shrink();
    }
  }

  // When current player starts the game
  void onThisPlayerStarterPressed() async {
    print("onThisPlayerStarterPressed: Trying to start game");
    if (await gameDatabaseService.tryStartGame(playerUid)) {
      print("onThisPlayerStarterPressed: Successfully started game");
      setState(() {
        gameState.whoseTurn = playerUid;
        gameState.gameStatus = GameStatusEnum.PLAYING;
      });
      gameDatabaseService.writeGameState(gameState);
      gameDatabaseService.updateGameStatus(GameStatusEnum.PLAYING);
    } else {
      print("onThisPlayerStarterPressed: unsuccessful in starting game");
    }
  }

  // Gets text for the display text box
  String getTextForTextBox() {
    String returnString = "";
    if (gameState.gameStatus == GameStatusEnum.WON) {
      returnString = winString;
    } else if (gameState.gameStatus == GameStatusEnum.LOST) {
      returnString = loseString;
    } else if (gameState.gameStatus == GameStatusEnum.SETUP) {
      returnString = choosingStarterString;
    } else if (gameState.gameStatus == GameStatusEnum.PLAYING) {
      for (var item in playerList) {
        // print("getTextForTextBox: item.uid = ${item.uid}");
        if (item.uid == gameState.whoseTurn) {
          // print("getTextForTextBox: gameState.whoseTurn = ${gameState.whoseTurn}");
          if (item.uid == playerUid) {
            // print("getTextForTextBox: playerUid = ${playerUid}");
            returnString = yourString + turnString;
            break;
          } else {
            returnString = item.name + "'s" + turnString;
            // print("getTextForTextBox: returnString = ${returnString}");
            break;
          }
        }
      }
    }
    print("getTextForTextBox: string for text box = $returnString");
    return returnString;
  }

  // Generate player cards and store them in playerCardWidgets
  List<Widget> _generatePlayerCards() {
    List<Widget> tempCardWidgets = [];
    for (var i = 0; i < thisPlayerHand.length; i++) {
      tempCardWidgets.add(
        getCardWidget(
          dimensions.playerCardWidth,
          dimensions.playerCardHeight,
          i,
          thisPlayerHand[i],
          cardColors[
              (thisPlayerHand[i] / TOTAL_CARD_NUMBERS * numColors).round()],
          CardTypeEnum.THIS_PLAYER,
          highlightedCardIndex == i
              ? highlightCardBorderColor
              : allPlayerCardsBorderColor,
        ),
      );
    }
    return tempCardWidgets;
  }

  // Generate player cards and store them in playerCardWidgets
  List<Widget> _generateCenterCards() {
    List<Widget> tempCardWidgets = [];
    for (var i = 0; i < NUM_CENTER_PILES; i++) {
      tempCardWidgets.add(
        getCardWidget(
          dimensions.playerCardWidth,
          dimensions.playerCardHeight,
          i,
          thisCenterDeck[i],
          cardColors[
              (thisCenterDeck[i] / TOTAL_CARD_NUMBERS * numColors).round() - 1],
          CardTypeEnum.CENTER_DECK,
          centerPilesBorderColors[i],
        ),
      );
    }
    return tempCardWidgets;
  }

  // Creates player card row/s using cardWidgets
  // Returns two rows in case of a 1 player game, otherwise one row
  Widget _getPlayerCardsRows() {
    if (dimensions.numPlayers < 0) {
      return Column(
        children: [
          Row(
            children: playerCardWidgets.sublist(
                0,
                thisPlayerHand.length < dimensions.numCardsWidth
                    ? thisPlayerHand.length
                    : dimensions.numCardsWidth),
            mainAxisAlignment: MainAxisAlignment.center,
          ),
          Row(
            children: playerCardWidgets.sublist(dimensions.numCardsWidth),
            mainAxisAlignment: MainAxisAlignment.center,
          ),
        ],
      );
    } else {
      return Row(
        children: playerCardWidgets,
        mainAxisAlignment: MainAxisAlignment.center,
      );
    }
  }

  Widget _getCenterDecksRow() {
    return Column(
      children: [
        // Up and down arrow icons
        Row(
          children: [
            Container(
              child: Icon(
                Icons.arrow_upward,
                color: arrowIconColor,
                size: dimensions.playerCardWidth,
              ),
              margin: const EdgeInsets.all(cardMargin),
            ),
            Container(
              child: Icon(
                Icons.arrow_upward,
                color: arrowIconColor,
                size: dimensions.playerCardWidth,
              ),
              margin: const EdgeInsets.all(cardMargin),
            ),
            Container(
              child: Icon(
                Icons.arrow_downward,
                color: arrowIconColor,
                size: dimensions.playerCardWidth,
              ),
              margin: const EdgeInsets.all(cardMargin),
            ),
            Container(
              child: Icon(
                Icons.arrow_downward,
                color: arrowIconColor,
                size: dimensions.playerCardWidth,
              ),
              margin: const EdgeInsets.all(cardMargin),
            )
          ],
          mainAxisAlignment: MainAxisAlignment.center,
        ),
        // Actual center cards
        Row(
          children: centerCardWidgets,
          mainAxisAlignment: MainAxisAlignment.center,
        ),
        // Displays number of cards left in draw pile
        Container(
          child: Text(
            numCardsDrawPileString + gameState.drawPile.length.toString(),
            style: defaultTextStyle,
          ),
          margin: const EdgeInsets.all(textBoxMargin),
        ),
      ],
    );
  }

  // Function to generate an entire new game state using RNG
  void generateNewGameState() {
    // Generating deck
    gameState.drawPile =
        List.generate(TOTAL_NUM_PLAYING_CARDS, (index) => index + 2);
    // Shuffle deck
    gameState.drawPile.shuffle();
    // Distribute cards to each player
    for (int playerIdx = 0; playerIdx < playerList.length; playerIdx++) {
      gameState.playersHands.add(PlayerHand());
      // Assigning player Uid to identify player
      gameState.playersHands[playerIdx].playerUid = playerList[playerIdx].uid;
      for (int cardNum = 0; cardNum < gameState.handLimit; cardNum++) {
        gameState.playersHands[playerIdx].cards.add(gameState.drawPile.last);
        gameState.drawPile.removeLast();
      }
      // Sort player hands
      gameState.playersHands[playerIdx].cards.sort();
    }
  }

  // DB callback function
  void onReceivePlayerList(List<PlayerInfo> tempPlayerList) async {
    playerList = tempPlayerList;
    gameState.numPlayers = playerList.length;

    // Generate new game state if current player pressed start button
    if (isGameStarter) {
      print("onReceivePlayerList player is starter");
      generateNewGameState();
      gameDatabaseService.writeGameState(gameState);
      populateThisPlayerHand();
    }
  }

  // DB callback function for getState
  void onReceiveGameState(GameState tempGameState) {
    setState(() {
      gameState = tempGameState;
      // Checking if draw pile is empty
      if (gameState.drawPile.length == 0) {
        minMovesPerTurn = END_MIN_MOVES_PER_TURN;
      } else {
        minMovesPerTurn = INITIAL_MIN_MOVES_PER_TURN;
      }
      if (!initialHandPopulated) {
        populateThisPlayerHand();
        initialHandPopulated = true;
      }
    });
  }

  // Populates this player's hand, which is used to display
  void populateThisPlayerHand() {
    print("populateThisPlayerHand: thisPlayerHand = $thisPlayerHand");
    setState(() {
      for (int playerIdx = 0; playerIdx < playerList.length; playerIdx++) {
        if (playerList[playerIdx].uid == playerUid) {
          thisPlayerHand = gameState.playersHands[playerIdx].cards;
        }
      }
      thisPlayerHand.sort();
    });
  }

  // Updating game state with new player hand
  void writeThisPlayerHandToGameState() {
    for (int playerIdx = 0; playerIdx < playerList.length; playerIdx++) {
      if (playerList[playerIdx].uid == playerUid) {
        gameState.playersHands[playerIdx].cards = thisPlayerHand;
        // TODO: Handle case when player plays all their cards but there are still cards in draw pile
        // Marking player as done if no cards left in their hand
        if (thisPlayerHand.length == 0) {
          gameState.playersHands[playerIdx].isDone = true;
        } else {
          gameState.playersHands[playerIdx].isDone = false;
        }
      }
    }
  }

  // DB callback when turn changes
  void onTurnChanged(String whoseTurn) {
    setState(() {
      gameState.whoseTurn = whoseTurn;
    });
    setState(() {
      gameDatabaseService.readGameState(gameState);
      if (whoseTurn == playerUid) {
        // gameState.numMovesDone = 0;
        print("It's my turn now");
      }
    });
    // Check if game is over (new player has no valid moves)
    if (whoseTurn == playerUid && isGameLost()) {
      gameDatabaseService.updateGameStatus(GameStatusEnum.LOST);
    }
  }

  // DB callback when center decks change
  void onCenterDecksChanged(List tempCenterDecksList) {
    print(
        "onCenterDecksChanged: tempCenterDecksList = ${tempCenterDecksList.toString()}");
    gameState.centerDecks = [];
    setState(() {
      for (int i = 0; i < tempCenterDecksList.length; i++) {
        CenterDeck tempCenterDeck = CenterDeck();
        tempCenterDeck.extremeValue = tempCenterDecksList[i];
        tempCenterDeck.isAscending = i < NUM_CENTER_PILES / 2;
        gameState.centerDecks.add(tempCenterDeck);
        thisCenterDeck[i] = tempCenterDecksList[i];
      }
    });
  }

  // When game status changes in DB
  void onGameStatusChanged(GameStatusEnum gameStatus) {
    setState(() {
      gameState.gameStatus = gameStatus;
    });
    if (gameStatus == GameStatusEnum.WAITING) {
      Navigator.of(context).pop(true);
    }
  }

  // When numMovesDone changes in DB
  void onNumMovesChanged(int newNumMoves) {
    setState(() {
      gameState.numMovesDone = newNumMoves;
    });
  }

  // Flash text box as error to tell player that it's someone else's turn
  void flashTextBox() async {
    if (textBoxColor != errorColor) {
      for (num reps = 0; reps < flashTimes; reps++) {
        // print("flashTextBox: setting text color to ${errorColor}");
        setState(() {
          textBoxColor = errorTextColor;
        });
        await Future.delayed(Duration(milliseconds: flashOnTimeMillis));
        // print("flashTextBox: setting text color to ${defaultTextColor}");
        setState(() {
          textBoxColor = defaultTextColor;
        });
        await Future.delayed(Duration(milliseconds: flashOffTimeMillis));
      }
    }
  }

  // Flash cards remaining text box as error to tell player that it's someone else's turn
  void flashCardsRemainingTextBox() async {
    if (cardsRemainingTextBoxColor != errorColor) {
      for (num reps = 0; reps < flashTimes; reps++) {
        // print("flashTextBox: setting text color to ${errorColor}");
        setState(() {
          cardsRemainingTextBoxColor = errorTextColor;
        });
        await Future.delayed(Duration(milliseconds: flashOnTimeMillis));
        // print("flashTextBox: setting text color to ${defaultTextColor}");
        setState(() {
          cardsRemainingTextBoxColor = defaultTextColor;
        });
        await Future.delayed(Duration(milliseconds: flashOffTimeMillis));
      }
    }
  }

  // Flash card borders for error/hint
  void flashCardBorder(Color color, int pileIndex) async {
    if (centerPilesBorderColors[pileIndex] != errorColor) {
      for (num reps = 0; reps < flashTimes; reps++) {
        // print("flashTextBox: setting text color to ${errorColor}");
        setState(() {
          centerPilesBorderColors[pileIndex] = errorCardBorderColor;
        });
        await Future.delayed(Duration(milliseconds: flashOnTimeMillis));
        // print("flashTextBox: setting text color to ${defaultTextColor}");
        setState(() {
          centerPilesBorderColors[pileIndex] = defaultCardBorderColor;
        });
        await Future.delayed(Duration(milliseconds: flashOffTimeMillis));
      }
    }
  }

  // Flash all player cards telling the player to select a card before trying to play
  void flashAllPlayerCards() async {
    if (allPlayerCardsBorderColor != suggestionCardBorderColor) {
      for (num reps = 0; reps < flashTimes; reps++) {
        // Break out of color flashing if player has selected a card
        if (highlightedCardIndex != -1) {
          break;
        }
        // print("flashTextBox: setting text color to ${errorColor}");
        setState(() {
          allPlayerCardsBorderColor = suggestionCardBorderColor;
        });
        await Future.delayed(Duration(milliseconds: flashOnTimeMillis));
        // print("flashTextBox: setting text color to ${defaultTextColor}");
        setState(() {
          allPlayerCardsBorderColor = defaultCardBorderColor;
        });
        await Future.delayed(Duration(milliseconds: flashOffTimeMillis));
      }
    }
  }

  // Handle exit icon / back gesture
  Future<bool> onExitPressed() async {
    print("onExitPressed: called");
    return (await showDialog(
          context: context,
          builder: (context) => new AlertDialog(
            title: Text(
              areYouSureString,
              style: defaultTextStyle,
            ),
            content: Text(
              noReturnString,
              style: defaultTextStyle,
            ),
            titleTextStyle: dialogTitleTextStyle,
            backgroundColor: primaryColor,
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  noString,
                  style: defaultTextStyle,
                ),
              ),
              TextButton(
                onPressed: onExitConfirmed,
                child: Text(
                  yesString,
                  style: defaultTextStyle,
                ),
              ),
            ],
          ),
        )) ??
        false;
  }

  // When exit is confirmed
  void onExitConfirmed() {
    print("onExitConfirmed: started");
    gameDatabaseService.clearGameStateFromDB();
    gameDatabaseService.updateGameStatus(GameStatusEnum.WAITING);
    // TODO: update entire game state in DB
    Navigator.of(context).pop(true);
  }
}
