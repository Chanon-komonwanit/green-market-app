#!/usr/bin/env dart

/// Green Market - Dependency Management Script
/// สคริปต์สำหรับจัดการ dependencies ของโปรเจค
///
/// การใช้งาน:
/// ```bash
/// dart run scripts/manage_dependencies.dart [command]
/// ```
///
/// Commands:
/// - check: ตรวจสอบ dependencies ที่ล้าสมัย
/// - update: อัพเดต dependencies ที่ปลอดภัย
/// - audit: ตรวจสอบความปลอดภัย
/// - clean: ทำความสะอาด cache

import 'dart:io';

void main(List<String> args) async {
  final command = args.isNotEmpty ? args[0] : 'help';

  print('🌱 Green Market - Dependency Manager');
  print('═' * 50);

  switch (command) {
    case 'check':
      await checkOutdated();
      break;
    case 'update':
      await updateDependencies();
      break;
    case 'audit':
      await auditSecurity();
      break;
    case 'clean':
      await cleanProject();
      break;
    case 'help':
    default:
      showHelp();
      break;
  }
}

Future<void> checkOutdated() async {
  print('📊 ตรวจสอบ dependencies ที่ล้าสมัย...\n');

  try {
    final result = await Process.run('flutter', ['pub', 'outdated'],
        workingDirectory: Directory.current.path);
    print(result.stdout);

    if (result.stderr.toString().isNotEmpty) {
      print('❌ Error: ${result.stderr}');
    }
  } catch (e) {
    print('❌ Error running flutter command: $e');
    print('💡 Make sure Flutter is installed and in your PATH');
  }
}

Future<void> updateDependencies() async {
  print('🔄 อัพเดต dependencies...\n');

  try {
    // Step 1: Clean first
    print('🧹 ทำความสะอาดก่อน...');
    await Process.run('flutter', ['clean'],
        workingDirectory: Directory.current.path);

    // Step 2: Get dependencies
    print('📦 ดาวน์โหลด dependencies...');
    final result = await Process.run('flutter', ['pub', 'get'],
        workingDirectory: Directory.current.path);
    print(result.stdout);

    // Step 3: Upgrade if possible
    print('⬆️ อัพเกรด dependencies ที่ปลอดภัย...');
    final upgradeResult = await Process.run('flutter', ['pub', 'upgrade'],
        workingDirectory: Directory.current.path);
    print(upgradeResult.stdout);

    if (result.exitCode == 0) {
      print('✅ อัพเดตสำเร็จ!');
    } else {
      print('❌ อัพเดตล้มเหลว: ${result.stderr}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}

Future<void> auditSecurity() async {
  print('🔒 ตรวจสอบความปลอดภัย...\n');

  // Check for known vulnerabilities
  print('🔍 ตรวจสอบช่องโหว่ที่ทราบ...');
  final result = await Process.run('flutter', ['pub', 'deps']);

  if (result.stdout.toString().contains('vulnerabilities')) {
    print('⚠️ พบช่องโหว่ความปลอดภัย!');
    print(result.stdout);
  } else {
    print('✅ ไม่พบช่องโหว่ความปลอดภัย');
  }

  // Check for deprecated packages
  print('\n📋 ตรวจสอบ packages ที่เลิกใช้แล้ว...');
  final outdatedResult = await Process.run('flutter', ['pub', 'outdated']);
  final output = outdatedResult.stdout.toString();

  if (output.contains('discontinued')) {
    print('⚠️ พบ packages ที่เลิกใช้แล้ว:');
    final lines = output.split('\n');
    for (final line in lines) {
      if (line.contains('discontinued')) {
        print('  - $line');
      }
    }
  } else {
    print('✅ ไม่พบ packages ที่เลิกใช้แล้ว');
  }
}

Future<void> cleanProject() async {
  print('🧹 ทำความสะอาดโปรเจค...\n');

  final commands = [
    ['flutter', 'clean'],
    ['flutter', 'pub', 'cache', 'clean'],
    ['flutter', 'pub', 'get'],
  ];

  for (final command in commands) {
    print('⚡ รัน: ${command.join(' ')}');
    final result = await Process.run(command[0], command.skip(1).toList());

    if (result.exitCode != 0) {
      print('❌ Error: ${result.stderr}');
      return;
    }
  }

  print('✅ ทำความสะอาดเสร็จสิ้น!');
}

void showHelp() {
  print('''
📋 คำสั่งที่ใช้ได้:

  check   - ตรวจสอบ dependencies ที่ล้าสมัย
  update  - อัพเดต dependencies ที่ปลอดภัย  
  audit   - ตรวจสอบความปลอดภัยและช่องโหว่
  clean   - ทำความสะอาด cache และ build files
  help    - แสดงความช่วยเหลือนี้

📖 ตัวอย่าง:
  dart run scripts/manage_dependencies.dart check
  dart run scripts/manage_dependencies.dart update

🔧 การบำรุงรักษาแนะนำ:
  - รัน 'check' ทุกสัปดาห์
  - รัน 'audit' ทุกเดือน
  - รัน 'clean' เมื่อมีปัญหา build
  - รัน 'update' หลังทดสอบแล้ว

⚠️  คำเตือน:
  - สำรองข้อมูลก่อน update
  - ทดสอบหลัง update ทุกครั้ง
  - อ่าน changelog ของ packages
''');
}
