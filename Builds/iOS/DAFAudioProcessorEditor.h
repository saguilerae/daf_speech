#pragma once

#include <JuceHeader.h>
#include "DAFAudioProcessor.h"

class DAFAudioProcessorEditor : public juce::AudioProcessorEditor,
                                private juce::Slider::Listener,
                                private juce::Timer
{
public:
    DAFAudioProcessorEditor(DAFAudioProcessor& p);
    ~DAFAudioProcessorEditor() override;

    void paint(juce::Graphics&) override;
    void resized() override;

private:
    DAFAudioProcessor& audioProcessor;

    juce::Slider delayTimeSlider;
    juce::TextButton startStopButton;

    class LevelMeter : public juce::Component
    {
    public:
        LevelMeter();
        void setLevel(float newLevel);
        void paint(juce::Graphics&) override;
    private:
        float level;
    };

    class MicStatusIndicator : public juce::Component
    {
    public:
        MicStatusIndicator();
        void setActive(bool isActive);
        void paint(juce::Graphics&) override;
    private:
        bool active;
    };

    LevelMeter levelMeter;
    MicStatusIndicator micStatusIndicator;

    bool isProcessing = false;
    juce::TextButton iconChangeButton;
    bool processingEnabled = true;
    float currentLevel = 0.0f;

    void toggleAudioProcessing();
    void sliderValueChanged(juce::Slider* slider) override;
    void timerCallback() override;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (DAFAudioProcessorEditor)
};
