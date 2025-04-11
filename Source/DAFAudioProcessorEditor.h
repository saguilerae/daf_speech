#pragma once

#include <JuceHeader.h>
#include "DAFAudioProcessor.h"
#include "AudioLevelLabel.h"

class DAFAudioProcessorEditor : public juce::AudioProcessorEditor,
                                private juce::Slider::Listener,
                                private juce::Timer
{
public:
    explicit DAFAudioProcessorEditor(DAFAudioProcessor&);
    ~DAFAudioProcessorEditor() override;

    void paint(juce::Graphics&) override;
    void resized() override;

private:
    DAFAudioProcessor& processor;

    void sliderValueChanged(juce::Slider* slider) override;
    void timerCallback() override;
    void toggleAudioProcessing();
    void updateMicStatus();
    void updateSliderLabels();
    void updateSlidersWithAnimation(); // Reemplaza a updateSliderPositions
    float currentDelayDisplay = 100.0f; // Valores iniciales
    float currentPitchDisplay = 0.0f;

    // Sliders y labels
    juce::Slider delayTimeSlider;
    juce::Label delayValueLabel;
    juce::Label delayMaxLabel;
    juce::TextButton startStopButton;
    juce::Slider pitchSlider;
    juce::Label pitchLabel;
    juce::Slider delaySlider;
    juce::Label delayLabel;
    juce::Label pitchValueLabel;
    juce::Label micStatusLabel;

    std::unique_ptr<juce::Label> audioLevelText;
    double currentLevel = 0.0;
    

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(DAFAudioProcessorEditor)
};
