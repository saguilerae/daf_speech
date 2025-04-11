#pragma once

#include <JuceHeader.h>
#include "SoundTouch.h"

class PitchShifter
{
public:
    PitchShifter();
    ~PitchShifter();

    void prepare(double sampleRate, int samplesPerBlock);
    void reset();
    void setPitchSemiTones(float newPitch);
    void processBlock(juce::AudioBuffer<float>& buffer);

private:
    soundtouch::SoundTouch soundTouchL;
    soundtouch::SoundTouch soundTouchR;

    float pitchSemitones = 0.0f;
    double currentSampleRate = 44100.0;
    int maxSamplesPerBlock = 512;

    juce::AudioBuffer<float> tempBuffer;
};
