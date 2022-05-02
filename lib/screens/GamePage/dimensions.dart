import 'package:flutter/material.dart';
import 'package:the_game/constants/numbers.dart' as myNumbers;

class Dimensions {
  // Number of players in the game
  late int numPlayers;

  // Layout dimensions, obtained from screen size
  late double layoutWidth;
  late double layoutHeight;

  // Player card dimensions, calculated
  late double playerCardHeight;
  late double playerCardWidth;

  // Center card dimensions, for now ignored,
  // because using same dimensions for all cards
  late double deckCardHeight;
  late double deckCardWidth;

  // Num of cards in a row for layout
  late int numCardsWidth;

  // Constructor
  Dimensions(BuildContext context, int numPlayers) {
    this.numPlayers = numPlayers;

    // Calculate number of cards width-wise in the layout
    calculateNumCardsWidth();
    getScreenDimensions(context);
    calculatePlayerCardDimensions();
  }

  void getScreenDimensions(BuildContext context) {
    // Get height and width of window
    this.layoutWidth = MediaQuery.of(context).size.width;
    var padding = MediaQuery.of(context).viewPadding;
    this.layoutHeight =
        MediaQuery.of(context).size.height - padding.top - kToolbarHeight;
  }

  // Function to calculate hand limit based on rules of game
  void calculateNumCardsWidth() {
    switch (numPlayers) {
      case 1:
      // TODO: Handle case for single player game with multiple rows?
        numCardsWidth = 8;
        break;
      case 2:
        numCardsWidth = 7;
        break;
      case 3:
      case 4:
      case 5:
        numCardsWidth = 6;
        break;
      default:
        numCardsWidth = 0;
    }
  }

  // Function to calculate dimensions of each card in the current view
  void calculatePlayerCardDimensions() {
    double maxCardHeight = layoutHeight / 4 - myNumbers.cardMargin * 2;
    double maxCardWidth =
        layoutWidth / numCardsWidth - myNumbers.cardMargin * 2;
    double tempCardWidth = maxCardHeight * myNumbers.cardAspectRatio;
    if (tempCardWidth < maxCardWidth) {
      playerCardHeight = maxCardHeight;
      playerCardWidth = playerCardHeight * myNumbers.cardAspectRatio;
    } else {
      playerCardWidth = maxCardWidth;
      playerCardHeight = playerCardWidth / myNumbers.cardAspectRatio;
    }
  }
}
