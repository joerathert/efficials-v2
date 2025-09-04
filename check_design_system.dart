#!/usr/bin/env dart

/// 🎨 Design System Compliance Checker
/// Run with: dart check_design_system.dart

import 'dart:io';
import 'lib/utils/design_checker.dart';

void main() async {
  print('🎨 Checking Efficials Design System Compliance...\n');

  final screensDir = Directory('lib/screens');
  if (!screensDir.existsSync()) {
    print('❌ lib/screens directory not found!');
    return;
  }

  int totalFiles = 0;
  int compliantFiles = 0;
  final allViolations = <String, List<String>>{};

  // Check all Dart files in screens directory
  await for (final entity in screensDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      totalFiles++;
      final content = await entity.readAsString();
      final violations = DesignChecker.checkFile(entity.path, content);

      if (violations.isEmpty) {
        compliantFiles++;
        print('✅ ${entity.path}');
      } else {
        allViolations[entity.path] = violations;
        print('❌ ${entity.path} (${violations.length} issues)');
      }
    }
  }

  // Print summary
  print('\n' + '=' * 50);
  print('📊 SUMMARY');
  print('=' * 50);
  print('Total screens: $totalFiles');
  print('Compliant: $compliantFiles');
  print('Need fixes: ${totalFiles - compliantFiles}');

  if (allViolations.isNotEmpty) {
    print('\n🚨 VIOLATIONS FOUND:');
    print('=' * 30);

    allViolations.forEach((file, violations) {
      print('\n📁 $file:');
      violations.forEach((violation) => print('  $violation'));
    });

    print('\n💡 FIXES NEEDED:');
    print('• Replace Colors.yellow with Theme.of(context).colorScheme.primary');
    print('• Replace Colors.white/Colors.black with theme colors');
    print('• Use Colors.black for sports logo');
    print('• Use colorScheme.onBackground for text');
    print('• See lib/design_system.md for full guidelines');
  } else {
    print('\n🎉 All screens follow the design system! Great job!');
  }

  print('\n📖 Resources:');
  print('• Design guide: lib/design_system.md');
  print('• Screen template: lib/templates/screen_template.dart');
  print('• Run this check: dart check_design_system.dart');
}
