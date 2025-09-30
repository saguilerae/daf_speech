#include "DAFAudioProcessorEditor.h"
#include "DAFAudioProcessor.h"
#include "getEducationalText.h"
#include "Monetization/PurchaseManagerFactory.h"
#include "UI/PaywallComponent.h"

// Constantes de estilo
static const juce::Colour kBackgroundColour = juce::Colour(0xfff9f6fc); // Fondo claro
static const juce::Colour kPrimaryColour = juce::Colour(0xff7e57c2);    // Púrpura
static const juce::Colour kTextColour = juce::Colours::black;           // Texto negro
static const juce::Colour kMenuButtonBg = juce::Colour(0xffeeeeee);     // Fondo botones menú
static const juce::String hamburgerLabel = juce::String::fromUTF8("☰");

// Constructor
DAFAudioProcessorEditor::DAFAudioProcessorEditor(DAFAudioProcessor& p)
    : AudioProcessorEditor(&p), processor(p)
{
    // Establecer Roboto Regular y Bold desde BinaryData como fuente por defecto
    juce::Typeface::Ptr robotoRegular = juce::Typeface::createSystemTypefaceFor(
        BinaryData::RobotoRegular_ttf, BinaryData::RobotoRegular_ttfSize);
    juce::Typeface::Ptr robotoBold = juce::Typeface::createSystemTypefaceFor(
        BinaryData::RobotoBold_ttf, BinaryData::RobotoBold_ttfSize);

    // Crear un LookAndFeel que use Roboto
    static juce::LookAndFeel_V4 robotoLookAndFeel;
    robotoLookAndFeel.setDefaultSansSerifTypeface(robotoRegular);

    // Establecerlo como LookAndFeel global
    juce::LookAndFeel::setDefaultLookAndFeel(&robotoLookAndFeel);

    setSize(420, 640);
    
    addAndMakeVisible(menuBackgroundPanel);
    menuBackgroundPanel.setVisible(false);

    // Botón hamburguesa
    static FlatLookAndFeel flatLook;
    hamburgerButton.setLookAndFeel(&flatLook);
    hamburgerButton.setColour(juce::TextButton::textColourOffId, kTextColour);
    hamburgerButton.setButtonText(hamburgerLabel);
    //hamburgerButton.setColour(juce::TextButton::buttonColourId, kBackgroundColour);
    //hamburgerButton.setColour(juce::TextButton::textColourOffId, kTextColour);
    hamburgerButton.onClick = [this] {
        menuVisible = !menuVisible;
        contentText.setVisible(false);
        resized();
        repaint();
    };
    addAndMakeVisible(hamburgerButton);

    // Título
    titleLabel.setText("FluTalk", juce::dontSendNotification);
    titleLabel.setJustificationType(juce::Justification::centred);
    titleLabel.setFont(juce::Font(juce::FontOptions(20.0f, juce::Font::bold)));
    titleLabel.setColour(juce::Label::textColourId, kTextColour);
    addAndMakeVisible(titleLabel);

    // delay Labels y sliders
    delayLabel.setText("Retardo", juce::dontSendNotification);
    delayLabel.setFont(juce::Font(juce::FontOptions(18.0f, juce::Font::bold)));
    delayLabel.setColour(juce::Label::textColourId, kTextColour);
    addAndMakeVisible(delayLabel);

    delaySlider.setRange(0.0, 200.0, 1.0);
    delaySlider.setSliderStyle(juce::Slider::LinearHorizontal);
    delaySlider.setTextBoxStyle(juce::Slider::NoTextBox, true, 0, 0);
    delaySlider.setColour(juce::Slider::thumbColourId, kPrimaryColour);
    delaySlider.setColour(juce::Slider::trackColourId, kPrimaryColour);
    delaySlider.setColour(juce::Slider::backgroundColourId, juce::Colours::lightgrey);
    delaySlider.setValue(processor.apvts.getRawParameterValue("delayTime")->load(), juce::dontSendNotification);
    delaySlider.addListener(this);
    addAndMakeVisible(delaySlider);

    delayValueLabel.setText(juce::String(delaySlider.getValue(), 0) + " ms", juce::dontSendNotification);
    delayValueLabel.setFont(juce::Font(juce::FontOptions(16.0f)));
    delayValueLabel.setColour(juce::Label::textColourId, kTextColour);
    addAndMakeVisible(delayValueLabel);

    // pitch Labels y sliders
    pitchLabel.setText("Tono", juce::dontSendNotification);
    pitchLabel.setFont(juce::Font(juce::FontOptions(18.0f, juce::Font::bold)));
    pitchLabel.setColour(juce::Label::textColourId, kTextColour);
    addAndMakeVisible(pitchLabel);

    pitchSlider.setRange(-4.0, 4.0, 0.5);
    pitchSlider.setSliderStyle(juce::Slider::LinearHorizontal);
    pitchSlider.setTextBoxStyle(juce::Slider::NoTextBox, true, 0, 0);
    pitchSlider.setColour(juce::Slider::thumbColourId, kPrimaryColour);
    pitchSlider.setColour(juce::Slider::trackColourId, kPrimaryColour);
    pitchSlider.setColour(juce::Slider::backgroundColourId, juce::Colours::lightgrey);
    pitchSlider.setValue(processor.apvts.getRawParameterValue("pitch")->load(), juce::dontSendNotification);
    pitchSlider.addListener(this);
    addAndMakeVisible(pitchSlider);

    pitchValueLabel.setText(juce::String(pitchSlider.getValue(), 0) + " st", juce::dontSendNotification);
    pitchValueLabel.setFont(juce::Font(juce::FontOptions(16.0f)));
    pitchValueLabel.setColour(juce::Label::textColourId, kTextColour);
    addAndMakeVisible(pitchValueLabel);
    
    // noiseGate Labels y sliders
    noiseGateLabel.setText(juce::String::fromUTF8("Reducción de Ruido"), juce::dontSendNotification);
    noiseGateLabel.setFont(juce::Font(juce::FontOptions(18.0f, juce::Font::bold)));
    noiseGateLabel.setColour(juce::Label::textColourId, kTextColour);
    addAndMakeVisible(noiseGateLabel);

    noiseGateSlider.setRange(0.0, 0.1, 0.001);
    noiseGateSlider.setSliderStyle(juce::Slider::LinearHorizontal);
    noiseGateSlider.setTextBoxStyle(juce::Slider::NoTextBox, true, 0, 0);
    noiseGateSlider.setColour(juce::Slider::thumbColourId, kPrimaryColour);
    noiseGateSlider.setColour(juce::Slider::trackColourId, kPrimaryColour);
    noiseGateSlider.setColour(juce::Slider::backgroundColourId, juce::Colours::lightgrey);
    noiseGateSlider.setValue(processor.apvts.getRawParameterValue("umbralNoiseGate")->load(), juce::dontSendNotification);
    noiseGateSlider.addListener(this);
    addAndMakeVisible(noiseGateSlider);

    // Value Label Noise Gate (muestra el valor numérico del slider)
    noiseGateValueLabel.setText(juce::String(noiseGateSlider.getValue() * 1000.0f, 1) + " %", juce::dontSendNotification);
    noiseGateValueLabel.setFont(juce::Font(juce::FontOptions(16.0f)));
    noiseGateValueLabel.setColour(juce::Label::textColourId, kTextColour);
    addAndMakeVisible(noiseGateValueLabel);
    
    // Adjunta el slider al parámetro del processor
    noiseGateSliderAttachment = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(
        processor.apvts, "umbralNoiseGate", noiseGateSlider);
    // Fin de Noise Gate

    startStopButton.setButtonText("Iniciar");
    startStopButton.setColour(juce::TextButton::buttonColourId, kPrimaryColour);
    startStopButton.setColour(juce::TextButton::textColourOffId, juce::Colours::white);
    startStopButton.onClick = [this] { toggleAudioProcessing(); };
    addAndMakeVisible(startStopButton);

    micStatusLabel.setText(juce::String::fromUTF8("Micrófono detenido"), juce::dontSendNotification);
    micStatusLabel.setColour(juce::Label::textColourId, juce::Colours::red);
    micStatusLabel.setFont(juce::Font(juce::FontOptions(18.0f, juce::Font::plain)));
    addAndMakeVisible(micStatusLabel);
    
    // 🔄 Sincronizar UI con el estado actual del motor de audio
    if (processor.isProcessing())
    {
        startStopButton.setButtonText("Detener");
        micStatusLabel.setText(juce::String::fromUTF8("Micrófono cobectado"), juce::dontSendNotification);
        micStatusLabel.setColour(juce::Label::textColourId, juce::Colours::green);
    }
    else
    {
        startStopButton.setButtonText("Iniciar");
        micStatusLabel.setText(juce::String::fromUTF8("Micrófono detenido"), juce::dontSendNotification);
        micStatusLabel.setColour(juce::Label::textColourId, juce::Colours::red);
    }

    setSize(420, 640);
    // Fin sincronización de UI con el estado del motoro dw audio

    contentText.setMultiLine(true);
    contentText.setReadOnly(true);
    contentText.setFont(juce::Font(juce::FontOptions(16.0f)));
    contentText.setColour(juce::TextEditor::backgroundColourId, kBackgroundColour);
    contentText.setColour(juce::TextEditor::textColourId, kTextColour);
    contentText.setColour(juce::TextEditor::outlineColourId, juce::Colours::transparentBlack);

    volumeLabel.setText(juce::String::fromUTF8("Micrófono"), juce::dontSendNotification);
    volumeLabel.setFont(juce::Font(juce::FontOptions(18.0f, juce::Font::bold)));
    volumeLabel.setColour(juce::Label::textColourId, kTextColour);
    addAndMakeVisible(volumeLabel);

    volumeSlider.setRange(-24.0, 24.0, 0.1);
    volumeSlider.setSliderStyle(juce::Slider::LinearHorizontal);
    volumeSlider.setTextBoxStyle(juce::Slider::NoTextBox, true, 0, 0);
    volumeSlider.setColour(juce::Slider::thumbColourId, kPrimaryColour);
    volumeSlider.setColour(juce::Slider::trackColourId, kPrimaryColour);
    volumeSlider.setColour(juce::Slider::backgroundColourId, juce::Colours::lightgrey);
    volumeSlider.setValue(processor.apvts.getRawParameterValue("inputGain")->load(), juce::dontSendNotification);
    volumeValueLabel.setText(juce::String(volumeSlider.getValue(), 1) + " dB", juce::dontSendNotification);
    volumeSlider.addListener(this);
    addAndMakeVisible(volumeSlider);
    
    volumeValueLabel.setFont(juce::Font(juce::FontOptions(16.0f)));
    volumeValueLabel.setColour(juce::Label::textColourId, kTextColour);
    addAndMakeVisible(volumeValueLabel);

    // Educational Title Label
    educationalTitleLabel.setFont(juce::Font(juce::FontOptions(18.0f, juce::Font::bold)));
    educationalTitleLabel.setJustificationType(juce::Justification::centred);
    educationalTitleLabel.setColour(juce::Label::textColourId, kTextColour);
    educationalTitleLabel.setColour(juce::Label::backgroundColourId, kBackgroundColour);
    addAndMakeVisible(educationalTitleLabel);
    educationalTitleLabel.setVisible(false);
    
    // Educational Content Label
    educationalContentLabel.setFont(juce::Font(juce::FontOptions(16.0f)));
    educationalContentLabel.setJustificationType(juce::Justification::topLeft);
    educationalContentLabel.setColour(juce::Label::textColourId, kTextColour);
    educationalContentLabel.setColour(juce::Label::backgroundColourId, kBackgroundColour);
    addAndMakeVisible(educationalContentLabel);
    educationalContentLabel.setVisible(false);

    contentText.setVisible(false);
    addAndMakeVisible(contentText);
    
    juce::StringArray options = {
        juce::String::fromUTF8("Cómo usar la app con audífonos Bluetooth"),
        juce::String::fromUTF8("Ajustar el retardo de audio"),
        juce::String::fromUTF8("Cambiar el tono de la voz"),
        juce::String::fromUTF8("Reducción de Ruido"),
        juce::String::fromUTF8("Controlar el volumen del micrófono"),
        juce::String::fromUTF8("Preguntas frecuentes"),
        juce::String::fromUTF8("Contacto y soporte técnico"),
        juce::String::fromUTF8("Política de Privacidad")
    };

    for (int i = 0; i < options.size(); ++i)
    {
        // Crear un nuevo Label
        auto* labelBtn = new juce::Label();
        labelBtn->setText(options[i], juce::dontSendNotification);
        labelBtn->setJustificationType(juce::Justification::left); // Alinear texto a la izquierda
        labelBtn->setColour(juce::Label::backgroundColourId, kBackgroundColour);  // Fondo igual al de la app
        labelBtn->setColour(juce::Label::textColourId, kTextColour); // Texto negro
        labelBtn->setColour(juce::Label::outlineColourId, juce::Colours::lightgrey); // Borde gris claro
        labelBtn->setOpaque(true); // Esto obliga al label a pintar su fondo
        labelBtn->setInterceptsMouseClicks(true, false); // Aceptar clics (como un botón)

        // Crear el listener que maneja el clic
        auto* listener = new MenuItemListener(i, this);  // `this` es DAFAudioProcessorEditor
        labelBtn->addMouseListener(listener, false);  // Agregar listener de clic

        menuButtons.add(labelBtn); // Agregar a la lista de botones
        addAndMakeVisible(labelBtn); // Hacer visible
        labelBtn->setVisible(false); // Iniciar oculto
    }

    delaySlider.setValue(processor.getDelayTimeMs(), juce::dontSendNotification);
    pitchSlider.setValue(processor.getPitchShiftSemitones(), juce::dontSendNotification);

    menuVisible = false;
    contentText.setVisible(false);

    startTimerHz(60);
    
    // Inicializar botón "Volver"
    setupBackButton();
    backButton.setVisible(false);
    
    // ===============================
    //   MONETIZACIÓN / PAYWALL
    // ===============================
    // iOS: inicializa el manager (sin activity)
    // prepara el manager y consulta el producto
/*
    auto* pmptr = &flutalk::PurchaseManagerFactory::instance();
    juce::MessageManager::callAsync([pmptr]{
            pmptr->initialize();
            pmptr->queryProducts();
    });

    // crea y muestra el paywall (visible solo si NO hay derecho adquirido)
    paywall = std::make_unique<PaywallComponent>(*pmptr);
    addAndMakeVisible(*paywall);
    paywall->toFront(false);
    paywall->setVisible(!pmptr->isEntitled());
*/
    // ------------------- Fin de Paywall Manager
}

