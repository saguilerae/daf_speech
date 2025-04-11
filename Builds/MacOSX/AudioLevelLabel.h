#pragma once
#include <JuceHeader.h>

class AudioLevelLabel : public juce::Component,
                       public juce::TooltipClient  // Herencia para tooltips
{
public:
    AudioLevelLabel();
    void paint(juce::Graphics& g) override;
    void setLevel(float newLevel);
    juce::String getTooltip() override;  // Método requerido por TooltipClient
    
private:
    std::atomic<float> currentLevel{0.0f};
    float lastPaintedLevel{0.0f};
    
    juce::Colour getColourForLevel(float level) const;
};
