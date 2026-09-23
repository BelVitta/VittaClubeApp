import Flutter
import CoreMethods
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let cardChannelName = "br.com.vittaclube/mercadopago_card_tokenization"
  private var pendingCardResult: FlutterResult?
  private var mercadoPagoConfiguredPublicKey: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    application.registerForRemoteNotifications()
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    // Flutter creates the root view controller while running `super`; register
    // the channel only afterwards so it is always attached to that controller.
    registerMercadoPagoChannel()
    return launched
  }

  private func registerMercadoPagoChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }

    let channel = FlutterMethodChannel(
      name: cardChannelName,
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "unavailable", message: "App indisponível.", details: nil))
        return
      }
      DispatchQueue.main.async {
        self.handleMercadoPago(call: call, result: result)
      }
    }
  }

  private func handleMercadoPago(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any]
    let publicKey = (arguments?["publicKey"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

    switch call.method {
    case "isAvailable":
      result(!publicKey.isEmpty)

    case "openCardTokenization":
      guard !publicKey.isEmpty else {
        result(FlutterError(
          code: "not_configured",
          message: "Public Key do Mercado Pago não configurada.",
          details: nil
        ))
        return
      }
      guard pendingCardResult == nil else {
        result(FlutterError(
          code: "already_open",
          message: "A tokenização já está aberta.",
          details: nil
        ))
        return
      }
      guard let payerName = arguments?["payerName"] as? String,
            let cpf = arguments?["cpf"] as? String,
            payerName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3,
            cpf.filter(\.isNumber).count == 11 else {
        result(FlutterError(
          code: "invalid_payer",
          message: "Nome e CPF válidos são obrigatórios.",
          details: nil
        ))
        return
      }

      initializeMercadoPago(publicKey: publicKey)
      guard let root = window?.rootViewController else {
        result(FlutterError(code: "unavailable", message: "Janela indisponível.", details: nil))
        return
      }
      let presenter = topViewController(from: root)
      pendingCardResult = result
      let cardViewController = MercadoPagoCardTokenizationViewController(
        payerName: payerName,
        cpf: cpf.filter(\.isNumber)
      ) { [weak self] response in
        self?.pendingCardResult?(response)
        self?.pendingCardResult = nil
      }
      cardViewController.modalPresentationStyle = .pageSheet
      presenter.present(cardViewController, animated: true)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func initializeMercadoPago(publicKey: String) {
    let configuration = MercadoPagoSDK.Configuration(publicKey: publicKey, country: .BRA)
    if mercadoPagoConfiguredPublicKey != nil {
      MercadoPagoSDK.shared.setNewConfiguration(configuration)
    } else {
      MercadoPagoSDK.shared.initialize(configuration)
    }
    mercadoPagoConfiguredPublicKey = publicKey
  }

  private func topViewController(from root: UIViewController) -> UIViewController {
    if let presented = root.presentedViewController {
      return topViewController(from: presented)
    }
    if let navigation = root as? UINavigationController, let visible = navigation.visibleViewController {
      return topViewController(from: visible)
    }
    if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
      return topViewController(from: selected)
    }
    return root
  }
}

/// Native PCI surface for iOS. Card number, expiration date and CVV remain
/// inside Mercado Pago's secure fields; only the generated token is returned.
final class MercadoPagoCardTokenizationViewController: UIViewController {
  private let payerName: String
  private let cpf: String
  private let completion: ([String: Any]) -> Void
  private let coreMethods = CoreMethods()
  private var didFinish = false

  private let cardNumberField = CardNumberTextField()
  private let expirationDateField = ExpirationDateTextfield()
  private let securityCodeField = SecurityCodeTextField()
  private let errorLabel = UILabel()
  private let submitButton = UIButton(type: .system)

  init(payerName: String, cpf: String, completion: @escaping ([String: Any]) -> Void) {
    self.payerName = payerName
    self.cpf = cpf
    self.completion = completion
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    view.isAccessibilityElement = false
    buildForm()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    if !didFinish {
      finish(["status": "cancelled"])
    }
  }

  private func buildForm() {
    let scrollView = UIScrollView()
    let content = UIStackView()
    content.axis = .vertical
    content.spacing = 12
    content.alignment = .fill

    let title = UILabel()
    title.text = "Cartão de crédito"
    title.font = .preferredFont(forTextStyle: .title2)
    title.textColor = .label

    let subtitle = UILabel()
    subtitle.text = "Seus dados são protegidos e tokenizados pelo Mercado Pago."
    subtitle.font = .preferredFont(forTextStyle: .subheadline)
    subtitle.textColor = .secondaryLabel
    subtitle.numberOfLines = 0

    cardNumberField.setPlaceholder("Número do cartão")
    expirationDateField.setPlaceholder("Validade (MM/AA)")
    securityCodeField.setPlaceholder("Código de segurança")

    errorLabel.textColor = .systemRed
    errorLabel.numberOfLines = 0
    errorLabel.isHidden = true

    submitButton.setTitle("Continuar com segurança", for: .normal)
    submitButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
    submitButton.addTarget(self, action: #selector(tokenize), for: .touchUpInside)

    let cancelButton = UIButton(type: .system)
    cancelButton.setTitle("Cancelar", for: .normal)
    cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)

    [title, subtitle, cardNumberField, expirationDateField, securityCodeField,
     errorLabel, submitButton, cancelButton].forEach(content.addArrangedSubview)

    cardNumberField.heightAnchor.constraint(equalToConstant: 52).isActive = true
    expirationDateField.heightAnchor.constraint(equalToConstant: 52).isActive = true
    securityCodeField.heightAnchor.constraint(equalToConstant: 52).isActive = true
    submitButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
    cancelButton.heightAnchor.constraint(equalToConstant: 44).isActive = true

    scrollView.translatesAutoresizingMaskIntoConstraints = false
    content.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(scrollView)
    scrollView.addSubview(content)
    NSLayoutConstraint.activate([
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      content.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 24),
      content.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -24),
      content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
      content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
      content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48),
    ])
  }

  @objc private func cancel() {
    finish(["status": "cancelled"])
  }

  @objc private func tokenize() {
    guard cardNumberField.isValid,
          expirationDateField.isValid,
          securityCodeField.isValid else {
      showError("Confira os dados do cartão e tente novamente.")
      return
    }

    submitButton.isEnabled = false
    errorLabel.isHidden = true

    Task { [weak self] in
      guard let self else { return }
      do {
        let identificationTypes = try await coreMethods.identificationTypes()
        guard let cpfType = identificationTypes.first(where: {
          [$0.id, $0.name, $0.type].contains(where: { $0.uppercased() == "CPF" })
        }) else {
          throw NSError(domain: "MercadoPago", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Tipo de documento CPF não disponível."
          ])
        }
        let cardToken = try await coreMethods.createToken(
          cardNumber: cardNumberField,
          expirationDate: expirationDateField,
          securityCode: securityCodeField,
          documentType: cpfType,
          documentNumber: cpf,
          cardHolderName: payerName
        )
        await MainActor.run {
          self.finish(["status": "success", "cardTokenId": cardToken.token])
        }
      } catch {
        await MainActor.run {
          self.showError("Não foi possível tokenizar o cartão. Tente novamente.")
          self.submitButton.isEnabled = true
        }
      }
    }
  }

  private func showError(_ message: String) {
    errorLabel.text = message
    errorLabel.isHidden = false
  }

  private func finish(_ response: [String: Any]) {
    guard !didFinish else { return }
    didFinish = true
    dismiss(animated: true) { [completion] in
      completion(response)
    }
  }
}
