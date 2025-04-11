#include "DAFAudioProcessor.h"

std::atomic<int> DAFAudioProcessor::instanceCount{0};

DAFAudioProcessor::DAFAudioProcessor()
    : AudioProcessor(
        BusesProperties()
#if !JucePlugin_IsMidiEffect
 #if !JucePlugin_IsSynth
                     
        .withInput("Input", juce::AudioChannelSet::stereo(), true)
 #endif
        .withOutput("Output", juce::AudioChannelSet::stereo(), true)
#endif
    ),
    apvts(*this, nullptr, "PARAMETERS", createParameterLayout()),
    writePositions{0, 0},
    delayTimeSmoother(0.0f),
    dryWetMixSmoother(0.5f),
    inputGainSmoother(1.0f)
{
    loadUserSettings();
    if (auto* param = apvts.getParameter("delayTime"))
        param->sendValueChangedMessageToListeners(param->getValue());
    
    if (auto* param = apvts.getParameter("pitch"))
        param->sendValueChangedMessageToListeners(param->getValue());
    
    ++instanceCount;
    DBG("[DAF] Constructor - Instancias activas: " << instanceCount);

    currentLevels[0].store(-100.0f);
    currentLevels[1].store(-100.0f);

    auto coeffs = juce::dsp::IIR::ArrayCoefficients<float>::makeLowPass(44100.0f, 5000.0f);
    wetFilter.state = new juce::dsp::IIR::Coefficients<float>(coeffs);
}

DAFAudioProcessor::~DAFAudioProcessor()
{
    --instanceCount;
    saveUserSettings();
    DBG("[DAF] Destructor - Instancias activas: " << instanceCount);
}

void DAFAudioProcessor::prepareToPlay(double sampleRate, int samplesPerBlock)
{
    jassert(sampleRate > 0 && samplesPerBlock > 0);

    const int delayBufferSize = juce::nextPowerOfTwo(static_cast<int>(2.0 * sampleRate));
    delayBuffer.setSize(2, delayBufferSize);
    delayBuffer.clear();

    // Inicializar buffer de fade
    fadeBuffer.setSize(2, samplesPerBlock);
    fadeBuffer.clear();

    writePositions[0].store(0);
    writePositions[1].store(0);
    currentLevels[0].store(0.0f);
    currentLevels[1].store(0.0f);

    const double smoothingTime = 0.1;
    delayTimeSmoother.reset(sampleRate, smoothingTime);
    dryWetMixSmoother.reset(sampleRate, smoothingTime);
    inputGainSmoother.reset(sampleRate, smoothingTime);

    delayTimeSmoother.setCurrentAndTargetValue(static_cast<float>(*apvts.getRawParameterValue("delayTime")));
    dryWetMixSmoother.setCurrentAndTargetValue(static_cast<float>(*apvts.getRawParameterValue("dryWet")));
    inputGainSmoother.setCurrentAndTargetValue(
        juce::Decibels::decibelsToGain(static_cast<float>(*apvts.getRawParameterValue("inputGain")))
    );

    wetFilter.prepare({ sampleRate, (juce::uint32)samplesPerBlock, 2 });
    auto coeffs = juce::dsp::IIR::ArrayCoefficients<float>::makeLowPass(sampleRate, 5000.0f);
    wetFilter.state = new juce::dsp::IIR::Coefficients<float>(coeffs);

    for (int ch = 0; ch < 2; ++ch)
    {
        pitchEngine[ch].setSampleRate(static_cast<uint>(sampleRate));
        pitchEngine[ch].setChannels(1);
        pitchEngine[ch].setPitchSemiTones(getPitchShiftSemitones());
        pitchEngine[ch].clear();
    }

    fadeLengthInSamples = static_cast<int>(fadeDurationSeconds * sampleRate);
    DBG("prepareToPlay completado");
}

void DAFAudioProcessor::releaseResources()
{
    fadeBuffer.setSize(0, 0);
}

