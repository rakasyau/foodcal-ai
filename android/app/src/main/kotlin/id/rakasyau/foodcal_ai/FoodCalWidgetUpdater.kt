package id.rakasyau.foodcal_ai

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.widget.RemoteViews
import java.io.File
import java.time.LocalDate
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.roundToLong

data class DataRingkasWidget(
    val kalori: Double,
    val target: Int,
)

object FoodCalWidgetUpdater {
    const val AKSI_BUKA_KAMERA = "id.rakasyau.foodcal_ai.BUKA_KAMERA"
    private const val PREFS_NAMA = "foodcal_widget_cache"
    private const val KUNCI_KALORI = "kalori"
    private const val KUNCI_TARGET = "target"
    private const val KUNCI_TANGGAL = "tanggal"

    fun simpanCacheDanPerbarui(
        context: Context,
        kalori: Double,
        target: Int,
        tanggal: String,
    ) {
        val targetAman = if (target > 0) target else 2000
        context.getSharedPreferences(PREFS_NAMA, Context.MODE_PRIVATE)
            .edit()
            .putFloat(KUNCI_KALORI, kalori.toFloat())
            .putInt(KUNCI_TARGET, targetAman)
            .putString(KUNCI_TANGGAL, tanggal)
            .apply()
        renderKeSemuaWidget(context, DataRingkasWidget(kalori, targetAman))
    }

    fun perbaruiSemua(context: Context) {
        val data = bacaDataTerkini(context)
        renderKeSemuaWidget(context, data)
    }

    private fun bacaDataTerkini(context: Context): DataRingkasWidget {
        val hariIni = LocalDate.now().toString()
        val dariDb = bacaDariSqlite(context, hariIni)
        if (dariDb != null) {
            context.getSharedPreferences(PREFS_NAMA, Context.MODE_PRIVATE)
                .edit()
                .putFloat(KUNCI_KALORI, dariDb.kalori.toFloat())
                .putInt(KUNCI_TARGET, dariDb.target)
                .putString(KUNCI_TANGGAL, hariIni)
                .apply()
            return dariDb
        }

        val prefs = context.getSharedPreferences(PREFS_NAMA, Context.MODE_PRIVATE)
        val targetTersimpan = prefs.getInt(KUNCI_TARGET, 2000).let {
            if (it > 0) it else 2000
        }
        val tanggalTersimpan = prefs.getString(KUNCI_TANGGAL, null)
        val kaloriTersimpan = if (tanggalTersimpan == hariIni) {
            prefs.getFloat(KUNCI_KALORI, 0f).toDouble()
        } else {
            0.0
        }
        return DataRingkasWidget(kalori = kaloriTersimpan, target = targetTersimpan)
    }

    private fun bacaDariSqlite(context: Context, hariIni: String): DataRingkasWidget? {
        val kandidatBerkas = listOf(
            File(context.applicationInfo.dataDir, "app_flutter/foodcal.db"),
            context.getDatabasePath("foodcal.db"),
            File(context.filesDir, "foodcal.db"),
        )
        val berkasDb = kandidatBerkas.firstOrNull { it.exists() && it.length() > 4096L }
            ?: return null

        return try {
            SQLiteDatabase.openDatabase(
                berkasDb.absolutePath,
                null,
                SQLiteDatabase.OPEN_READWRITE or SQLiteDatabase.ENABLE_WRITE_AHEAD_LOGGING,
            ).use { db ->
                var target = 2000
                db.rawQuery(
                    "SELECT nilai FROM pengaturan WHERE kunci = ? LIMIT 1",
                    arrayOf("target_kalori"),
                ).use { kursor ->
                    if (kursor.moveToFirst()) {
                        val nilai = kursor.getString(0)?.toIntOrNull()
                        if (nilai != null && nilai > 0) {
                            target = nilai
                        }
                    }
                }

                var kalori = 0.0
                db.rawQuery(
                    "SELECT COALESCE(SUM(kalori), 0) FROM log_makan WHERE tanggal = ?",
                    arrayOf(hariIni),
                ).use { kursor ->
                    if (kursor.moveToFirst()) {
                        kalori = kursor.getDouble(0)
                    }
                }

                DataRingkasWidget(kalori = kalori, target = target)
            }
        } catch (_: Throwable) {
            null
        }
    }

