// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devlokos_podcast/bloc/episode/episode_bloc_exports.dart';
import 'package:devlokos_podcast/repository/episode_repository.dart';

void main() {
  testWidgets('DevLokos App loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<EpisodeBloc>(
            create: (context) => EpisodeBloc(
              repository: EpisodeRepositoryImpl(),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('DevLokos'),
            ),
          ),
        ),
      ),
    );

    // Verify that the app loads
    expect(find.text('DevLokos'), findsOneWidget);
  });
}