void DAFAudioProcessor::processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer&)
{
    juce::ScopedNoDenormals noDenormals;
    const int numChannels = buffer.getNumChannels();
    const int numSamples = buffer.getNumSamples();

    if (!processingEnabled) {
        buffer.clear();
        resetLevels();
        return;
    }

    // 1. Limpiar buffer de fade y copiar datos de entrada
    fadeBuffer.makeCopyOf(buffer, true);

    // 2. Aplicar fade-in si está activo
    if (isFadingIn)
    {
        for (int i = 0; i < numSamples; ++i)
        {
            // Calcular ganancia actual del fade
            if (fadeCounter < fadeLengthInSamples)
            {
                fadeGain = static_cast<float>(fadeCounter) / static_cast<float>(fadeLengthInSamples);
                fadeCounter++;
            }
            else
            {
                fadeGain = 1.0f;
                isFadingIn = false; // Fade completado
            }
            
            // Aplicar fade a todas las muestras
            for (int ch = 0; ch < numChannels; ++ch)
            {
                buffer.getWritePointer(ch)[i] = fadeBuffer.getReadPointer(ch)[i] * fadeGain;
            }
        }
    }

    // 3. Obtener parámetros
    float delayTimeMs = apvts.getRawParameterValue("delayTime")->load();
    float pitchShift = apvts.getRawParameterValue("pitch")->load();

    // 4. Procesamiento de delay (si está activo)
    if (delayTimeMs > 0.0f) {
        const float delaySamples = (delayTimeMs / 1000.0f) * getSampleRate();
        const int delayBufferSize = delayBuffer.getNumSamples();

        for (int ch = 0; ch < numChannels; ++ch) {
            float* channelData = buffer.getWritePointer(ch);
            int writePos = writePositions[ch].load();

            for (int i = 0; i < numSamples; ++i) {
                delayBuffer.setSample(ch, writePos, channelData[i]);
                int readPos = (writePos - static_cast<int>(delaySamples) + delayBufferSize) % delayBufferSize;
                channelData[i] = delayBuffer.getSample(ch, readPos);
                writePos = (writePos + 1) % delayBufferSize;
            }
            writePositions[ch].store(writePos);
        }
    }

    // 5. Procesamiento de pitch (con manejo especial de SoundTouch)
    if (std::abs(pitchShift) > 0.1f) {
        // Buffer temporal para acumular salida procesada
        juce::AudioBuffer<float> pitchBuffer(numChannels, numSamples);
        pitchBuffer.clear();

        for (int ch = 0; ch < numChannels; ++ch) {
            float* channelData = buffer.getWritePointer(ch);
            pitchEngine[ch].setPitchSemiTones(pitchShift);
            
            // 1. Enviar muestras a SoundTouch
            pitchEngine[ch].putSamples(channelData, numSamples);
            
            // 2. Recibir muestras procesadas
            int received = pitchEngine[ch].receiveSamples(pitchBuffer.getWritePointer(ch), numSamples);
            
            // 3. Si no hay suficientes muestras, forzar flush
            if (received < numSamples) {
                pitchEngine[ch].flush();
                received += pitchEngine[ch].receiveSamples(pitchBuffer.getWritePointer(ch) + received, numSamples - received);
            }
        }
        
        // Reemplazar buffer original con el procesado
        for (int ch = 0; ch < numChannels; ++ch) {
            buffer.copyFrom(ch, 0, pitchBuffer, ch, 0, numSamples);
        }
    }
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
    juce::MemoryOutputStream stream(destData, true);
    apvts.state.writeToStream(stream);
}

void DAFAudioProcessor::setStateInformation(const void* data, int sizeInBytes)
{
    juce::ValueTree tree = juce::ValueTree::readFromData(data, sizeInBytes);
    if (tree.isValid())
        apvts.replaceState(tree);
}


float DAFAudioProcessor::getDelayTimeMs() const
{
    return *apvts.getRawParameterValue("delayTime");
}

void DAFAudioProcessor::setDelayTimeMs(float newValue)
{
    if (auto* p = apvts.getParameter("delayTime"))
        p->setValueNotifyingHost(p->getNormalisableRange().convertTo0to1(newValue));
}

