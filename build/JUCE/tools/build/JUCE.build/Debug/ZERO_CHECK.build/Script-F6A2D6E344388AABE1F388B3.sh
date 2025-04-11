#!/bin/sh
set -e
if test "$CONFIGURATION" = "Debug"; then :
  cd /Users/saguilerae/development/apps/daf_speech/build/JUCE/tools
  make -f /Users/saguilerae/development/apps/daf_speech/build/JUCE/tools/CMakeScripts/ReRunCMake.make
fi
if test "$CONFIGURATION" = "Release"; then :
  cd /Users/saguilerae/development/apps/daf_speech/build/JUCE/tools
  make -f /Users/saguilerae/development/apps/daf_speech/build/JUCE/tools/CMakeScripts/ReRunCMake.make
fi
if test "$CONFIGURATION" = "MinSizeRel"; then :
  cd /Users/saguilerae/development/apps/daf_speech/build/JUCE/tools
  make -f /Users/saguilerae/development/apps/daf_speech/build/JUCE/tools/CMakeScripts/ReRunCMake.make
fi
if test "$CONFIGURATION" = "RelWithDebInfo"; then :
  cd /Users/saguilerae/development/apps/daf_speech/build/JUCE/tools
  make -f /Users/saguilerae/development/apps/daf_speech/build/JUCE/tools/CMakeScripts/ReRunCMake.make
fi

