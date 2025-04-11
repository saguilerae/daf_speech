#pragma once

#include <JuceHeader.h>

class DAFAudioProcessor : public juce::AudioProcessor
{
public:
    DAFAudioProcessor();
    ~DAFAudioProcessor() override;

    void prepareToPlay (double sampleRate, int samplesPerBlock) override;
    void releaseResources() override;
    void processBlock (juce::AudioBuffer<float>&, juce::MidiBuffer&) override;

    juce::AudioProcessorEditor* createEditor() override;
    bool hasEditor() const override;

    const juce::String getName() const override;
    bool acceptsMidi() const override;
    bool producesMidi() const override;
    bool isMidiEffect() const override;
    double getTailLengthSeconds() const override;

    int getNumPrograms() override;
    int getCurrentProgram() override;
    void setCurrentProgram (int index) override;
    const juce::String getProgramName (int index) override;
    void changeProgramName (int index, const juce::String& newName) override;

    void getStateInformation (juce::MemoryBlock& destData) override;
    void setStateInformation (const void* data, int sizeInBytes) override;

    float getDelayTimeMs() const;
    void setDelayTimeMs(float newValue);
    void setProcessingEnabled(bool shouldProcess);
    float getCurrentLevel() const;
    bool isMicActive() const;

private:
    juce::AudioBuffer<float> delayBuffer;
    int writePosition = 0;

    juce::SmoothedValue<float> delayTimeSmoother;
    juce::AudioParameterFloat* delayTimeParam = nullptr;
    juce::AudioParameterFloat* dryWetMixParam = nullptr;

    bool processingEnabled = true;
    float currentLevel = 0.0f;
    bool micActive = true;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (DAFAudioProcessor)
};
