#!/bin/bash
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew reinstall imagemagick --HEAD
brew reinstall tesseract --HEAD
