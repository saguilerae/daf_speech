#include "PitchShifter.h"

PitchShifter::PitchShifter() {}

PitchShifter::~PitchShifter() {}

void PitchShifter::prepare(double sampleRate, int samplesPerBlock)
{
    currentSampleRate = sampleRate;
    maxSamplesPerBlock = samplesPerBlock;

    tempBuffer.setSize(1, maxSamplesPerBlock);

    soundTouchL.setSampleRate(static_cast<uint>(sampleRate));
    soundTouchL.setChannels(1);
    soundTouchL.setPitchSemiTones(pitchSemitones);
    soundTouchL.setTempo(1.0f);  // no cambiar tempo

    soundTouchR.setSampleRate(static_cast<uint>(sampleRate));
    soundTouchR.setChannels(1);
    soundTouchR.setPitchSemiTones(pitchSemitones);
    soundTouchR.setTempo(1.0f);
}

void PitchShifter::reset()
{
    soundTouchL.clear();
    soundTouchR.clear();
}

void PitchShifter::setPitchSemiTones(float newPitch)
{
    pitchSemitones = newPitch;
    soundTouchL.setPitchSemiTones(newPitch);
    soundTouchR.setPitchSemiTones(newPitch);
}

void PitchShifter::processBlock(juce::AudioBuffer<float>& buffer)
{
    const int numSamples = buffer.getNumSamples();
    if (buffer.getNumChannels() < 1 || numSamples == 0)
        return;

    tempBuffer.setSize(1, maxSamplesPerBlock, false, false, true);

    for (int channel = 0; channel < juce::jmin(2, buffer.getNumChannels()); ++channel)
    {
        float* data = buffer.getWritePointer(channel);
        soundtouch::SoundTouch& st = (channel == 0 ? soundTouchL : soundTouchR);

        st.putSamples(data, numSamples);

        int numReceived = st.receiveSamples(tempBuffer.getWritePointer(0), numSamples);

        if (numReceived > 0)
        {
            juce::FloatVectorOperations::copy(data, tempBuffer.getReadPointer(0), numReceived);
        }
        else
        {
            buffer.clear(channel, 0, numSamples);
        }
    }
}
