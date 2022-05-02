import 'package:flutter/material.dart';
import 'package:the_game/constants/colors.dart';
import 'package:the_game/constants/strings.dart';
import 'package:the_game/constants/numbers.dart';
import 'package:the_game/data/models.dart';
import 'package:the_game/data/types.dart';
import 'package:the_game/theme/styles.dart';
import 'package:the_game/screens/GamePage/game_page.dart';
import 'package:the_game/screens/GameLobbyPage/game_lobby_database_service.dart';
import 'package:flutter/services.dart';

const String DEFAULT_NAME = "NoName";

late String gameCode;
bool isLobbyPublic = false;

class GameLobbyPage extends StatelessWidget {
  GameLobbyPage(String tempGameCode, LobbyPrivacyEnum tempLobbyPrivacy) {
    gameCode = tempGameCode;
    // If lobby privacy is default, keep whatever is already present
    if (tempLobbyPrivacy != LobbyPrivacyEnum.DEFAULT) {
      isLobbyPublic = tempLobbyPrivacy == LobbyPrivacyEnum.PUBLIC;
    }
    //playerUid = tempPlayerUid;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: titleString,
      home: LobbyView(),
    );
  }
}

class LobbyView extends StatefulWidget {
  const LobbyView({Key? key}) : super(key: key);

  @override
  _LobbyViewState createState() => _LobbyViewState();
}

class _LobbyViewState extends State<LobbyView> with WidgetsBindingObserver {
  late BuildContext context;
  List<PlayerInfo> playersList = [];
  late String playerName = DEFAULT_NAME;
  late LobbyDatabaseService lobbyDatabaseService;
  bool gameStarted = false;

  _LobbyViewState() {
    lobbyDatabaseService = LobbyDatabaseService(
      playerUidGeneratedCallback: onPlayerUidGenerated,
      playerAddedCallback: onPlayerAdded,
      playerRemovedCallback: onPlayerRemoved,
      playerChangedCallback: onPlayerChanged,
      cardsDealtCallback: onCardsDealt,
      lobbyPrivacyCallback: onLobbyPrivacyChanged,
      gameCode: gameCode,
      playerName: playerName,
    );
  }

