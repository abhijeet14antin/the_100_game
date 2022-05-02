import 'package:flutter/material.dart';
import 'package:the_game/screens/JoinGamePage/join_game_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:the_game/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // TODO: Sign in page to optionally create account for history + stats
  runApp(JoinGamePage());
}

// TODO: Fix order of all imports!

// TODO: Handle player leaving the game (just remove player from list should be enough?)

// TODO: Fix initial draw pile size bug

// TODO: Fix case in single player game where player plays more than 4 cards, causes UI bug

// TODO: Fix app & website icons & titles

// TODO Restart game option in same game

// TODO: Add done button under "minimum moves remaining" text ?

// TODO: Handle player leaving lobby

// TODO: Handle player leaving mid game (implement close icon properly)

// TODO: Handle back button everywhere

// TODO: Handle onExit, onDestroy or their equivalent

// TODO: Move a lot of functions to GameState class!!!!!!!!!!!

// TODO: Handle logic for deleting game from database (only if last player leaves the game/lobby)

// TODO: Handle visual bug for single player game on browser (for now, just put 8 cards in a row - we will need to make this two rows of 4 cards each)

// TODO: Generate cool starting names (instead of NoName). Highlight said name in text field on lobby startup

// TODO: Add statistics for number of games in progress, number of games started!

// TODO: Make individual call/callbacks for game state <=> DB interaction, instead of doing the entire game state at the same time

// TODO: Handle deletion of game state

// TODO: I'm ready option ?

// TODO: Game starting timer, with cancel option

// TODO: Automatically become next player's turn if a player plays all their cards and there are still cards in the draw pile

// TODO: Add single undo button -> need to make center piles into decks instead of single extreme values

// TODO: Replace all int/double with num

// TODO: Replace "once" with "get" everywhere

// TODO: Save name on device?

// TODO: Center (make small) InputText and button in Lobby

// TODO: Handle starter in single player game