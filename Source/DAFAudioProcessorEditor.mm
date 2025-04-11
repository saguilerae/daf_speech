#include "DAFAudioProcessorEditor.h"
#include "DAFAudioProcessor.h"

DAFAudioProcessorEditor::DAFAudioProcessorEditor(DAFAudioProcessor& p)
    : AudioProcessorEditor(&p), processor(p)
{
    setSize(400, 300);

    delayLabel.setText("Retardo", juce::dontSendNotification);
    addAndMakeVisible(delayLabel);

    // Configuración óptima del slider de delay
    delaySlider.setRange(0.0, 1000.0, 1.0);  // Rango de 0 a 1000 en pasos de 1.0
    delaySlider.setSliderStyle(juce::Slider::LinearHorizontal);
    delaySlider.setTextBoxStyle(juce::Slider::NoTextBox, true, 0, 0);
    delaySlider.setDoubleClickReturnValue(true, 100.0);  // Reset a 100ms con doble click
    delaySlider.setMouseDragSensitivity(120);  // Sensibilidad balanceada (80 era muy bajo)
    delaySlider.setNumDecimalPlacesToDisplay(0);  // Mostrar solo valores enteros
    delaySlider.setScrollWheelEnabled(false);  // Deshabilitar rueda del mouse
    delaySlider.setValue(100.0, juce::dontSendNotification);  // Valor inicial sin notificar
    delaySlider.setPopupDisplayEnabled(true, true, this);
    delaySlider.setPopupMenuEnabled(true);
    delaySlider.addListener(this);
    addAndMakeVisible(delaySlider);

    delayValueLabel.setJustificationType(juce::Justification::centredRight);
    addAndMakeVisible(delayValueLabel);

    delayMaxLabel.setText("1000 ms", juce::dontSendNotification);
    delayMaxLabel.setJustificationType(juce::Justification::centredRight);
    addAndMakeVisible(delayMaxLabel);

    pitchLabel.setText("Tono", juce::dontSendNotification);
    addAndMakeVisible(pitchLabel);

    // Configuración óptima del slider de pitch
    pitchSlider.setRange(-12.0, 12.0, 1.0);  // Rango de -12 a 12 en pasos de 1.0
    pitchSlider.setSliderStyle(juce::Slider::LinearHorizontal);
    pitchSlider.setTextBoxStyle(juce::Slider::NoTextBox, true, 0, 0);
    pitchSlider.setDoubleClickReturnValue(true, 0.0);  // Reset a 0 semitonos con doble click
    pitchSlider.setMouseDragSensitivity(120);  // Sensibilidad balanceada
    pitchSlider.setNumDecimalPlacesToDisplay(0);  // Mostrar solo valores enteros
    pitchSlider.setScrollWheelEnabled(false);  // Deshabilitar rueda del mouse
    pitchSlider.setValue(0.0, juce::dontSendNotification);  // Valor inicial sin notificar
    pitchSlider.setPopupDisplayEnabled(true, true, this);
    pitchSlider.setPopupMenuEnabled(true);
    pitchSlider.addListener(this);
    addAndMakeVisible(pitchSlider);

    pitchValueLabel.setJustificationType(juce::Justification::centredRight);
    addAndMakeVisible(pitchValueLabel);

    audioLevelText = std::make_unique<juce::Label>("", "Estado del audio:");
    addAndMakeVisible(audioLevelText.get());

    micStatusLabel.setText("Microfono detenido", juce::dontSendNotification);
    micStatusLabel.setColour(juce::Label::textColourId, juce::Colours::red);
    addAndMakeVisible(micStatusLabel);

    startStopButton.setButtonText("Iniciar");
    startStopButton.onClick = [this] { toggleAudioProcessing(); };
    addAndMakeVisible(startStopButton);

    // Inicializar con valores actuales
    currentDelayDisplay = processor.getDelayTimeMs();
    currentPitchDisplay = processor.getPitchShiftSemitones();
    
    delaySlider.setValue(currentDelayDisplay, juce::dontSendNotification);
    pitchSlider.setValue(currentPitchDisplay, juce::dontSendNotification);
    
    startTimerHz(60);
}

DAFAudioProcessorEditor::~DAFAudioProcessorEditor() {}

void DAFAudioProcessorEditor::paint(juce::Graphics& g)
{
    g.fillAll(getLookAndFeel().findColour(juce::ResizableWindow::backgroundColourId));
    g.setColour(juce::Colours::white);
    g.setFont(20.0f);
    g.drawText("DAF Speech", getLocalBounds().removeFromTop(130), juce::Justification::centred);
}