  @override
  Widget build(BuildContext context) {
    this.context = context;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: Text(
          gameLobbyAppBarString,
          style: appBarTextStyle,
        ),
      ),
      body: getLobbyPage(context),
      backgroundColor: appBackgroundColor,
    );
  }

  // Gets default display page for this screen
  Container getLobbyPage(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(16.0),
        child: ListView(children: [
          Container(
            child: Row(
              children: [
                Text(
                  codeDisplayString,
                  style: defaultTextStyle,
                ),
                InkWell(
                  child: Row(
                    children: [
                      Text(
                        gameCode,
                        style: boldLargeTextStyle,
                      ),
                      IconButton(
                          onPressed: copyGameCodeToClipboard,
                          icon: Icon(
                            Icons.copy,
                            color: copyIconColor,
                            size: copyIconSize,
                          )),
                    ],
                  ),
                  onTap: copyGameCodeToClipboard,
                )
              ],
              mainAxisAlignment: MainAxisAlignment.center,
            ),
            margin: const EdgeInsets.all((lobbyPageMargin)),
          ),
          Container(
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: textFieldBorderColor),
                ),
                labelText: nameTextFieldLabelString,
                labelStyle: textFieldLabelTextStyle,
                fillColor: textFieldBackgroundColor,
              ),
              style: textFieldTextStyle,
              textCapitalization: TextCapitalization.words,
              onSubmitted: _updatePlayerName,
              onChanged: _updatePlayerName,
              cursorColor: cursorColor,
            ),
            margin: const EdgeInsets.all((lobbyPageMargin)),
          ),
          Container(
            child: SwitchListTile(
              title: Text(publicLobbyString, style: defaultTextStyle),
              value: isLobbyPublic,
              onChanged: (bool value) => onIsPublicSwitchChanged(value),
              activeColor: secondaryColorAccent,
            ),
          ),
          Container(
            child: ElevatedButton(
              onPressed: () => onDealPressed(isPlayerStarter: true),
              child: Text(dealCardsButtonString),
              style: myButtonStyle,
            ),
            margin: const EdgeInsets.all((joinPageMargin)),
          ),
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  playersString,
                  style: defaultTextStyle,
                ),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: playersList.length,
                  itemBuilder: (context, index) {
                    return Center(
                      child: Text(
                        playersList[index].name == playerName
                            ? playerName + youString
                            : playersList[index].name,
                        style: defaultTextStyle,
                      ),
                    );
                  },
                ),
              ],
            ),
            margin: const EdgeInsets.all((lobbyPageMargin)),
          ),
        ]));
  }

  // Function called when player changes name
  void _updatePlayerName(String name) async {
    if (this.mounted) {
      setState(() {
        playerName = name;
        if (playerName == "") {
          playerName = DEFAULT_NAME;
        }
      });
    }
    lobbyDatabaseService.updatePlayerNameInDB(playerName);
  }

  // Getting the assigned UID for player
  void onPlayerUidGenerated(String tempPlayerUid) {
    playerUid = tempPlayerUid;
  }

  // Callback function when player added in DB
  void onPlayerAdded(PlayerInfo playerInfo) {
    if (this.mounted) {
      setState(() {
        playersList.add(playerInfo);
      });
    }
    // Set game_status to full in DB
    if (playersList.length == MAX_NUM_PLAYERS) {
      lobbyDatabaseService.updateGameStatus(GameStatusEnum.FULL);
    }
  }

  // Callback function when player added in DB
  void onPlayerRemoved(PlayerInfo playerInfo) {
    if (this.mounted) {
      setState(() {
        playersList.removeWhere((item) => item.uid == playerInfo.uid);
      });
    }
    // Set game_status to waiting in DB if lobby is no longer full
    if (playersList.length == MAX_NUM_PLAYERS - 1) {
      lobbyDatabaseService.updateGameStatus(GameStatusEnum.WAITING);
    }
  }

  // Callback function when player added in DB
  void onPlayerChanged(PlayerInfo playerInfo) {
    if (this.mounted) {
      var idx = playersList.indexWhere((item) => item.uid == playerInfo.uid);
      setState(() {
        playersList[idx] = playerInfo;
      });
    }
  }

  // Function when public/private switch is pressed
  onIsPublicSwitchChanged(bool tempIsPublic) {
    setState(() {
      isLobbyPublic = tempIsPublic;
    });
    lobbyDatabaseService.updateLobbyPrivacy(isLobbyPublic);
  }

  // Callback for change in lobby privacy
  void onLobbyPrivacyChanged(bool newIsPublic) {
    setState(() {
      isLobbyPublic = newIsPublic;
    });
  }

  // Callback for when someone else starts the game
  void onCardsDealt() {
    // Start game if this player is not who started the game
    if (!gameStarted) {
      onDealPressed(isPlayerStarter: false);
    }
  }

  // TODO: Include a timer for starting the game

  // When deal cards button is pressed
  void onDealPressed({bool isPlayerStarter = false}) {
    // TODO: Handle case when two players press deal at the same time - transactions
    gameStarted = true;
    // Navigate to Game Lobby screen
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) {
      return GamePage(gameCode, playersList.length, playerUid, isPlayerStarter);
    }));
  }

  // Copies game code to clipboard
  void copyGameCodeToClipboard() {
    Clipboard.setData(ClipboardData(text: gameCode));
  }

  // Clean up player if app is closed
  @mustCallSuper
  @override
  void dispose() {
    print("game lobby dispose called");
    lobbyDatabaseService.removePlayerFromDb(playerUid);
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }
}
