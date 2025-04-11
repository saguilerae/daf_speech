#include "DAFAudioProcessorEditor.h"

#if JUCE_IOS
#import <Foundation/Foundation.h>
#import "daf_speech-Swift.h"
#endif

DAFAudioProcessorEditor::DAFAudioProcessorEditor (DAFAudioProcessor& p)
    : AudioProcessorEditor (&p), audioProcessor (p)
{
    delayTimeSlider.setSliderStyle(juce::Slider::LinearHorizontal);
    delayTimeSlider.setRange(0.0, 1000.0, 10.0);
    delayTimeSlider.setTextBoxStyle(juce::Slider::TextBoxRight, false, 80, 20);
    delayTimeSlider.setPopupDisplayEnabled(true, false, this);
    delayTimeSlider.setTextValueSuffix(" ms");
    delayTimeSlider.setValue(audioProcessor.getDelayTimeMs());
    delayTimeSlider.addListener(this);
    addAndMakeVisible(&delayTimeSlider);

    addAndMakeVisible(&levelMeter);
    addAndMakeVisible(&micStatusIndicator);

    startStopButton.setButtonText("Start");
    startStopButton.onClick = [this] { toggleAudioProcessing(); };
    addAndMakeVisible(&startStopButton);

    #if JUCE_IOS
    iconChangeButton.setButtonText("Cambiar ícono");
    iconChangeButton.onClick = [] {
        void* pool = objc_autoreleasePoolPush();
        [AppIconSwitcher setAppIcon:@"DarkIcon"];
        objc_autoreleasePoolPop(pool);
    };
    addAndMakeVisible(&iconChangeButton);
    #endif

    startTimerHz(30);
    setSize(500, 300);
}

DAFAudioProcessorEditor::~DAFAudioProcessorEditor()
{
    stopTimer();
}

void DAFAudioProcessorEditor::paint (juce::Graphics& g)
{
    g.fillAll(getLookAndFeel().findColour(juce::ResizableWindow::backgroundColourId));

    g.setColour(juce::Colours::white);
    g.setFont(18.0f);
    g.drawText("DAF Speech", getLocalBounds().removeFromTop(40), juce::Justification::centred, true);

    g.setFont(14.0f);
    g.drawText("Delay Time", 20, 50, 100, 30, juce::Justification::left);
    g.drawText(juce::String(audioProcessor.getDelayTimeMs()) + " ms",
              getWidth() - 120, 50, 100, 30, juce::Justification::right);
    g.drawText("Audio Level", 20, 110, 100, 30, juce::Justification::left);
}

void DAFAudioProcessorEditor::resized()
{
    delayTimeSlider.setBounds(20, 80, getWidth() - 40, 30);
    levelMeter.setBounds(20, 140, getWidth() - 40, 20);
    micStatusIndicator.setBounds(20, 180, getWidth() - 40, 30);
    startStopButton.setBounds((getWidth() - 120) / 2, 230, 120, 40);
#if JUCE_IOS
    iconChangeButton.setBounds((getWidth() - 140) / 2, 280, 140, 40);
#endif
}

DAFAudioProcessorEditor::LevelMeter::LevelMeter() { level = 0.0f; }

void DAFAudioProcessorEditor::LevelMeter::setLevel(float newLevel)
{
    level = newLevel;
    repaint();
}

void DAFAudioProcessorEditor::LevelMeter::paint(juce::Graphics& g)
{
    auto bounds = getLocalBounds().toFloat();
    g.setColour(juce::Colours::darkgrey);
    g.fillRoundedRectangle(bounds, 3.0f);
    g.setColour(juce::Colours::green);
    auto levelWidth = bounds.getWidth() * level;
    g.fillRoundedRectangle(bounds.withWidth(levelWidth), 3.0f);
}

DAFAudioProcessorEditor::MicStatusIndicator::MicStatusIndicator() : active(false) {}

void DAFAudioProcessorEditor::MicStatusIndicator::setActive(bool isActive)
{
    active = isActive;
    repaint();
}

void DAFAudioProcessorEditor::MicStatusIndicator::paint(juce::Graphics& g)
{
    g.setColour(active ? juce::Colours::green : juce::Colours::red);
    g.fillEllipse(10, 10, 10, 10);
    g.setColour(juce::Colours::white);
    g.setFont(14.0f);
    g.drawText(active ? "Microfono conectado" : "Microfono NO detectado",
               30, 0, getWidth() - 30, 30, juce::Justification::left);
}

void DAFAudioProcessorEditor::toggleAudioProcessing()
{
    isProcessing = !isProcessing;
    startStopButton.setButtonText(isProcessing ? "Detener" : "Iniciar");
    audioProcessor.setProcessingEnabled(isProcessing);
}

void DAFAudioProcessorEditor::sliderValueChanged(juce::Slider* slider)
{
    if (slider == &delayTimeSlider)
        audioProcessor.setDelayTimeMs(slider->getValue());
}

void DAFAudioProcessorEditor::timerCallback()
{
    levelMeter.setLevel(audioProcessor.getCurrentLevel(0)); // canal 0 = izquierda
    micStatusIndicator.setActive(audioProcessor.isMicActive());
}