void DAFAudioProcessorEditor::resized()
{
    const int margin = 20;
    const int labelW = 80;
    const int sliderH = 24;
    const int labelH = 20;
    const int valueW = 50;
    const int spacing = 12;
    int y = 100;

    delayLabel.setBounds(margin, y, labelW, labelH);
    delayMaxLabel.setBounds(getWidth() - margin - valueW - 8, y, 58, labelH);
    y += labelH;

    delaySlider.setBounds(margin, y, getWidth() - 2 * margin - valueW, sliderH);
    //delayValueLabel.setBounds(getWidth() - margin - valueW, y, valueW, sliderH);
    delayValueLabel.setBounds(getWidth() - margin - valueW - 8, y, 58, sliderH);
    y += sliderH + spacing;

    pitchLabel.setBounds(margin, y, labelW, labelH);
    y += labelH;

    pitchSlider.setBounds(margin, y, getWidth() - 2 * margin - valueW, sliderH);
    pitchValueLabel.setBounds(getWidth() - margin - valueW, y, valueW, sliderH);
    y += sliderH + spacing;

    if (audioLevelText != nullptr)
        audioLevelText->setBounds(margin, y, getWidth() - 2 * margin, labelH);
    y += labelH + 5;

    micStatusLabel.setBounds(margin, y, getWidth() - 2 * margin, 20);
    y += 30 + 5;

    startStopButton.setBounds(getWidth() / 2 - 60, y, 120, 30);
}

void DAFAudioProcessorEditor::toggleAudioProcessing() {
    processor.setProcessingEnabled(!processor.isProcessing());

    bool isNowRunning = processor.isProcessing();
    startStopButton.setButtonText(isNowRunning ? "Detener" : "Iniciar");
    
    // Actualizar texto y color del label del micrófono
    if (isNowRunning) {
        micStatusLabel.setText("Microfono conectado", juce::dontSendNotification);
        micStatusLabel.setColour(juce::Label::textColourId, juce::Colours::green);
    } else {
        micStatusLabel.setText("Microfono detenido", juce::dontSendNotification);
        micStatusLabel.setColour(juce::Label::textColourId, juce::Colours::red);
    }

    DBG("[DAF] Estado de captura cambiado: " << (isNowRunning ? "ON" : "OFF"));
}

void DAFAudioProcessorEditor::sliderValueChanged(juce::Slider* slider)
{
    if (slider == nullptr) return;

    if (slider == &delaySlider)
    {
        // Forzar valor entero exacto para delay
        float exactValue = slider->getValue();
        int intValue = static_cast<int>(exactValue + 0.5f); // Redondeo correcto
        
        // Asegurar que no se pase de los límites
        intValue = juce::jlimit(0, 1000, intValue);
        
        // Solo actualizar si hay cambio real
        if (std::abs(exactValue - intValue) > 0.1f) {
            slider->setValue(intValue, juce::dontSendNotification);
        }
        
        processor.setDelayTimeMs(intValue);
        delayValueLabel.setText(juce::String(intValue) + " ms", juce::dontSendNotification);
    }
    else if (slider == &pitchSlider)
    {
        // Forzar valor entero exacto para pitch
        float exactValue = slider->getValue();
        int intValue = static_cast<int>(exactValue + (exactValue >= 0 ? 0.5f : -0.5f)); // Redondeo correcto para negativos
        
        // Asegurar que no se pase de los límites
        intValue = juce::jlimit(-12, 12, intValue);
        
        // Solo actualizar si hay cambio real
        if (std::abs(exactValue - intValue) > 0.1f) {
            slider->setValue(intValue, juce::dontSendNotification);
        }
        
        processor.setPitchShiftSemitones(intValue);
        pitchValueLabel.setText(juce::String(intValue), juce::dontSendNotification);
    }
    
    processor.saveCurrentSettings();
}

void DAFAudioProcessorEditor::timerCallback()
{
    updateSlidersWithAnimation(); // Mantiene la UI actualizada
}

void DAFAudioProcessorEditor::updateSlidersWithAnimation()
{
    // 1. Obtener valores objetivo como enteros
    const int targetDelay = static_cast<int>(std::round(processor.getDelayTimeMs()));
    const int targetPitch = static_cast<int>(std::round(processor.getPitchShiftSemitones()));
    
    // 2. Interpolación suave pero forzando a enteros
    currentDelayDisplay = targetDelay; // Eliminamos la interpolación para valores enteros
    currentPitchDisplay = targetPitch;
    
    // 3. Actualizar UI
    delaySlider.setValue(currentDelayDisplay, juce::dontSendNotification);
    pitchSlider.setValue(currentPitchDisplay, juce::dontSendNotification);
    
    delayValueLabel.setText(juce::String(currentDelayDisplay) + " ms", juce::dontSendNotification);
    pitchValueLabel.setText(juce::String(currentPitchDisplay), juce::dontSendNotification);
}
