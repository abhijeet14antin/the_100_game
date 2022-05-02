// Font sizes
const double defaultFontSize = 20;
const double largeFontSize = 24;
const double appBarFontSize = defaultFontSize;
const double cardNumFontSize = defaultFontSize;
const double textFieldLabelFontSize = defaultFontSize;
const double buttonTextFontSize = defaultFontSize;

// Card
const double cardAspectRatio = 2 / 3;
const double defaultCardElevation = 1;
const double highlightedCardElevation = 8;
const double cardBorderRadius = 8;
const double cardBorderWidth = 4;
const double arrowSize = 24;

// Screen padding
const double screenPadding = 16;

// Margins
const double cardMargin = 4;
const double joinPageMargin = 16;
const double lobbyPageMargin = 16;
const double textBoxMargin = 16;

//----------RNG----------//
// Length of game room code
const int codeLength = 4;
const int numLetters = 26;
const int AsciiOffset = 65;

// Hardcoded constants
const int MAX_NUM_PLAYERS = 5;
const int NUM_CENTER_PILES = 4;
const int TOTAL_CARD_NUMBERS = 100;
const int TOTAL_NUM_PLAYING_CARDS = TOTAL_CARD_NUMBERS - 2;
const int CENTER_START_NUM = 1;
const int CENTER_END_NUM = TOTAL_CARD_NUMBERS;
const int INITIAL_MIN_MOVES_PER_TURN = 2;
const int END_MIN_MOVES_PER_TURN = 1;
const int BACKWARDS_DIFF = 10;

// Icon size
const double appBarIconSize = 32;
const double copyIconSize = 32;

// Colors
const int numColors = TOTAL_CARD_NUMBERS;
const List colorRange = [0.5, 0.7];

// Timer/sleep
const int timeSecondInMillis = 1000;
const int timeTenthSecondInMillis = 100;
const int timeTwentiethSecondInMillis = 50;
const int flashTimes = 2;
const int flashOnTimeMillis = 3 * timeTenthSecondInMillis;
const int flashOffTimeMillis = 2 * timeTenthSecondInMillis;
