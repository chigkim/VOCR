#!/bin/bash
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew uninstall --ignore-dependencies --force imagemagick
brew install --HEAD imagemagick
brew uninstall --ignore-dependencies --force tesseract-lang
brew uninstall --ignore-dependencies --force tesseract
brew install --HEAD tesseract
brew install --HEAD tesseract-lang