void DAFAudioProcessor::setProcessingEnabled(bool shouldProcess)
{
    if (shouldProcess && !processingEnabled)
    {
        // Resetear buffers y preparar fade-in
        delayBuffer.clear();
        for (auto& engine : pitchEngine) {
            engine.clear();
        }
        
        // Configurar parámetros del fade-in
        isFadingIn = true;
        fadeGain = 0.0f;
        fadeCounter = 0;
        fadeLengthInSamples = static_cast<int>(fadeDurationSeconds * getSampleRate());
    }
    else if (!shouldProcess && processingEnabled)
    {
        // Resetear el fade cuando se desactiva
        isFadingIn = false;
        fadeGain = 0.0f;
    }
    
    processingEnabled = shouldProcess;
}

float DAFAudioProcessor::getCurrentLevel(int channel) const
{
    if (channel == 0) return currentLevels[0].load();
    if (channel == 1) return currentLevels[1].load();
    return 0.0f;
}

bool DAFAudioProcessor::isMicActive() const
{
    return micActive;
}

bool DAFAudioProcessor::isBusesLayoutSupported(const BusesLayout& layouts) const
{
    // Versión alternativa más compatible
    
    // Para versiones donde getMainInputChannelSet() no existe
    #if JUCE_VERSION < 0x060000
    const auto& mainInput = layouts.getChannelSet(true, 0);
    const auto& mainOutput = layouts.getChannelSet(false, 0);
    #else
    const auto& mainInput = layouts.getMainInputChannelSet();
    const auto& mainOutput = layouts.getMainOutputChannelSet();
    #endif

    const auto mono = juce::AudioChannelSet::mono();
    const auto stereo = juce::AudioChannelSet::stereo();

    return (mainInput == mono || mainInput == stereo) &&
           (mainOutput == mono || mainOutput == stereo);
}

void DAFAudioProcessor::setPitchShiftSemitones(float value)
{
    if (auto* p = apvts.getParameter("pitch"))
        p->setValueNotifyingHost(p->getNormalisableRange().convertTo0to1(value));
}

float DAFAudioProcessor::getPitchShiftSemitones() const
{
    return *apvts.getRawParameterValue("pitch");
}

void DAFAudioProcessor::resetLevels() {
    currentLevels[0].store(0.0f);
    currentLevels[1].store(0.0f);
}

void DAFAudioProcessor::applyInputGain(juce::AudioBuffer<float>& buffer) {
    for (int i = 0; i < buffer.getNumSamples(); ++i) {
        const float gain = inputGainSmoother.getNextValue();
        for (int ch = 0; ch < buffer.getNumChannels(); ++ch) {
            buffer.getWritePointer(ch)[i] *= gain;
        }
    }
}

void DAFAudioProcessor::updateInputLevels(const juce::AudioBuffer<float>& buffer) {
    for (int ch = 0; ch < buffer.getNumChannels(); ++ch) {
        const float* data = buffer.getReadPointer(ch);
        float sum = 0.0f;
        for (int i = 0; i < buffer.getNumSamples(); ++i) {
            sum += data[i] * data[i];
        }
        currentLevels[ch].store(std::sqrt(sum / buffer.getNumSamples()));
    }
}

void DAFAudioProcessor::updateOutputLevels(const juce::AudioBuffer<float>& buffer) {
    for (int ch = 0; ch < buffer.getNumChannels(); ++ch) {
        const float* data = buffer.getReadPointer(ch);
        float sum = 0.0f;
        for (int i = 0; i < buffer.getNumSamples(); ++i) {
            sum += data[i] * data[i];
        }
        currentLevels[ch].store(std::sqrt(sum / buffer.getNumSamples()));
    }
}

