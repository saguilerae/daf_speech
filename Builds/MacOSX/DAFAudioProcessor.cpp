#include "DAFAudioProcessor.h"

DAFAudioProcessor::DAFAudioProcessor()
    : AudioProcessor (BusesProperties()
                      .withInput  ("Input",  juce::AudioChannelSet::stereo(), true)
                      .withOutput ("Output", juce::AudioChannelSet::stereo(), true))
{
    const double maxDelaySeconds = 2.0;
    const int maxDelaySamples = static_cast<int>(maxDelaySeconds * getSampleRate());
    delayBuffer.setSize(2, maxDelaySamples);
    delayBuffer.clear();

    addParameter(delayTimeParam = new juce::AudioParameterFloat(
        "delaytime", "Delay Time", 0.0f, 2000.0f, 100.0f));

    addParameter(dryWetMixParam = new juce::AudioParameterFloat(
        "drywet", "Dry/Wet Mix", 0.0f, 1.0f, 1.0f));
}

DAFAudioProcessor::~DAFAudioProcessor() {}

void DAFAudioProcessor::prepareToPlay(double sampleRate, int samplesPerBlock)
{
    const double maxDelaySeconds = 2.0;
    const int maxDelaySamples = static_cast<int>(maxDelaySeconds * sampleRate);
    delayBuffer.setSize(2, maxDelaySamples);
    delayBuffer.clear();

    writePosition = 0;

    delayTimeSmoother.reset(sampleRate, 0.05);
    delayTimeSmoother.setCurrentAndTargetValue(*delayTimeParam);
}

void DAFAudioProcessor::releaseResources() {}

void DAFAudioProcessor::processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer&)
{
    DBG("Procesando audio... " << buffer.getNumSamples());
    
    juce::ScopedNoDenormals noDenormals;

    const int numInputChannels = getTotalNumInputChannels();
    const int numOutputChannels = getTotalNumOutputChannels();
    const int numSamples = buffer.getNumSamples();

    // Silenciar si está desactivado
    if (!processingEnabled)
    {
        buffer.clear();
        currentLevel = 0.0f;
        return;
    }

    // Limpiar canales no conectados
    for (int channel = numInputChannels; channel < numOutputChannels; ++channel)
        buffer.clear(channel, 0, numSamples);

    const float delayTimeMs = *delayTimeParam;
    float dryWetMix = *dryWetMixParam;

    if (delayTimeMs <= 0.0f)
        dryWetMix = 0.0f;

    const double sampleRate = getSampleRate();
    const float delaySamples = (delayTimeMs / 1000.0f) * sampleRate;
    
    for (int channel = 0; channel < juce::jmin(numInputChannels, numOutputChannels); ++channel)
    {
        float* channelData = buffer.getWritePointer(channel);
        const int delayBufferSize = delayBuffer.getNumSamples();

        for (int sample = 0; sample < numSamples; ++sample)
        {
            const float inputSample = channelData[sample];
            float outputSample = 0.0f;

            delayBuffer.setSample(channel, writePosition, inputSample);

            int readPosition = static_cast<int>(writePosition - delaySamples);
            if (readPosition < 0)
                readPosition += delayBufferSize;

            const float delaySample = delayBuffer.getSample(channel, readPosition);

            outputSample = (1.0f - dryWetMix) * inputSample + dryWetMix * delaySample;

            channelData[sample] = outputSample;

            writePosition++;
            if (writePosition >= delayBufferSize)
                writePosition = 0;
        }
    }

    // ✅ Calcular nivel RMS real para UI
    float sumSquares = 0.0f;
    const float* readPtr = buffer.getReadPointer(0);
    for (int i = 0; i < numSamples; ++i)
        sumSquares += readPtr[i] * readPtr[i];

    float rms = std::sqrt(sumSquares / numSamples);
    currentLevel = juce::jlimit(0.0f, 1.0f, rms * 5.0f); // Escalado aproximado
}

juce::AudioProcessorEditor* DAFAudioProcessor::createEditor()
{
    return new juce::GenericAudioProcessorEditor(*this);
}

bool DAFAudioProcessor::hasEditor() const { return true; }
const juce::String DAFAudioProcessor::getName() const { return "DAF Processor"; }
bool DAFAudioProcessor::acceptsMidi() const { return false; }
bool DAFAudioProcessor::producesMidi() const { return false; }
bool DAFAudioProcessor::isMidiEffect() const { return false; }
double DAFAudioProcessor::getTailLengthSeconds() const { return 2.0; }
int DAFAudioProcessor::getNumPrograms() { return 1; }
int DAFAudioProcessor::getCurrentProgram() { return 0; }
void DAFAudioProcessor::setCurrentProgram(int) {}
const juce::String DAFAudioProcessor::getProgramName(int) { return {}; }
void DAFAudioProcessor::changeProgramName(int, const juce::String&) {}

void DAFAudioProcessor::getStateInformation(juce::MemoryBlock& destData)
{
    auto state = juce::ValueTree("DAFAudioProcessorState");
    state.setProperty("delayTime", static_cast<double>(delayTimeParam->get()), nullptr);
    state.setProperty("dryWetMix", static_cast<double>(dryWetMixParam->get()), nullptr);

    std::unique_ptr<juce::XmlElement> xml(state.createXml());
    copyXmlToBinary(*xml, destData);
}

void DAFAudioProcessor::setStateInformation(const void* data, int sizeInBytes)
{
    std::unique_ptr<juce::XmlElement> xmlState(getXmlFromBinary(data, sizeInBytes));

    if (xmlState.get() != nullptr)
    {
        juce::ValueTree state = juce::ValueTree::fromXml(*xmlState);

        if (state.hasProperty("delayTime"))
            *delayTimeParam = static_cast<float>(state.getProperty("delayTime"));

        if (state.hasProperty("dryWetMix"))
            *dryWetMixParam = static_cast<float>(state.getProperty("dryWetMix"));
    }
}

float DAFAudioProcessor::getDelayTimeMs() const
{
    return delayTimeParam != nullptr ? delayTimeParam->get() : 0.0f;
}

void DAFAudioProcessor::setDelayTimeMs(float newValue)
{
    if (delayTimeParam != nullptr)
        delayTimeParam->setValueNotifyingHost(delayTimeParam->convertTo0to1(newValue));
}

void DAFAudioProcessor::setProcessingEnabled(bool shouldProcess)
{
    processingEnabled = shouldProcess;
}

float DAFAudioProcessor::getCurrentLevel() const
{
    return currentLevel;
}

bool DAFAudioProcessor::isMicActive() const
{
    return micActive;
}
