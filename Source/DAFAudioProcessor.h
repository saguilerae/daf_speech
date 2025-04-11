#pragma once

#include <JuceHeader.h>
#include <array>
#include <atomic>
#include <SoundTouch.h>

using juce::jmax;
using juce::jmin;
using juce::jlimit;

class DAFAudioProcessor : public juce::AudioProcessor
{
public:
    DAFAudioProcessor();
    ~DAFAudioProcessor() override;

    void prepareToPlay(double sampleRate, int samplesPerBlock) override;
    void releaseResources() override;
    void processBlock(juce::AudioBuffer<float>&, juce::MidiBuffer&) override;

    juce::AudioProcessorEditor* createEditor() override;
    bool hasEditor() const override;

    const juce::String getName() const override;
    bool acceptsMidi() const override;
    bool producesMidi() const override;
    bool isMidiEffect() const override;
    double getTailLengthSeconds() const override;

    int getNumPrograms() override;
    int getCurrentProgram() override;
    void setCurrentProgram(int index) override;
    const juce::String getProgramName(int index) override;
    void changeProgramName(int index, const juce::String& newName) override;

    void getStateInformation(juce::MemoryBlock& destData) override;
    void setStateInformation(const void* data, int sizeInBytes) override;

    // APVTS y parámetros
    juce::AudioProcessorValueTreeState apvts;
    static juce::AudioProcessorValueTreeState::ParameterLayout createParameterLayout();

    float getDelayTimeMs() const;
    void setDelayTimeMs(float newValue);
    float getPitchShiftSemitones() const;
    void setPitchShiftSemitones(float value);

    void setProcessingEnabled(bool shouldProcess);
    bool isProcessing() const { return processingEnabled; }
    bool isMicActive() const;
    float getCurrentLevel(int channel) const;

    bool isBusesLayoutSupported(const BusesLayout& layouts) const override;
    
    static std::atomic<int> instanceCount; // Contador de instancias activas
    
    void saveCurrentSettings(); // Nuevo método público

private:
    juce::AudioBuffer<float> delayBuffer;
    std::array<std::atomic<int>, 2> writePositions;
    std::array<std::atomic<float>, 2> currentLevels;

    juce::SmoothedValue<float> delayTimeSmoother;
    juce::SmoothedValue<float> dryWetMixSmoother;
    juce::SmoothedValue<float> inputGainSmoother;

    bool processingEnabled = false;
    bool micActive = true;

    juce::dsp::ProcessorDuplicator<
        juce::dsp::IIR::Filter<float>,
        juce::dsp::IIR::Coefficients<float>> wetFilter;

    soundtouch::SoundTouch pitchEngine[2]; // SoundTouch por canal

    void resetLevels();
    void updateInputLevels(const juce::AudioBuffer<float>& buffer);
    void applyInputGain(juce::AudioBuffer<float>& buffer);
    void processStereoDelay(juce::AudioBuffer<float>& buffer, float delayTimeMs, float mix);
    void updateOutputLevels(const juce::AudioBuffer<float>& buffer);
    void ensureStereo(juce::AudioBuffer<float>& buffer);
    
    juce::PropertiesFile* getSettingsFile();
    void loadUserSettings();
    void saveUserSettings();
    
    // Variables para fade-in
    bool isFadingIn = false;
    float fadeGain = 0.0f;
    const float fadeDurationSeconds = 0.1f; // 100ms de fade-in (aumentado de 50ms)
    int fadeCounter = 0;
    int fadeLengthInSamples = 0;
    juce::AudioBuffer<float> fadeBuffer; // Buffer temporal para fade

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(DAFAudioProcessor)
};
