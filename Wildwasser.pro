# This is the basic qmake template for the Ubuntu-SDK
# it handles creation and installation of the manifest
# file and takes care of subprojects
TEMPLATE = subdirs

#load Ubuntu specific features
load(ubuntu-click)

SUBDIRS += Wildwasser

# specify the manifest file, this file is required for click
# packaging and for the IDE to create runconfigurations
UBUNTU_MANIFEST_FILE=manifest.json.in

# specify translation domain, this must be equal with the
# app name in the manifest file
UBUNTU_TRANSLATION_DOMAIN="wildwasser.kalikiana"

# specify the source files that should be included into
# the translation file, from those files a translation
# template is created in po/template.pot, to create a
# translation copy the template to e.g. de.po and edit the sources
UBUNTU_TRANSLATION_SOURCES+= \
    $$files(*.qml,true) \
    $$files(*.js,true) \
    $$files(*.desktop,true)

# specifies all translations files and makes sure they are
# compiled and installed into the right place in the click package
UBUNTU_PO_FILES+=$$files(po/*.po)

aptest.target   = autopilot
aptest.commands = bash $$PWD/Wildwasser/tests/autopilot/run
aptest.depends  = sub-Wildwasser

unittest.target   = check
unittest.commands = /usr/bin/qmltestrunner -input $$PWD/Wildwasser/tests/unit 
unittest.depends  = sub-Wildwasser

QMAKE_EXTRA_TARGETS += aptest unittest

