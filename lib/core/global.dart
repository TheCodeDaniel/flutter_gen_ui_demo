import 'package:flutter/material.dart';

// Base handler method for navigation
void navigate(BuildContext context, {required Widget page}) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => page));
