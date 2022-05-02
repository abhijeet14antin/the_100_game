import 'package:flutter/material.dart';
import 'package:the_game/constants/numbers.dart';
import 'package:the_game/constants/colors.dart';

TextStyle appBarTextStyle = TextStyle(
  fontSize: defaultFontSize,
);
TextStyle textFieldLabelTextStyle = TextStyle(
  fontSize: defaultFontSize,
  color: defaultTextColor,
);
TextStyle textFieldTextStyle = TextStyle(
  fontSize: defaultFontSize,
  color: defaultTextColor,
);
TextStyle defaultTextStyle = TextStyle(
  fontSize: defaultFontSize,
  color: defaultTextColor,
);
TextStyle defaultTextStyleWithColor(Color? color) {
  return TextStyle(
    fontSize: defaultFontSize,
    color: color == null ? defaultTextColor : color,
  );
}
TextStyle buttonTextStyle = TextStyle(
  fontSize: defaultFontSize,
  color: defaultTextColor,
);
TextStyle cardTextStyle = TextStyle(
  fontSize: defaultFontSize,
  color: defaultTextColor,
);
TextStyle boldLargeTextStyle = TextStyle(
  fontSize: largeFontSize,
  color: defaultTextColor,
  fontWeight: FontWeight.bold,
);
TextStyle dialogTitleTextStyle = TextStyle(
  fontSize: defaultFontSize,
  color: defaultTextColor,
  fontWeight: FontWeight.bold,
);

var myButtonStyle = ElevatedButton.styleFrom(
  textStyle: const TextStyle(
    fontSize: buttonTextFontSize,
  ),
  padding: EdgeInsets.all(joinPageMargin),
  primary: buttonColor,
);

var cardTheme = CardTheme(
    shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(
  Radius.circular(8.0),
)));
