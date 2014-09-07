
import re
import os
import time
import sys
import unittest
from ave.util.Log import Log
from vimdriver.VimDriver import VimDriver
from ave.util import FileUtil

Log.setMinLevel(Log.Levels.info)
#Log.setMinLevel(Log.Levels.debug)

# Enabling this keeps it open and makes it easier to debug
UseExistingVim = True

ScriptDir = os.path.dirname(os.path.realpath(__file__))

class Tests1(unittest.TestCase):

    def setUp(self):
        self.driver = VimDriver()

        if UseExistingVim and self.driver.isServerUp:
            self.driver.clearBuffer()
        else:
            vimrc = FileUtil.ChangeToForwardSlashes(os.path.join(ScriptDir, 'TestVimRc.vim'))
            self.driver.start(vimrc)

    def tearDown(self):
        if not UseExistingVim:
            self.driver.stop()

    def testRepeatVimLoaded(self):
        # Will throw exception otherwise
        self.driver.command('call repeat#invalidate()')

    def testEasyClipLoaded(self):
        # Will throw exception otherwise
        defaultReg = self.driver.evaluate('EasyClip#GetDefaultReg()')
        self.assertEqual(defaultReg, '"')

if __name__ == '__main__':
    unittest.main()
