# Keep Flutter core classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep native application package and all its classes (services, receivers, widgets)
-keep class ir.ritmo.app.** { *; }

# Keep sqflite library
-keep class com.tekartik.sqflite.** { *; }

# Keep workmanager plugin
-keep class com.befovy.aar.workmanager.** { *; }

# Keep local notifications plugin
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep background service & workmanager dependencies
-keep class androidx.core.app.JobIntentService { *; }
-keep class androidx.work.** { *; }
-keep class com.google.android.gms.ads.** { *; }