DAFAudioProcessorEditor::~DAFAudioProcessorEditor()
{
    menuButtons.clear(true);
}

void DAFAudioProcessorEditor::paint(juce::Graphics& g)
{
    // Aplica el color de fondo definido en las constantes
    g.fillAll(kBackgroundColour);
}

void DAFAudioProcessorEditor::resized()
{
    const int margin = 13;
    const int labelW = 320;
    const int sliderH = 24;
    const int labelH = 20;
    const int valueW = 50;
    const int spacing = 40; //12
    const int topBarY = 10;
    const int topBarH = 30;

    int y = 120;

    // Título y botón de menú alineados
    hamburgerButton.setBounds(3, topBarY + 40, 40, topBarH);
    titleLabel.setBounds(getWidth() / 2 - 60, topBarY + 40, 120, topBarH);

    // Retardo
    delayLabel.setBounds(margin, y, labelW, labelH);
    delayValueLabel.setBounds(getWidth() - margin - valueW - 10, y, 58, labelH);
    y += labelH;
    delaySlider.setBounds(margin - 3, y, getWidth() - 2 * margin - valueW, sliderH);
    y += sliderH + spacing;

    // Tono
    pitchLabel.setBounds(margin, y, labelW, labelH);
    pitchValueLabel.setBounds(getWidth() - margin - valueW - 10, y, valueW, sliderH);
    y += labelH;
    pitchSlider.setBounds(margin - 3, y, getWidth() - 2 * margin - valueW, sliderH);
    y += sliderH + spacing;
    
    // Volumen del Micrófono
    volumeLabel.setBounds(margin, y, labelW, labelH);
    volumeValueLabel.setBounds(getWidth() - margin - valueW - 10, y, 58, sliderH);
    y += labelH;
    volumeSlider.setBounds(margin - 3, y, getWidth() - 2 * margin - valueW, sliderH);
    y += sliderH + spacing;
    
    // Noise Gate
    noiseGateLabel.setBounds(margin, y, labelW, labelH);
    noiseGateValueLabel.setBounds(getWidth() - margin - valueW - 10, y, 58, sliderH);
    y += labelH;
    noiseGateSlider.setBounds(margin - 3, y, getWidth() - 2 * margin - valueW, sliderH);
    y += sliderH + spacing;

    // Audio level (opcional)
    if (audioLevelText != nullptr) {
        audioLevelText->setBounds(margin, y, getWidth() - 2 * margin, labelH);
    }
    y += labelH + 5;

    // Estado del micrófono
    micStatusLabel.setBounds(margin, y, getWidth() - 2 * margin, 20);
    y += 30 + 5;

    // Botón iniciar/detener
    startStopButton.setBounds(getWidth() / 2 - 60, y, 120, 30);
    y += 40;

    // Panel educativo (fondo y texto aplicados en constructor)
    const int contentTopOffset = 85;
    contentText.setBounds(16, contentTopOffset, getWidth() - 40, getHeight() - contentTopOffset - 20);

    // Educational Labels
    educationalTitleLabel.setBounds(16, 80, getWidth() - 40, 50);
    educationalContentLabel.setBounds(16, 120, getWidth() - 40, getHeight() - 120);
    backButton.setBounds(getWidth() / 2 - 60, getHeight() - 50, 120, 30);

    // Botones del menú lateral
    if (menuVisible)
    {
        int menuY = contentTopOffset;
        const int menuH = menuButtons.size() * 42;
        int menuW = 0;
        juce::Font font(juce::FontOptions(16.0f)); // mismo tamaño usado en los labels del menú
        juce::GlyphArrangement g;
        for (auto* label : menuButtons)
        {
            g.addFittedText(font, label->getText(), 0.0f, 0.0f, 10000.0f, font.getHeight(), juce::Justification::left, false);
            const int labelWidth = static_cast<int>(g.getBoundingBox(0, label->getText().length(), true).getWidth()) + 10;
            if (labelWidth > menuW)
                menuW = labelWidth;
        }

        // Fondo detrás del menú
        menuBackgroundPanel.setBounds(5, menuY, menuW, menuH);
        menuBackgroundPanel.toFront(true);
        menuBackgroundPanel.setVisible(true);

        for (int i = 0; i < menuButtons.size(); ++i)
        {
            menuButtons[i]->setBounds(5, menuY, menuW, 40);
            menuButtons[i]->setVisible(true);
            menuButtons[i]->toFront(true);
            menuY += 42;
        }

        educationalTitleLabel.setVisible(false);
        educationalContentLabel.setVisible(false);
        backButton.setVisible(false);
    }
    else
    {
        menuBackgroundPanel.setVisible(false);
        for (int i = 0; i < menuButtons.size(); ++i)
            menuButtons[i]->setVisible(false);
    }
    
    // Paywall Manger
    if (paywall)
        paywall->setBounds(getLocalBounds()); // full-screen del editor
    // Fin de Paywall Manger
}

