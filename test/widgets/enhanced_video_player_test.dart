import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devlokos_podcast/widgets/enhanced_video_player.dart';

void main() {
  group('EnhancedVideoPlayer', () {
    testWidgets('should display error for invalid video ID', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedVideoPlayer(
              videoId: 'invalid_id',
              title: 'Test Video',
            ),
          ),
        ),
      );

      // Wait for the widget to initialize
      await tester.pumpAndSettle();

      // Should show error message for invalid video ID
      expect(find.text('Error al cargar el video'), findsOneWidget);
      expect(find.text('ID de video no válido'), findsOneWidget);
    });

    testWidgets('should display loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedVideoPlayer(
              videoId: 'dQw4w9WgXcQ', // Valid YouTube video ID
              title: 'Test Video',
            ),
          ),
        ),
      );

      // Should show loading initially
      expect(find.text('Cargando video...'), findsOneWidget);
    });

    testWidgets('should have retry and open in YouTube buttons on error', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedVideoPlayer(
              videoId: 'invalid_id',
              title: 'Test Video',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have retry button
      expect(find.text('Reintentar'), findsOneWidget);
      
      // Should have open in YouTube button
      expect(find.text('Abrir en YouTube'), findsOneWidget);
    });
  });
}
