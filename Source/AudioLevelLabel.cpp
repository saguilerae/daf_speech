#include "AudioLevelLabel.h"

void AudioLevelLabel::paint(juce::Graphics& g)
{
    auto bounds = getLocalBounds().toFloat();
    const float level = juce::jlimit(0.0f, 1.0f, currentLevel.load());
    
    // Fondo gris para la barra completa
    g.setColour(juce::Colours::darkgrey);
    g.fillRoundedRectangle(bounds, 4.0f);
    
    // Calcular el ancho basado en el nivel actual
    const float filledWidth = bounds.getWidth() * level;
    auto filledBounds = bounds.withWidth(filledWidth);
    
    // Color basado en el nivel (verde -> amarillo -> rojo)
    juce::Colour fillColour;
    if (level < 0.6f) {
        // Verde a amarillo
        fillColour = juce::Colour::fromFloatRGBA(2.0f * level, 1.0f, 0.0f, 1.0f);
    } else {
        // Amarillo a rojo
        fillColour = juce::Colour::fromFloatRGBA(1.0f, 1.0f - (level - 0.6f) * 2.5f, 0.0f, 1.0f);
    }
    
    // Dibujar solo la parte activa
    g.setColour(fillColour);
    g.fillRoundedRectangle(filledBounds, 4.0f);
    
    // Borde para mejor visibilidad
    g.setColour(juce::Colours::white.withAlpha(0.2f));
    g.drawRoundedRectangle(bounds, 4.0f, 1.0f);
}

void AudioLevelLabel::setLevel(float newLevel)
{
    // Suavizar la transición del nivel
    const float smoothedLevel = 0.2f * newLevel + 0.8f * currentLevel.load();
    currentLevel.store(smoothedLevel);
    
    // Repintar solo si hay cambio significativo (optimización)
    if (std::abs(smoothedLevel - lastPaintedLevel) > 0.01f) {
        lastPaintedLevel = smoothedLevel;
        repaint();
    }
}