    private fun renderKeSemuaWidget(context: Context, data: DataRingkasWidget) {
        val manajer = AppWidgetManager.getInstance(context)
        val id4x2 = manajer.getAppWidgetIds(
            ComponentName(context, FoodCalWidget4x2Provider::class.java),
        )
        val id2x2 = manajer.getAppWidgetIds(
            ComponentName(context, FoodCalWidget2x2Provider::class.java),
        )
        if (id4x2.isEmpty() && id2x2.isEmpty()) return

        val kaloriBulat = data.kalori.roundToLong().coerceAtLeast(0L)
        val targetAman = if (data.target > 0) data.target else 2000
        val persen = ((data.kalori / targetAman.toDouble()) * 100.0)
            .roundToInt()
            .coerceAtLeast(0)

        val teksKalori = formatRibuan(kaloriBulat)
        val teksTarget = "dari ${formatRibuan(targetAman.toLong())} kkal"
        val teksPersen = "$persen% target"

        val pendingBeranda = buatPendingIntent(context, bukaKamera = false)
        val pendingKamera = buatPendingIntent(context, bukaKamera = true)

        if (id4x2.isNotEmpty()) {
            val bitmapCincin = buatBitmapCincin(context, persen)
            for (widgetId in id4x2) {
                val tampilan = RemoteViews(context.packageName, R.layout.widget_foodcal_4x2)
                tampilan.setTextViewText(R.id.tv_kalori_4x2, teksKalori)
                tampilan.setTextViewText(R.id.tv_target_4x2, teksTarget)
                tampilan.setImageViewBitmap(R.id.img_cincin_4x2, bitmapCincin)
                tampilan.setOnClickPendingIntent(R.id.akar_widget_4x2, pendingBeranda)
                tampilan.setOnClickPendingIntent(R.id.tombol_kamera_4x2, pendingKamera)
                manajer.updateAppWidget(widgetId, tampilan)
            }
        }

        if (id2x2.isNotEmpty()) {
            for (widgetId in id2x2) {
                val tampilan = RemoteViews(context.packageName, R.layout.widget_foodcal_2x2)
                tampilan.setTextViewText(R.id.tv_kalori_2x2, teksKalori)
                tampilan.setTextViewText(R.id.tv_persen_2x2, teksPersen)
                tampilan.setOnClickPendingIntent(R.id.akar_widget_2x2, pendingBeranda)
                manajer.updateAppWidget(widgetId, tampilan)
            }
        }
    }

    private fun buatPendingIntent(context: Context, bukaKamera: Boolean): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = if (bukaKamera) AKSI_BUKA_KAMERA else Intent.ACTION_MAIN
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val kode = if (bukaKamera) 1002 else 1001
        return PendingIntent.getActivity(
            context,
            kode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun buatBitmapCincin(context: Context, persen: Int): Bitmap {
        val kepadatan = context.resources.displayMetrics.density.coerceAtLeast(1f)
        val sisi = (60f * kepadatan).roundToInt().coerceAtLeast(60)
        val tebal = 5.5f * kepadatan
        val bitmap = Bitmap.createBitmap(sisi, sisi, Bitmap.Config.ARGB_8888)
        val kanvas = Canvas(bitmap)

        val tengah = sisi / 2f
        val radius = (min(sisi, sisi) - tebal) / 2f - (1f * kepadatan)
        val warnaAksen = Color.parseColor("#D6382F")
        val warnaJalur = Color.parseColor("#D9D9D9")
        val warnaTeks = Color.parseColor("#111111")

        val kuasDasar = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = tebal
            strokeCap = Paint.Cap.ROUND
            color = if (persen >= 100) warnaAksen else warnaJalur
        }
        kanvas.drawCircle(tengah, tengah, radius, kuasDasar)

        if (persen in 1..99) {
            val kuasBusur = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = tebal
                strokeCap = Paint.Cap.ROUND
                color = warnaAksen
            }
            val kotak = RectF(
                tengah - radius,
                tengah - radius,
                tengah + radius,
                tengah + radius,
            )
            val sapuan = 360f * (persen / 100f)
            kanvas.drawArc(kotak, -90f, sapuan, false, kuasBusur)
        }

        val label = "$persen%"
        val kuasTeks = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = warnaTeks
            textAlign = Paint.Align.CENTER
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            textSize = (if (label.length >= 4) 11f else 12.5f) * kepadatan
        }
        val metrik = kuasTeks.fontMetrics
        val yTeks = tengah - (metrik.ascent + metrik.descent) / 2f
        kanvas.drawText(label, tengah, yTeks, kuasTeks)

        return bitmap
    }

    private fun formatRibuan(nilai: Long): String {
        val digit = nilai.toString()
        if (digit.length <= 3) return digit
        val hasil = StringBuilder()
        var hitung = 0
        for (i in digit.length - 1 downTo 0) {
            hasil.append(digit[i])
            hitung++
            if (hitung == 3 && i > 0) {
                hasil.append('.')
                hitung = 0
            }
        }
        return hasil.reverse().toString()
    }
}