void DAFAudioProcessor::processStereoDelay(juce::AudioBuffer<float>& buffer, float delayTimeMs, float mix) {
    const float delaySamples = (delayTimeMs / 1000.0f) * getSampleRate();
    const int delayBufferSize = delayBuffer.getNumSamples();

    juce::AudioBuffer<float> dryBuffer;
    dryBuffer.makeCopyOf(buffer);

    for (int channel = 0; channel < buffer.getNumChannels(); ++channel) {
        float* channelData = buffer.getWritePointer(channel);
        int writePos = writePositions[channel].load();

        for (int i = 0; i < buffer.getNumSamples(); ++i) {
            delayBuffer.setSample(channel, writePos, dryBuffer.getSample(channel, i));
            int readPos = (writePos - static_cast<int>(delaySamples) + delayBufferSize) % delayBufferSize;
            float delayedSample = delayBuffer.getSample(channel, readPos);
            channelData[i] = dryBuffer.getSample(channel, i) * (1.0f - mix) + delayedSample * mix;
            writePos = (writePos + 1) % delayBufferSize;
        }

        writePositions[channel].store(writePos);
    }
}

juce::AudioProcessorValueTreeState::ParameterLayout DAFAudioProcessor::createParameterLayout()
{
    std::vector<std::unique_ptr<juce::RangedAudioParameter>> params;

    params.push_back(std::make_unique<juce::AudioParameterFloat>(
        "inputGain", "Input Gain", juce::NormalisableRange<float>(-24.0f, 24.0f), 0.0f));

    params.push_back(std::make_unique<juce::AudioParameterFloat>(
        "delayTime", "Delay Time", juce::NormalisableRange<float>(0.0f, 1000.0f), 100.0f));

    params.push_back(std::make_unique<juce::AudioParameterFloat>(
        "dryWet", "Dry/Wet Mix", juce::NormalisableRange<float>(0.0f, 1.0f), 0.5f));

    params.push_back(std::make_unique<juce::AudioParameterFloat>(
        "pitch", "Pitch", juce::NormalisableRange<float>(-12.0f, 12.0f), 0.0f));

    return { params.begin(), params.end() };
}

void DAFAudioProcessor::loadUserSettings()
{
    juce::PropertiesFile* settings = getSettingsFile(); // Ahora correctamente declarado
    if (settings != nullptr)
    {
        float delay = settings->getDoubleValue("delayTime", 100.0); // Valor por defecto 100ms
        float pitch = settings->getDoubleValue("pitch", 0.0);       // Valor por defecto 0 semitonos
        
        if (auto* param = apvts.getParameter("delayTime"))
            param->setValueNotifyingHost(apvts.getParameterRange("delayTime").convertTo0to1(delay));
        
        if (auto* param = apvts.getParameter("pitch"))
            param->setValueNotifyingHost(apvts.getParameterRange("pitch").convertTo0to1(pitch));
    }
}

void DAFAudioProcessor::saveUserSettings()
{
    juce::PropertiesFile* settings = getSettingsFile(); // Ahora correctamente declarado
    if (settings != nullptr)
    {
        if (auto* param = apvts.getParameter("delayTime"))
        {
            float delay = apvts.getParameterRange("delayTime").convertFrom0to1(param->getValue());
            settings->setValue("delayTime", delay);
        }
        
        if (auto* param = apvts.getParameter("pitch"))
        {
            float pitch = apvts.getParameterRange("pitch").convertFrom0to1(param->getValue());
            settings->setValue("pitch", pitch);
        }
        
        settings->saveIfNeeded();
    }
}

juce::PropertiesFile* DAFAudioProcessor::getSettingsFile()
{
    static std::unique_ptr<juce::PropertiesFile> settings;
    if (!settings)
    {
        juce::PropertiesFile::Options options;
        options.applicationName = "DAFSpeech";
        options.filenameSuffix = "settings";
        options.osxLibrarySubFolder = "Application Support";
        options.storageFormat = juce::PropertiesFile::storeAsXML;
        
        settings.reset(new juce::PropertiesFile(options));
    }
    return settings.get();
}

void DAFAudioProcessor::saveCurrentSettings()
{
    saveUserSettings(); // Llama al método privado
}
