// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gurukul/provider/api_provider.dart';
import 'package:gurukul/provider/tab_provider.dart';
import 'package:gurukul/view/HomeScreen/home_screen.dart';
import 'package:provider/provider.dart';

void main() {
  group('TabProvider', () {
    test('starts with currentTab at 0', () {
      final tabProvider = TabProvider();
      expect(tabProvider.currentTab, 0);
    });

    test('updates currentTab when newTab is set', () {
      final tabProvider = TabProvider();
      tabProvider.newTab = 2;
      expect(tabProvider.currentTab, 2);
    });

    test('option select test', () {
      final tabProvider = TabProvider();
      tabProvider.setQID = 3;
      tabProvider.setQID = 2;
      tabProvider.setQID = 5;
      tabProvider.setQID = 1;
      expect(tabProvider.qId, [3, 2, 5, 1]);
    });
  });
}