void DAFAudioProcessorEditor::toggleAudioProcessing()
{
    // Alternar el estado del procesamiento
    processor.setProcessingEnabled(!processor.isProcessing());

    bool isNowRunning = processor.isProcessing();

    // Cambiar texto del botón según estado
    startStopButton.setButtonText(isNowRunning ? "Detener" : "Iniciar");

    // Cambiar estado del label de micrófono
    if (isNowRunning)
    {
        micStatusLabel.setText(juce::String::fromUTF8("Micrófono conectado"), juce::dontSendNotification);
        micStatusLabel.setColour(juce::Label::textColourId, juce::Colours::green);
    }
    else
    {
        micStatusLabel.setText(juce::String::fromUTF8("Micrófono detenido"), juce::dontSendNotification);
        micStatusLabel.setColour(juce::Label::textColourId, juce::Colours::red);
    }

    // Ocultar panel educativo si está activo
    contentText.setVisible(false);

    // Ocultar menú si estaba abierto
    menuVisible = false;

    // Redibujar UI
    resized();

    DBG("[DAF] Estado de captura cambiado: " << (isNowRunning ? "ON" : "OFF"));
}

void DAFAudioProcessorEditor::sliderValueChanged(juce::Slider* slider)
{
    if (slider == nullptr) return;
    if (slider == &delaySlider) {
        const float exact = slider->getValue();
        int ms = juce::jlimit(0, 200, (int)std::lround(exact)); // 0..200 ms
        if (std::abs(exact - (float)ms) > 0.001f)
            slider->setValue(ms, juce::dontSendNotification);

        processor.setDelayTimeMs((float)ms);
        delayValueLabel.setText(juce::String(ms) + " ms", juce::dontSendNotification);
    } else if (slider == &pitchSlider) {
        const float exact = slider->getValue();
        // Snap a pasos de 0.5 semitonos y limitar entre -4 y +4
        float snapped = std::round(exact * 2.0f) / 2.0f;
        snapped = juce::jlimit(-4.0f, 4.0f, snapped);

        if (std::abs(exact - snapped) > 0.001f)
            slider->setValue(snapped, juce::dontSendNotification);

        processor.setPitchShiftSemitones(snapped);
        pitchValueLabel.setText(juce::String(snapped, 1) + " st", juce::dontSendNotification);
    } else if (slider == &volumeSlider) {
        float v = juce::jlimit(-24.0f, 24.0f, (float)slider->getValue());
        if (auto* p = processor.apvts.getParameter("inputGain"))
            p->setValueNotifyingHost(p->getNormalisableRange().convertTo0to1(v));

        volumeValueLabel.setText(juce::String(v, 1) + " dB", juce::dontSendNotification);
    } else if (slider == &noiseGateSlider) {
        float v = juce::jlimit(0.0f, 0.1f, (float)slider->getValue());
        if (auto* p = processor.apvts.getParameter("umbralNoiseGate"))
            p->setValueNotifyingHost(p->getNormalisableRange().convertTo0to1(v));

        noiseGateValueLabel.setText(juce::String(v * 1000.0f, 1) + " %", juce::dontSendNotification);
    }
    processor.saveCurrentSettings();
}


