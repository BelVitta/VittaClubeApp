package com.example.vita_clube

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import android.content.Intent
import com.mercadopago.sdk.android.domain.model.CountryCode
import com.mercadopago.sdk.android.initializer.MercadoPagoSDK
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private var pendingTokenizationResult: MethodChannel.Result? = null

    @Deprecated("Android callback retained because FlutterActivity is not a ComponentActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != CARD_TOKENIZATION_REQUEST) return
        val callback = pendingTokenizationResult ?: return
        pendingTokenizationResult = null
        if (resultCode == RESULT_OK) {
            val token = data?.getStringExtra(CardTokenizationActivity.EXTRA_CARD_TOKEN)
            if (!token.isNullOrBlank()) {
                callback.success(mapOf("status" to "success", "cardTokenId" to token))
            } else {
                callback.success(mapOf("status" to "error", "message" to "Token não retornado."))
            }
        } else {
            callback.success(mapOf("status" to "cancelled"))
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        initializeMercadoPago()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "vitta_clube_default",
                "Vita Clube",
                NotificationManager.IMPORTANCE_HIGH
            )
            channel.description = "Avisos do clube"
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAvailable" -> result.success(BuildConfig.MERCADOPAGO_PUBLIC_KEY.isNotBlank())
                "openCardTokenization" -> {
                    if (BuildConfig.MERCADOPAGO_PUBLIC_KEY.isBlank()) {
                        result.error("not_configured", "Public Key do Mercado Pago não configurada.", null)
                        return@setMethodCallHandler
                    }
                    if (pendingTokenizationResult != null) {
                        result.error("already_open", "A tokenização já está aberta.", null)
                        return@setMethodCallHandler
                    }
                    val name = call.argument<String>("payerName").orEmpty().trim()
                    val cpf = call.argument<String>("cpf").orEmpty().filter(Char::isDigit)
                    if (name.length < 3 || cpf.length != 11) {
                        result.error("invalid_payer", "Nome e CPF válidos são obrigatórios.", null)
                        return@setMethodCallHandler
                    }
                    pendingTokenizationResult = result
                    startActivityForResult(
                        Intent(this, CardTokenizationActivity::class.java).apply {
                            putExtra(CardTokenizationActivity.EXTRA_PAYER_NAME, name)
                            putExtra(CardTokenizationActivity.EXTRA_PAYER_CPF, cpf)
                        },
                        CARD_TOKENIZATION_REQUEST,
                    )
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun initializeMercadoPago() {
        if (BuildConfig.MERCADOPAGO_PUBLIC_KEY.isBlank() || MercadoPagoSDK.isInitialized) return
        MercadoPagoSDK.initialize(
            context = applicationContext,
            publicKey = BuildConfig.MERCADOPAGO_PUBLIC_KEY,
            countryCode = CountryCode.BRA,
        )
    }

    companion object {
        private const val CHANNEL_NAME = "br.com.vittaclube/mercadopago_card_tokenization"
        private const val CARD_TOKENIZATION_REQUEST = 4107
    }
}
