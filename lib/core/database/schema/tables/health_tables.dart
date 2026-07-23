import 'package:sqflite/sqflite.dart';

class HealthTables {
  static Future<void> create(Database db) async {
    // 21. prn_logs (V2 table)
    await db.execute('''
      CREATE TABLE prn_logs (
          id TEXT PRIMARY KEY,
          routineId TEXT NOT NULL,
          takenAt INTEGER NOT NULL,
          dosage TEXT,
          createdAt INTEGER NOT NULL,
          FOREIGN KEY(routineId) REFERENCES routines(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX index_prn_logs_routineId ON prn_logs(routineId);');
    await db.execute('CREATE INDEX index_prn_logs_takenAt ON prn_logs(takenAt);');

    // 22. doctor_visits (V11 table)
    await db.execute('''
      CREATE TABLE doctor_visits (
          id TEXT PRIMARY KEY, doctorName TEXT NOT NULL, specialty TEXT,
          clinicName TEXT, clinicAddress TEXT, clinicPhone TEXT,
          visitDateTime INTEGER NOT NULL, visitType TEXT NOT NULL DEFAULT 'IN_PERSON',
          status TEXT NOT NULL DEFAULT 'UPCOMING', reason TEXT,
          doctorNotes TEXT, userNotes TEXT, followUpDate INTEGER,
          reminderBefore INTEGER NOT NULL DEFAULT 60, attachmentPath TEXT,
          createdAt INTEGER NOT NULL, updatedAt INTEGER NOT NULL
      );
    ''');

    // 23. blood_sugar_logs (V11 table)
    await db.execute('''
      CREATE TABLE blood_sugar_logs (
          id TEXT PRIMARY KEY, value INTEGER NOT NULL,
          measurementType TEXT NOT NULL DEFAULT 'FASTING', note TEXT, loggedAt INTEGER NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX idx_bs_loggedAt ON blood_sugar_logs(loggedAt);');

    // 24. blood_pressure_logs (V11 table)
    await db.execute('''
      CREATE TABLE blood_pressure_logs (
          id TEXT PRIMARY KEY, systolic INTEGER NOT NULL, diastolic INTEGER NOT NULL,
          pulse INTEGER, arm TEXT DEFAULT 'LEFT', position TEXT DEFAULT 'SITTING',
          note TEXT, loggedAt INTEGER NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX idx_bp_loggedAt ON blood_pressure_logs(loggedAt);');

    // 25. vital_signs_logs (V11 table)
    await db.execute('''
      CREATE TABLE vital_signs_logs (
          id TEXT PRIMARY KEY, vitalType TEXT NOT NULL, value REAL NOT NULL,
          unit TEXT NOT NULL, note TEXT, loggedAt INTEGER NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX idx_vs_loggedAt ON vital_signs_logs(loggedAt);');

    // 26. medical_documents (V11 table)
    await db.execute('''
      CREATE TABLE medical_documents (
          id TEXT PRIMARY KEY, title TEXT NOT NULL, category TEXT NOT NULL,
          documentDate INTEGER NOT NULL, labName TEXT, summary TEXT,
          doctorNotes TEXT, userNotes TEXT, createdAt INTEGER NOT NULL, updatedAt INTEGER NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX idx_md_category ON medical_documents(category);');
    await db.execute('CREATE INDEX idx_md_documentDate ON medical_documents(documentDate);');

    // 27. medical_document_images (V11 table)
    await db.execute('''
      CREATE TABLE medical_document_images (
          id TEXT PRIMARY KEY, documentId TEXT NOT NULL, imagePath TEXT NOT NULL,
          pageNumber INTEGER DEFAULT 1, caption TEXT,
          FOREIGN KEY(documentId) REFERENCES medical_documents(id) ON DELETE CASCADE
      );
    ''');

    // 28. vaccinations (V11 table)
    await db.execute('''
      CREATE TABLE vaccinations (
          id TEXT PRIMARY KEY, vaccineName TEXT NOT NULL, diseaseTarget TEXT,
          doseNumber INTEGER DEFAULT 1, totalDoses INTEGER, dateAdministered INTEGER,
          nextDoseDue INTEGER, batchNumber TEXT, clinicName TEXT, notes TEXT,
          createdAt INTEGER NOT NULL, updatedAt INTEGER NOT NULL
      );
    ''');

    // 29. allergies (V11 table)
    await db.execute('''
      CREATE TABLE allergies (
          id TEXT PRIMARY KEY, allergen TEXT NOT NULL, category TEXT NOT NULL,
          reaction TEXT, severity TEXT NOT NULL DEFAULT 'MODERATE',
          diagnosedDate INTEGER, notes TEXT, createdAt INTEGER NOT NULL
      );
    ''');

    // 30. medical_profile (V11 table)
    await db.execute('''
      CREATE TABLE medical_profile (
          id TEXT PRIMARY KEY, profileKey TEXT NOT NULL UNIQUE,
          profileValue TEXT NOT NULL, updatedAt INTEGER NOT NULL
      );
    ''');

    // 31. pregnancy_tracker (V11 table)
    await db.execute('''
      CREATE TABLE pregnancy_tracker (
          id TEXT PRIMARY KEY, lmpDate TEXT NOT NULL, estimatedDueDate TEXT NOT NULL,
          currentWeek INTEGER NOT NULL, currentTrimester INTEGER NOT NULL,
          isActive INTEGER NOT NULL DEFAULT 1, notes TEXT,
          createdAt INTEGER NOT NULL, updatedAt INTEGER NOT NULL
      );
    ''');

    // 32. pregnancy_checkups (V11 table)
    await db.execute('''
      CREATE TABLE pregnancy_checkups (
          id TEXT PRIMARY KEY, pregnancyId TEXT NOT NULL, title TEXT NOT NULL,
          scheduledDate INTEGER, actualDate INTEGER, type TEXT NOT NULL,
          result TEXT, notes TEXT, isCompleted INTEGER DEFAULT 0, createdAt INTEGER NOT NULL,
          FOREIGN KEY(pregnancyId) REFERENCES pregnancy_tracker(id) ON DELETE CASCADE
      );
    ''');

    // 33. pregnancy_symptoms (V11 table)
    await db.execute('''
      CREATE TABLE pregnancy_symptoms (
          id TEXT PRIMARY KEY, pregnancyId TEXT NOT NULL, date TEXT NOT NULL,
          symptom TEXT NOT NULL, severity TEXT DEFAULT 'MILD', note TEXT,
          FOREIGN KEY(pregnancyId) REFERENCES pregnancy_tracker(id) ON DELETE CASCADE
      );
    ''');

    // 34. kick_counts (V11 table)
    await db.execute('''
      CREATE TABLE kick_counts (
          id TEXT PRIMARY KEY, pregnancyId TEXT NOT NULL, startTime INTEGER NOT NULL,
          endTime INTEGER, kickCount INTEGER, loggedAt INTEGER NOT NULL,
          FOREIGN KEY(pregnancyId) REFERENCES pregnancy_tracker(id) ON DELETE CASCADE
      );
    ''');

    // 35. contraction_timer (V11 table)
    await db.execute('''
      CREATE TABLE contraction_timer (
          id TEXT PRIMARY KEY, pregnancyId TEXT NOT NULL, startTime INTEGER NOT NULL,
          endTime INTEGER, durationSeconds INTEGER, intervalFromPrevious INTEGER,
          loggedAt INTEGER NOT NULL,
          FOREIGN KEY(pregnancyId) REFERENCES pregnancy_tracker(id) ON DELETE CASCADE
      );
    ''');

    // 36. medication_logs (V21 table)
    await db.execute('''
      CREATE TABLE medication_logs (
          id TEXT PRIMARY KEY,
          routineId TEXT NOT NULL,
          scheduledTime INTEGER,
          takenTime INTEGER,
          status TEXT NOT NULL DEFAULT 'TAKEN',
          note TEXT,
          createdAt INTEGER NOT NULL,
          FOREIGN KEY(routineId) REFERENCES routines(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX idx_medlog_routine ON medication_logs(routineId);');
    await db.execute('CREATE INDEX idx_medlog_time ON medication_logs(scheduledTime);');
  }
}