void DAFAudioProcessorEditor::timerCallback()
{
    updateSlidersWithAnimation(); // Mantiene la UI actualizada

    bool shouldBeProcessing = processor.isProcessing();
    bool isButtonInSync = (startStopButton.getButtonText() == (shouldBeProcessing ? "Detener" : "Iniciar"));

    if (!isButtonInSync) {
        startStopButton.setButtonText(shouldBeProcessing ? "Detener" : "Iniciar");
        micStatusLabel.setText(shouldBeProcessing ? juce::String::fromUTF8("Micrófono conectado") : juce::String::fromUTF8("Micrófono detenido"), juce::dontSendNotification);
        micStatusLabel.setColour(juce::Label::textColourId, shouldBeProcessing ? juce::Colours::green : juce::Colours::red);
    }
    
    //------------- Paywall Manager
    if (paywall && paywall->isVisible())
    {
        if (flutalk::PurchaseManagerFactory::instance().isEntitled())
        {
            paywall->setVisible(false);
            resized(); // reacomoda la UI
        }
    }
    //------------- Paywall Manager
}

void DAFAudioProcessorEditor::updateSlidersWithAnimation()
{
    // 1. Obtener valores objetivo como enteros
    const int targetDelay = static_cast<int>(std::round(processor.getDelayTimeMs()));
    const int targetPitch = static_cast<int>(std::round(processor.getPitchShiftSemitones()));
    
    // 2. Interpolación suave pero forzando a enteros
    currentDelayDisplay = targetDelay;
    currentPitchDisplay = targetPitch;
    
    // 3. Actualizar UI
    delaySlider.setValue(currentDelayDisplay, juce::dontSendNotification);
    pitchSlider.setValue(currentPitchDisplay, juce::dontSendNotification);
    
    delayValueLabel.setText(juce::String(currentDelayDisplay) + " ms", juce::dontSendNotification);
    pitchValueLabel.setText(juce::String(currentPitchDisplay) + " st", juce::dontSendNotification);
}

void DAFAudioProcessorEditor::showEducationalContent(int index)
{
    auto text = getEducationalText(index);
    auto lineBreak = text.indexOfChar('\n');
    juce::String title = text.substring(0, lineBreak);
    juce::String body = text.substring(lineBreak + 1);

    educationalTitleLabel.setText(title, juce::dontSendNotification);
    educationalContentLabel.setText(body, juce::dontSendNotification);

    educationalTitleLabel.setVisible(true);
    educationalContentLabel.setVisible(true);
    backButton.setVisible(true);
}

void DAFAudioProcessorEditor::setupBackButton()
{
    backButton.setButtonText("Volver");
    backButton.setColour(juce::TextButton::buttonColourId, kPrimaryColour);
    backButton.setColour(juce::TextButton::textColourOffId, juce::Colours::white);
    backButton.onClick = [this]() {
        hideEducationalContent();
        resized();
        repaint();
    };
    backButton.setVisible(false);
    addAndMakeVisible(backButton);
}

// Ocultar contenido educativo
void DAFAudioProcessorEditor::hideEducationalContent()
{
    educationalTitleLabel.setVisible(false);
    educationalContentLabel.setVisible(false);
    backButton.setVisible(false);
}
