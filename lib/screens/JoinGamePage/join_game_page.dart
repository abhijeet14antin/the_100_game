import 'package:flutter/material.dart';
import 'package:the_game/constants/colors.dart';
import 'package:the_game/constants/strings.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:the_game/constants/numbers.dart';
import 'package:the_game/data/types.dart';
import 'package:the_game/theme/styles.dart';
import 'package:the_game/screens/GameLobbyPage/game_lobby_page.dart';
import 'dart:math';

class JoinGamePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: titleString,
      home: JoinView(),
    );
  }
}

class JoinView extends StatefulWidget {
  const JoinView({Key? key}) : super(key: key);

  @override
  _JoinViewState createState() => _JoinViewState();
}

class _JoinViewState extends State<JoinView> {
  late String gameCode = "";
  late BuildContext context;
  //late String playerUid;

  _JoinViewState() {}

  @override
  Widget build(BuildContext context) {
    this.context = context;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: Text(
          joinGameAppBarString,
          style: appBarTextStyle,
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(screenPadding),
        alignment: Alignment.center,
        child: Column(
          //mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              child: ElevatedButton(
                onPressed: onCreateButtonPressed,
                child: Text(createButtonString),
                style: myButtonStyle,
              ),
              margin: const EdgeInsets.all((joinPageMargin)),
            ),
            Container(
              child: ElevatedButton(
                onPressed: onJoinCustomPressed,
                child: Text(joinExistingButtonString),
                style: myButtonStyle,
              ),
              margin: const EdgeInsets.all((joinPageMargin)),
            ),
            Container(
              child: ElevatedButton(
                onPressed: onJoinRandomPressed,
                child: Text(joinRandomButtonString),
                style: myButtonStyle,
              ),
              margin: const EdgeInsets.all((joinPageMargin)),
            ),
          ],
          mainAxisAlignment: MainAxisAlignment.center,
        ),
      ),
      backgroundColor: appBackgroundColor,
    );
  }

  // When create new game button is pressed
  // Generates game codes until one is generated that's not already in DB
  void onCreateButtonPressed() async {
    LobbyPrivacyEnum lobbyPrivacy = LobbyPrivacyEnum.PRIVATE;
    // Creating new lobby that's not random
    await createNewLobby(lobbyPrivacy);
    // Navigate to Game Lobby screen
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) {
      return GameLobbyPage(gameCode, lobbyPrivacy);
    }));
  }

  // Creates a new game, common for create and
  // random (when no available game exists)
  Future<void> createNewLobby(LobbyPrivacyEnum lobbyPrivacy) async {
    final gamesRef = FirebaseDatabase.instance.ref("games");
    var tempGameCode = _generateGameCode();
    bool foundUniqueCode = false;
    while (!foundUniqueCode) {
      var child = await gamesRef.child(tempGameCode).get();
      var value = child.value;
      if (value == null) {
        foundUniqueCode = true;
        break;
      } else {
        tempGameCode = _generateGameCode();
      }
    }
    setState(() {
      gameCode = tempGameCode;
    });

    // Setting game_status and num_players in DB
    gamesRef
        .child(tempGameCode)
        .child("game_status")
        .set(GameStatusEnum.WAITING.index);

    // Setting random games to PUBLIC and intentional games to PRIVATE
    gamesRef
        .child(tempGameCode)
        .child("is_public")
        .set(lobbyPrivacy == LobbyPrivacyEnum.PUBLIC);
  }

  // When join custom game button is pressed
  void onJoinCustomPressed() {
    String inputCode = "";
    showDialog(
        context: context,
        builder: (BuildContext context) => SimpleDialog(
              title: Text(enterGameCodeString),
              titleTextStyle: defaultTextStyle,
              backgroundColor: primaryColor,
              children: [
                Column(
                  children: [
                    Container(
                      child: TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: textFieldBorderColor),
                          ),
                          labelText: codeTextFieldLabelString,
                          labelStyle: textFieldLabelTextStyle,
                          fillColor: textFieldBackgroundColor,
                        ),
                        style: textFieldTextStyle,
                        textCapitalization: TextCapitalization.characters,
                        onSubmitted: _onGameCodeEntered,
                        onChanged: (code) => inputCode = code,
                        cursorColor: cursorColor,
                      ),
                      margin: const EdgeInsets.all((lobbyPageMargin)),
                    ),
                    Row(
                      children: [
                        Container(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context, 'Cancel'),
                            child: Text(
                              cancelButtonString,
                              style: buttonTextStyle,
                            ),
                          ),
                          margin: const EdgeInsets.all((lobbyPageMargin)),
                        ),
                        Container(
                          child: TextButton(
                            onPressed: () => _onGameCodeEntered(inputCode),
                            child: Text(
                              confirmButtonString,
                              style: buttonTextStyle,
                            ),
                          ),
                          margin: const EdgeInsets.all((lobbyPageMargin)),
                        ),
                      ],
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                    )
                  ],
                )
              ],
            ));
  }

  // When join random game button is pressed
  void onJoinRandomPressed() async {
    // TODO: Find game with available slots, or create new game
    // Iterate through all existing game codes and find any available games
    bool gameFound = false;
    final gamesRef = FirebaseDatabase.instance.ref("games");
    var event = await gamesRef.once(DatabaseEventType.value);
    if (event.snapshot.value == null) {
      // Should never come here
      print("Invalid code");
    } else {
      var tempGameCodes = Map.from(event.snapshot.value as Map);
      print("tempGameCodes = " + tempGameCodes.runtimeType.toString());
      print("length = " + tempGameCodes.length.toString());
      tempGameCodes.forEach((gameCode, value) {
        print("gameCode = " + gameCode.toString());
        print("value = " + value.runtimeType.toString());
        if (gameCode == null) {
          // TODO: Display invalid message
          print("Invalid code");
        } else if (!value["is_public"]) {
          // TODO: Display private message
          print("private room");
        } else if (value["game_status"] == GameStatusEnum.FULL.index) {
          // TODO: Display full message
          print("game full");
        } else if (value["game_status"] == GameStatusEnum.WAITING.index) {
          gameFound = true;
          // Navigate to Game Lobby screen
          Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (context) {
            return GameLobbyPage(gameCode, LobbyPrivacyEnum.DEFAULT);
          }));
        } else if (value["game_status"] == GameStatusEnum.SETUP.index) {
          // TODO: Display game is progress, can't join
          print("game in progress - choosing starter");
        } else if (value["game_status"] == GameStatusEnum.PLAYING.index) {
          // TODO: Display game is progress, can't join
          print("game in progress");
        } else if (value["game_status"] == GameStatusEnum.WON.index ||
            value["game_status"] == GameStatusEnum.LOST.index) {
          // TODO: Display completed message
          print("game completed");
        }
      });
    }

    // If no game found, create your own game
    if (!gameFound) {
      LobbyPrivacyEnum lobbyPrivacy = LobbyPrivacyEnum.PUBLIC;
      // Creating new lobby that's public
      await createNewLobby(lobbyPrivacy);
      // Navigate to Game Lobby screen
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) {
        return GameLobbyPage(gameCode, lobbyPrivacy);
      }));
    }
  }

  // Generates game code without checking in DB!
  String _generateGameCode() {
    String code = "";
    var rng = Random();
    for (int i = 0; i < codeLength; i++) {
      code += String.fromCharCode(rng.nextInt(numLetters) + AsciiOffset);
    }
    return code;
  }

  // When game code is entered in dialog
  void _onGameCodeEntered(String code) async {
    final gamesRef = FirebaseDatabase.instance.ref("games");
    // Checking validity of code based on game status & privacy
    var child = await gamesRef.child(code).get();
    if (child.value == null) {
      // TODO: Display invalid message
      print("Invalid code");
    } else if (child.child("game_status").value == GameStatusEnum.FULL.index) {
      // TODO: Display full message
      print("game full");
    } else if (child.child("game_status").value ==
        GameStatusEnum.WAITING.index) {
      // Navigate to Game Lobby screen
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) {
        return GameLobbyPage(code, LobbyPrivacyEnum.DEFAULT);
      }));
    } else if (child.child("game_status").value ==
        GameStatusEnum.PLAYING.index) {
      // TODO: Display game is progress, can't join
      print("game in progress");
    } else if (child.child("game_status").value == GameStatusEnum.WON.index ||
        child.child("game_status").value == GameStatusEnum.LOST.index) {
      // TODO: Display completed message
      print("game completed");
    }
  }
}
