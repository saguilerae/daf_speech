#include <JuceHeader.h>

#if JUCE_IOS

#import <AVFoundation/AVFoundation.h>
#include "DAFAudioProcessor.h"
#include "DAFAudioProcessorEditor.h"

class iOSStandaloneApp : public juce::JUCEApplication
{
public:
    const juce::String getApplicationName() override       { return "DAF Speech"; }
    const juce::String getApplicationVersion() override    { return "1.0"; }

    void initialise(const juce::String&) override
    {
        DBG("DBG1: Iniciando initialise() en Main.mm");

        NSError* error = nil;
        AVAudioSession* session = [AVAudioSession sharedInstance];

        [session setCategory:AVAudioSessionCategoryPlayAndRecord
                 withOptions:AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionDefaultToSpeaker
                       error:&error];

        if (error) {
            juce::Logger::writeToLog("Error AVAudioSession (categoría): " + juce::String([error.localizedDescription UTF8String]));
        }

        [session setActive:YES error:&error];

        if (error) {
            juce::Logger::writeToLog("Error AVAudioSession (activación): " + juce::String([error.localizedDescription UTF8String]));
        }

        [session requestRecordPermission:^(BOOL granted) {
            juce::Logger::writeToLog(granted ? "Permiso de microfono CONCEDIDO" : "Permiso de microfono DENEGADO");
        }];

        processor = std::make_unique<DAFAudioProcessor>();
        DBG("DBG2: DAFAudioProcessor instanciado");

        editor = std::make_unique<DAFAudioProcessorEditor>(*processor);
        DBG("DBG3: DAFAudioProcessorEditor instanciado");

        deviceManager.initialise(1, 2, nullptr, true);
        processorPlayer.setProcessor(processor.get());
        deviceManager.addAudioCallback(&processorPlayer);
        DBG("DBG4: AudioDeviceManager y ProcessorPlayer configurados");

        mainWindow.reset(new MainWindow("DAF Speech", editor.get(), *this));
        DBG("DBG5: MainWindow creada");
        juce::Logger::writeToLog("Salimos de Main");
    }

    void shutdown() override
    {
        deviceManager.removeAudioCallback(&processorPlayer);
        processorPlayer.setProcessor(nullptr);

        mainWindow = nullptr;
        editor = nullptr;
        processor = nullptr;
    }

private:
    std::unique_ptr<DAFAudioProcessor> processor;
    std::unique_ptr<DAFAudioProcessorEditor> editor;
    juce::AudioDeviceManager deviceManager;
    juce::AudioProcessorPlayer processorPlayer;

    class MainWindow : public juce::DocumentWindow
    {
    public:
        MainWindow(const juce::String& name, juce::Component* content, JUCEApplication& app)
            : DocumentWindow(name,
                             juce::Colours::black,
                             0),
              ownerApp(app)
        {
            setUsingNativeTitleBar(true);
            setContentNonOwned(content, true);
            setFullScreen(true);
            setVisible(true);
        }

        void closeButtonPressed() override
        {
            ownerApp.systemRequestedQuit();
        }

    private:
        JUCEApplication& ownerApp;
    };

    std::unique_ptr<MainWindow> mainWindow;
};

START_JUCE_APPLICATION(iOSStandaloneApp)

#endif
