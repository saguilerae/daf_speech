#pragma once
#include <JuceHeader.h>

class AudioLevelLabel : public juce::Component
{
public:
    AudioLevelLabel();
    void paint(juce::Graphics& g) override;
    void setLevel(float newLevel);
    
private:
    std::atomic<float> currentLevel{0.0f};
    float lastPaintedLevel{0.0f};
};