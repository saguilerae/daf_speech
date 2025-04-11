cmake_minimum_required(VERSION 3.15)

project(daf_speech)
include_directories(${CMAKE_SOURCE_DIR}/JuceLibraryCode)

# Habilitar C++17
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Ruta de JUCE
set(JUCE_ROOT /Users/saguilerae/development/JUCE)
add_subdirectory(${JUCE_ROOT} JUCE)

# Incluir Qt
set(QT_DIR /opt/homebrew/opt/qt)
set(CMAKE_PREFIX_PATH ${QT_DIR})
find_package(Qt6 COMPONENTS Core Gui Widgets REQUIRED)

# Agregar archivos fuente (ajusta según tu estructura de proyecto)
add_executable(daf_speech
    Source/Main.cpp
    Source/MainComponent.cpp
)

# Enlazar JUCE
target_link_libraries(daf_speech PRIVATE 
    juce::juce_gui_extra 
    juce::juce_audio_utils 
)

# Enlazar Qt
target_link_libraries(daf_speech PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
)

set(CMAKE_SKIP_INSTALL_ALL_DEPENDENCY TRUE)
set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/install")  # Evita instalar en /usr/local
