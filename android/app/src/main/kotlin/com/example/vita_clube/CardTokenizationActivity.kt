package com.example.vita_clube

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.activity.ComponentActivity
import androidx.lifecycle.lifecycleScope
import com.mercadopago.sdk.android.coremethods.domain.interactor.coreMethods
import com.mercadopago.sdk.android.coremethods.domain.model.BuyerIdentification
import com.mercadopago.sdk.android.coremethods.domain.model.ResultError
import com.mercadopago.sdk.android.coremethods.domain.utils.Result
import com.mercadopago.sdk.android.coremethods.ui.components.textfield.cardnumber.xml.CardNumberTextField
import com.mercadopago.sdk.android.coremethods.ui.components.textfield.expirationdate.xml.ExpirationDateTextField
import com.mercadopago.sdk.android.coremethods.ui.components.textfield.securitycode.xml.SecurityCodeTextField
import com.mercadopago.sdk.android.initializer.MercadoPagoSDK
import kotlinx.coroutines.launch

/**
 * Superfície PCI nativa. Os três campos sensíveis pertencem ao SDK oficial;
 * somente o token final sai desta Activity.
 */
class CardTokenizationActivity : ComponentActivity() {
    private lateinit var cardNumberField: CardNumberTextField
    private lateinit var expirationField: ExpirationDateTextField
    private lateinit var securityCodeField: SecurityCodeTextField
    private lateinit var submitButton: Button
    private lateinit var errorLabel: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        setResult(Activity.RESULT_CANCELED)
        setContentView(buildContent())
    }

    private fun buildContent(): ScrollView {
        val density = resources.displayMetrics.density
        fun dp(value: Int) = (value * density).toInt()
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(28), dp(24), dp(28))
        }
        content.addView(TextView(this).apply {
            text = "Cartão de crédito"
            textSize = 24f
            setTextColor(Color.rgb(1, 34, 91))
        })
        content.addView(TextView(this).apply {
            text = "Seus dados são protegidos e tokenizados pelo Mercado Pago."
            textSize = 14f
            setTextColor(Color.DKGRAY)
            setPadding(0, dp(8), 0, dp(24))
        })
        content.addLabel("Número do cartão", dp(8))
        cardNumberField = CardNumberTextField(this)
        content.addView(cardNumberField, fieldParams(dp(58)))
        content.addLabel("Validade", dp(18))
        expirationField = ExpirationDateTextField(this)
        content.addView(expirationField, fieldParams(dp(58)))
        content.addLabel("Código de segurança", dp(18))
        securityCodeField = SecurityCodeTextField(this)
        content.addView(securityCodeField, fieldParams(dp(58)))
        errorLabel = TextView(this).apply {
            setTextColor(Color.rgb(180, 30, 30))
            setPadding(0, dp(14), 0, dp(8))
        }
        content.addView(errorLabel)
        submitButton = Button(this).apply {
            text = "Continuar com segurança"
            isAllCaps = false
            setOnClickListener { tokenize() }
        }
        content.addView(submitButton, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            dp(52),
        ).apply { topMargin = dp(12) })
        content.addView(Button(this).apply {
            text = "Cancelar"
            isAllCaps = false
            setOnClickListener { finish() }
        }, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            dp(48),
        ).apply { topMargin = dp(8) })
        return ScrollView(this).apply { addView(content) }
    }

    private fun LinearLayout.addLabel(label: String, topPadding: Int) {
        addView(TextView(this@CardTokenizationActivity).apply {
            text = label
            textSize = 14f
            setTextColor(Color.rgb(1, 34, 91))
            setPadding(0, topPadding, 0, 6)
        })
    }

    private fun fieldParams(height: Int) = LinearLayout.LayoutParams(
        LinearLayout.LayoutParams.MATCH_PARENT,
        height,
    )

    private fun tokenize() {
        val payerName = intent.getStringExtra(EXTRA_PAYER_NAME).orEmpty()
        val cpf = intent.getStringExtra(EXTRA_PAYER_CPF).orEmpty()
        submitButton.isEnabled = false
        errorLabel.text = ""
        lifecycleScope.launch {
            val result = try {
                MercadoPagoSDK.getInstance().coreMethods.generateCardToken(
                    cardNumberState = cardNumberField.state,
                    expirationDateState = expirationField.state,
                    securityCodeState = securityCodeField.state,
                    buyerIdentification = BuyerIdentification(
                        name = payerName,
                        number = cpf,
                        type = "CPF",
                    ),
                )
            } catch (_: UninitializedPropertyAccessException) {
                errorLabel.text = "Aguarde os campos carregarem e tente novamente."
                submitButton.isEnabled = true
                return@launch
            }
            when (result) {
                is Result.Success -> {
                    // Deliberadamente não retornamos bandeira, BIN, final, validade ou CVV.
                    setResult(Activity.RESULT_OK, Intent().apply {
                        putExtra(EXTRA_CARD_TOKEN, result.data.token)
                    })
                    finish()
                }
                is Result.Error -> {
                    errorLabel.text = when (val error = result.error) {
                        is ResultError.Request -> "Não foi possível tokenizar o cartão. Tente novamente."
                        is ResultError.Validation -> error.message
                    }
                    submitButton.isEnabled = true
                }
            }
        }
    }

    companion object {
        const val EXTRA_PAYER_NAME = "payer_name"
        const val EXTRA_PAYER_CPF = "payer_cpf"
        const val EXTRA_CARD_TOKEN = "card_token"
    }
}
