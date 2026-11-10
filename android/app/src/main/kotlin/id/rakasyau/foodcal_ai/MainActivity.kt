package id.rakasyau.foodcal_ai

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.time.LocalDate

class MainActivity : FlutterActivity() {
    private var kanalWidget: MethodChannel? = null
    private var aksiAwalWidget: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        tangkapIntentWidget(intent, kirimLangsung = false)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        tangkapIntentWidget(intent, kirimLangsung = true)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val kanal = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            KANAL_WIDGET,
        )
        kanalWidget = kanal
        kanal.setMethodCallHandler { panggilan, hasil ->
            when (panggilan.method) {
                "ambilAksiAwal" -> {
                    val aksi = aksiAwalWidget
                    aksiAwalWidget = null
                    hasil.success(aksi)
                }

                "perbaruiWidget" -> {
                    val kalori = panggilan.argument<Number>("kalori")?.toDouble() ?: 0.0
                    val target = panggilan.argument<Number>("target")?.toInt() ?: 2000
                    val tanggal = panggilan.argument<String>("tanggal")
                        ?: LocalDate.now().toString()
                    FoodCalWidgetUpdater.simpanCacheDanPerbarui(
                        applicationContext,
                        kalori,
                        target,
                        tanggal,
                    )
                    hasil.success(null)
                }

                "cekStatus" -> {
                    val manajer = AppWidgetManager.getInstance(applicationContext)
                    val id4x2 = manajer.getAppWidgetIds(
                        ComponentName(applicationContext, FoodCalWidget4x2Provider::class.java),
                    )
                    val id2x2 = manajer.getAppWidgetIds(
                        ComponentName(applicationContext, FoodCalWidget2x2Provider::class.java),
                    )
                    hasil.success(
                        mapOf(
                            "empatKaliDua" to id4x2.size,
                            "duaKaliDua" to id2x2.size,
                            "didukungPin" to manajer.isRequestPinAppWidgetSupported,
                        ),
                    )
                }

                "pasangWidget" -> {
                    val jenis = panggilan.argument<String>("jenis") ?: "empat_kali_dua"
                    FoodCalWidgetUpdater.perbaruiSemua(applicationContext)
                    val manajer = AppWidgetManager.getInstance(applicationContext)
                    if (!manajer.isRequestPinAppWidgetSupported) {
                        hasil.success("tidak_didukung")
                    } else {
                        val penyedia = if (jenis == "dua_kali_dua") {
                            ComponentName(applicationContext, FoodCalWidget2x2Provider::class.java)
                        } else {
                            ComponentName(applicationContext, FoodCalWidget4x2Provider::class.java)
                        }
                        val berhasil = try {
                            manajer.requestPinAppWidget(penyedia, null, null)
                        } catch (_: Throwable) {
                            false
                        }
                        hasil.success(if (berhasil) "diminta" else "tidak_didukung")
                    }
                }

                else -> hasil.notImplemented()
            }
        }
    }

    private fun tangkapIntentWidget(intent: Intent?, kirimLangsung: Boolean) {
        if (intent?.action != FoodCalWidgetUpdater.AKSI_BUKA_KAMERA) return
        intent.action = Intent.ACTION_MAIN
        if (kirimLangsung && kanalWidget != null) {
            kanalWidget?.invokeMethod("bukaKamera", null)
        } else {
            aksiAwalWidget = "buka_kamera"
        }
    }

    companion object {
        private const val KANAL_WIDGET = "id.rakasyau.foodcal_ai/widget"
    }
}
