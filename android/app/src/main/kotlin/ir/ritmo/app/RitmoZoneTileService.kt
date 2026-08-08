package ir.ritmo.app

import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.util.Log
import androidx.annotation.RequiresApi

@RequiresApi(Build.VERSION_CODES.N)
class RitmoZoneTileService : TileService() {

    override fun onClick() {
        super.onClick()

        // 1. Read current override id from DB
        val activeZoneId = getSettingFromDb("realm_override_id", "")
        val zoneIds = ArrayList<String>()

        try {
            val dbPath = getDatabasePath(DatabaseConfig.DATABASE_NAME)
            if (dbPath.exists()) {
                val db = SQLiteDatabase.openDatabase(dbPath.absolutePath, null, SQLiteDatabase.OPEN_READONLY)
                val cursor = db.query("zones", arrayOf("id"), null, null, null, null, null)
                while (cursor.moveToNext()) {
                    zoneIds.add(cursor.getString(0))
                }
                cursor.close()
                db.close()
            }
        } catch (e: Exception) {
            Log.e("RitmoZoneTile", "Error reading zones: " + e.message)
        }

        // Add default_zone/empty to the end of options to clear override
        zoneIds.add("default_zone")

        var nextIndex = 0
        val currentIndex = zoneIds.indexOf(activeZoneId)
        if (currentIndex != -1) {
            nextIndex = (currentIndex + 1) % zoneIds.size
        }
        val nextZoneId = zoneIds[nextIndex]

        // 2. Send broadcast to NotificationActionReceiver to apply changes and update persistent notification
        val intent = Intent(this, NotificationActionReceiver::class.java).apply {
            action = "CHANGE_ZONE"
            putExtra("actionType", "CHANGE_ZONE")
            putExtra("zoneId", nextZoneId)
        }
        sendBroadcast(intent)

        // 3. Update the Tile UI locally
        updateTileState(nextZoneId)
    }

    override fun onStartListening() {
        super.onStartListening()
        val activeZoneId = getSettingFromDb("realm_override_id", "")
        updateTileState(activeZoneId)
    }

    private fun updateTileState(zoneId: String) {
        val tile = qsTile ?: return

        var zoneName = "آزاد"
        var isActive = false

        if (zoneId.isNotEmpty() && zoneId != "default_zone") {
            isActive = true
            try {
                val dbPath = getDatabasePath(DatabaseConfig.DATABASE_NAME)
                if (dbPath.exists()) {
                    val db = SQLiteDatabase.openDatabase(dbPath.absolutePath, null, SQLiteDatabase.OPEN_READONLY)
                    val cursor = db.query("zones", arrayOf("name"), "id = ?", arrayOf(zoneId), null, null, null)
                    if (cursor.moveToFirst()) {
                        zoneName = cursor.getString(0) ?: "زون"
                    }
                    cursor.close()
                    db.close()
                }
            } catch (e: Exception) {
                zoneName = "زون فعال"
            }
        } else {
            zoneName = "آزاد"
            isActive = false
        }

        tile.label = "ریتمو: " + zoneName
        tile.state = if (isActive) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        tile.updateTile()
    }

    private fun getSettingFromDb(key: String, defaultValue: String): String {
        var value = defaultValue
        try {
            val dbPath = getDatabasePath(DatabaseConfig.DATABASE_NAME)
            if (dbPath.exists()) {
                val db = SQLiteDatabase.openDatabase(dbPath.absolutePath, null, SQLiteDatabase.OPEN_READONLY)
                val cursor = db.query("app_settings", arrayOf("value"), "key = ?", arrayOf(key), null, null, null)
                if (cursor.moveToFirst()) {
                    value = cursor.getString(0) ?: defaultValue
                }
                cursor.close()
                db.close()
            }
        } catch (e: Exception) {
            Log.e("RitmoZoneTile", "Error reading DB setting " + key + ": " + e.message)
        }
        return value
    }
}