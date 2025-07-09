#!/usr/bin/env python3
#===============================================================================
# Copyright Synopsys, INC. All rights reserved. You need to read the file
# auxiliary/copyright.txt for full copyright protection details.
#===============================================================================

#===============================================================================
# Imports
#===============================================================================
import argparse
import logging
import os
import shlex
import sys
# import time
import traceback

sys.path.append('/remote/sdgedt/tools/reem/SNPS_FABRIC/Subsystem1/components/i_axi_a2x_2/scratch/rce/python')

import ctpkg.log_mod       as log_mod
import ctpkg.filelock_mod  as filelock_mod
import ctpkg.exec_mod      as exec_mod

#===============================================================================
# Check version of python is min 3.5
#===============================================================================
tPythonMin = (3, 5)
if sys.version_info < tPythonMin:
   exit("ERR  Python %s.%s or later is required.\n" % tPythonMin)

#===============================================================================
# Main application
#===============================================================================
def main():
   oArg, sArgv = parseCli()
   try:
      log_mod.log.initLogging(sScriptName='ivip.py', sScriptLog='ivip.log')
      log_mod.log.start(sArgv)

      #-------------------------------------------------------------------------
      #
      #-------------------------------------------------------------------------
      oVip = Vip(oArg.dTech, oArg.dTitle, oArg.sRootPath[0],  oArg.sDesignDir[0], oArg.sModelListFile[0], oArg.sExtraArgs, oArg.sPostScript[0])


      # 2022.03: .lock file needs group write permissions. Set the umask to
      # 002 overwrites the users umask and ensures the .lock will will have
      # group write
      oUmask_orig = os.umask(0o002)

      if oArg.bCheck and not oArg.bSetup:
         bUptodate = oVip.checkVip()
         if not bUptodate:
            logging.error("VIP setup is out of date")

      if oArg.bSetup:
         oVip.setupVip(oArg.sLinkFile[0], oArg.bDisableLock)

      os.umask(oUmask_orig)

   except Exception as exErr:
      logging.error("Exception: {}.".format(str(exErr)))
      logging.info(traceback.format_exc())

   finally:
      log_mod.log.end()

#===============================================================================
#
#===============================================================================
def parseCli():
   #----------------------------------------------------------------------------
   # Pass0: Parse CLI to
   #----------------------------------------------------------------------------
   oCli = CmdLine()
   oArg = oCli.getArg()

   #----------------------------------------------------------------------------
   # Pass1: If arg file exists, then read file and re-parse CLI
   #----------------------------------------------------------------------------
   sArgv = ""
   if os.path.exists(oArg.sArgFile[0]):
      with open(oArg.sArgFile[0], 'r')  as fh:
         sArgv   = fh.readline().strip()

         # Issue with --extraargs "-aaa bb -ccc"
         # because of the spaces, they were seen as extra cli arguments
         # Ended up with the code to reinsert the " " around them.
         sArgv1 = ""
         for sEl in sys.argv[1:]:
            if " " in sEl:
               sArgv1 += ' "{}"'.format(sEl)
            else:
               sArgv1 += ' {}'.format(sEl)

         # append args read from file
         sArgv1 += " {}".format(sArgv)

         lArg = shlex.split(sArgv1)

         oCli = CmdLine(lArg)
         oArg = oCli.getArg()

   return (oArg, sArgv)

#==============================================================================#
#                                                                              #
#                                       VIP                                    #
#                                                                              #
#==============================================================================#
class Vip:
   #============================================================================
   #
   #============================================================================
   def __init__(self, dTech, dTitle, sRootPath, sDesignDir, sModelListFile, sExtraArgs, sPostScript):
      self.dTech           = dTech
      self.dTitle          = dTitle
      self.sRootPath       = sRootPath
      self.sDesignDir      = sDesignDir
      self.sModelListFile  = sModelListFile
      self.sExtraArgs      = sExtraArgs
      self.sPostScript     = sPostScript

      #-------------------------------------------------------------------------
      #
      #-------------------------------------------------------------------------
      self.dTech_vipcfg    = {}
      self.dTitle_vipcfg   = {}

      self.sPath           = ""

      #-------------------------------------------------------------------------
      #
      #-------------------------------------------------------------------------
      self.checkEnv()

      # Input VIP Info
      # 1. command line: --modellist --techlist
      # 2. command line: --argfile  input file model list file
      if self.dTech and self.dTitle:
         self.printVipInfo(self.dTech, self.dTitle, sMsg="(command line)")

      else:
         raise Exception("Input VIP information not provided on the CLI with --modellist, --techlist OR with --argfile")

      self.setPath()

      # if self.existVipCfg():
      #    self.readVipCfg()
      #    self.printVipInfo(self.dTech_vipcfg, self.dTitle_vipcfg, bPrintHdr=True, sMsg="(vip cfg file)")

   #============================================================================
   # 1. The utility dw_vip_setup comes from DESIGNWARE_HOME
   # 2. when using vmt
   #  - vera must be available i.e. VERA_HOME must be available
   #  - VRO_CACHE_DIR must be defined
   #============================================================================
   def checkEnv(self):
      logging.hdr0("Checking Environment")
      if 'DESIGNWARE_HOME' in os.environ:
         if self.isWriteable(os.environ['DESIGNWARE_HOME']):
            logging.info("DESIGNWARE_HOME : {} (writeable)".format(os.environ['DESIGNWARE_HOME']))
         else:
            logging.info("DESIGNWARE_HOME : {} (read only)".format(os.environ['DESIGNWARE_HOME']))
      else:
         logging.info("DESIGNWARE_HOME : undefined")
         logging.error("DESIGNWARE_HOME must be defined.")

      if 'VRO_CACHE_DIR' in os.environ:
         if self.isWriteable(os.environ['VRO_CACHE_DIR']):
            logging.info("VRO_CACHE_DIR   : {} (writeable)".format(os.environ['VRO_CACHE_DIR']))
         else:
            logging.info("VRO_CACHE_DIR   : {} (read only)".format(os.environ['VRO_CACHE_DIR']))
      else:
         if 'vmt' in self.dTech:
            logging.info("VRO_CACHE_DIR   : undefined")
            logging.error("VRO_CACHE_DIR must be defined when using VIP Technology vmt")
         else:
            logging.info("VRO_CACHE_DIR   : undefined")

      if 'VERA_HOME' in os.environ:
         logging.info("VERA_HOME       : {}".format(os.environ['VERA_HOME']))
      else:
         if 'vmt' in self.dTech:
            logging.info("VERA_HOME       : undefined")
            logging.error("VERA_HOME must be defined when using VIP Technology vmt")
         else:
            logging.info("VERA_HOME       : undefined")

      log_mod.log.raiseExcIfErr("Environment is not setup correctly")

   #============================================================================
   #
   #============================================================================
   def isWriteable(self, sDir):
      if os.access(sDir, os.W_OK):
         return True
      else:
         return False

   #============================================================================
   #
   #============================================================================
   def setPath(self):
      # Need to create the basepath folder as dw_vip_setup may fail
      # create as 777 to ensure anyone can add more subdir
      if not os.path.exists(self.sRootPath):
         oUmask_orig = os.umask(0o000)
         os.makedirs(self.sRootPath, mode=0o0777, exist_ok=True)
         os.umask(oUmask_orig)

      self.sPath = os.path.join(self.sRootPath, self.calcDesignDir(self.dTech, self.dTitle))

   #============================================================================
   # calc name of the vip Design Dir
   # ---------------------------------------------------------------------------
   # - create a name based on the tech and the titles.
   # - if vmt, then append vera version
   # - sorted alphabetically (tech first then title then vera)
   #     - svt Q-2019.12         -> svtQ-2019.12
   #     - amba_svt Q-2019.12    -> ambaSvtQ-2019.12
   #        => folder = ambaSvtQ-2019.12_svtQ-2019.12
   #============================================================================
   def calcDesignDir(self, dTech, dTitle):
      if self.sDesignDir is None:
         lTech = []
         for sTech in dTech:
            sVersion = dTech[sTech]['sVersion']

            lField = sTech.split("_")
            if len(lField) == 2:
               lField[1] = lField[1].capitalize()
            sTech = "".join(lField)

            lTech.append("{}{}".format(sTech, sVersion))

         lTitle = []
         for sTitle in dTitle:
            sVersion = dTitle[sTitle]['sVersion']

            lField = sTitle.split("_")
            if len(lField) == 2:
               lField[1] = lField[1].capitalize()
            sTitle = "".join(lField)

            lTitle.append("{}{}".format(sTitle, sVersion))

         sDesignDir = "_".join(sorted(lTech)) + "_" + "_".join(sorted(lTitle))

         #-------------------------------------------------------------------------
         # If using vera, must add to the vip setup dir
         #-------------------------------------------------------------------------
         if 'vmt' in dTech and 'VERA_HOME' in os.environ:
            sVer = self.getVeraVersion()
            sDesignDir += "_vera{}".format(sVer)

      else:
         sDesignDir = self.sDesignDir

      return sDesignDir

   #============================================================================
   #
   #============================================================================
   def getVeraVersion(self):
      sVer = ""
      dRet  = exec_mod.execCmd(['vera -v'], bPrint=False)
      if dRet['bPass']:
         sVer = dRet['lLog'][0]

      return sVer

   #============================================================================
   #
   #============================================================================
   def getVipDesignDir(self):
      return self.sPath

   #============================================================================
   #
   #============================================================================
   def getVipCfg(self):
      return os.path.join(self.sPath, ".dw_vip.cfg")

   #============================================================================
   #
   #============================================================================
   def existVipCfg(self):
      if os.path.exists(self.getVipCfg()):
         return True
      else:
         return False

   #============================================================================
   #
   #============================================================================
   def printVipInfo(self, dTech, dTitle, bPrintHdr=True, sMsg=""):
      if bPrintHdr:
         logging.hdr0("VIP Information {}".format(sMsg))
      else:
         logging.info("VIP Information {}".format(sMsg))

      if dTech:
         for sTech in dTech:
            logging.info("Technology Library : {} ({})".format(sTech, dTech[sTech]['sVersion']))

      if dTitle:
         for sTitle in dTitle:
            logging.info("Title Library      : {} ({})".format(sTitle, dTitle[sTitle]['sVersion']))
            logging.info("Title Models       : {}".format(", ".join(sorted(dTitle[sTitle]['lModel']))))

   #============================================================================
   # Read a .dw_vip.cfg file
   # ---------------------------------------------------------------------------
   #     // Versioned models:
   #     %MOD apb_master_svt amba_svt P-2019.09 svt
   #     %MOD apb_slave_svt amba_svt P-2019.09 svt
   #
   #     // Versioned libraries:
   #     %LIB svt P-2019.09
   #
   # 2020.09: If IIP uses only vmt. When dw_vip_setup runs
   # the generated .dw_vip.cfg will list vmt AND svt.
   # this means the logic to check if the name of the folder will fail
   #============================================================================
   def readVipCfg(self):
      sFile    = self.getVipCfg()

      dTech    = {}
      dTitle   = {}
      with open(sFile, 'r') as fh:
         lLine = fh.readlines()

         for sLine in lLine:
            sLine = sLine.strip()
            if "%MOD" in sLine:
               lField   = sLine.split(" ")
               sModel   = lField[1]
               sTitle   = lField[2]
               sVersion = lField[3]

               if sTitle not in dTitle:
                  dTitle[sTitle] = {}
                  dTitle[sTitle]['lModel'] = []

               dTitle[sTitle]['lModel'].append(sModel)
               dTitle[sTitle]['sVersion'] = sVersion

            elif "%LIB" in sLine:
               lField   = sLine.split(" ")
               sTech    = lField[1]
               sVersion = lField[2]
               if sTech not in dTech:
                  dTech[sTech] = {}
               dTech[sTech] ['sVersion'] = sVersion

      self.dTech_vipcfg    = dTech
      self.dTitle_vipcfg   = dTitle

      #-------------------------------------------------------------------------
      # 2020.09
      #-------------------------------------------------------------------------
      if 'vmt' in self.dTech and 'svt' not in self.dTech:
         if 'vmt' in self.dTech_vipcfg and 'svt' in self.dTech_vipcfg:
            logging.info("IIP uses vmt but not svt. Found vmt and svt in .dw_vip.cfg. Ignoring svt.")
            del self.dTech_vipcfg['svt']

   #============================================================================
   #
   #============================================================================
   def checkVip(self, bPrintHdr=True):
      if bPrintHdr:
         logging.hdr0("Checking VIP Setup")
         logging.info("Model List File    : {}".format(self.sModelListFile))
         logging.info("VIP Cfg file       : {}".format(self.getVipCfg()))
      else:
         logging.info("Checking VIP Setup")

      bUptodate = True

      #-------------------------------------------------------------------------
      # 1. does the <path>/.dw_vip.cfg exist
      #-------------------------------------------------------------------------
      if not self.existVipCfg():
         logging.warning("Check0: Path VIP Cfg file does not exist")
         bUptodate = False
      else:
         self.readVipCfg()
         logging.info("Check0: Path VIP Cfg file does exist")

      #-------------------------------------------------------------------------
      # 2. Check what vip setup
      #-------------------------------------------------------------------------
      if bUptodate:
         sVipSetupDir_in      = self.calcDesignDir(self.dTech, self.dTitle)

         sVipSetupDir_vipcfg  = self.calcDesignDir(self.dTech_vipcfg, self.dTitle_vipcfg)

         if sVipSetupDir_in == sVipSetupDir_vipcfg:
            logging.info("Check1: VIP Info (input) == VIP Info (VIP Cfg File)")

         else:
            logging.warning("Check1: VIP Info (input) != VIP Info (VIP Cfg File)")
            logging.warning("- {}".format(sVipSetupDir_in))
            logging.warning("- {}".format(sVipSetupDir_vipcfg))
            bUptodate = False

      return bUptodate

   #===============================================================================
   #
   #===============================================================================
   def setupVip(self, sVipLink, bDisableLock):
      logging.hdr0("Setup VIP")
      logging.info("Model List File    : {}".format(self.sModelListFile))
      logging.info("VIP Base Path      : {}".format(self.sRootPath))
      logging.info("VIP Design Dir     : {}".format(self.getVipDesignDir()))
      logging.info("VIP Cfg File       : {}".format(self.getVipCfg()))
      logging.info("VIP Link           : {}".format(sVipLink))
      logging.info("VIP Post Script    : {}".format(self.sPostScript))

      logging.info("NOTE: VIP Path structured as follows")
      logging.info("      <VIP Base Path>/<VIP Design Dir>  <-- VIP models")
      logging.info("      <VIP Base Path>/vip               <-- Compiled VERA models")

      #-------------------------------------------------------------------------
      # No Lock - setup
      #-------------------------------------------------------------------------
      if bDisableLock:
         self.setupVip_run()

      #-------------------------------------------------------------------------
      # Lock - setup
      # If using VMT, then they are compiled.... this can take 5+ minutes...
      #
      # 2021.11: Updated to NOT delete the lock file. I believe the is the root
      # cause for Mantis 11093. Researching on web there is explicit info that
      # the lock file should not be deleted. Therefore im removing the code
      # that removes the file. I believe that when there are multiple parallel
      # process trying to lock the vip that this rm can trigger the exceptions.
      # 2022.03: The FileLock creates the .lock file if it does not exist.
      # it does NOT delete the .lock file. Therefore if there is shared access
      # to an area, you need to ensure the .lock file has group access.
      #-------------------------------------------------------------------------
      else:
         sLockFile   = "{}.lock".format(self.getVipDesignDir())
         oLock       = filelock_mod.FileLock(sLockFile, timeout=1)
         try:
            # the sLockFile is created when the lock is acquired. the presence of
            # the lock file itself does not mean a lock is acquired. it uses linux flock.
            with oLock.acquire(timeout=600, poll_intervall=10):
               self.setupVip_run()

               # 2021.11: Comment out.
               # remove the lock file as last action within "with block" before the lock
               # is released.
               # if os.path.exists(sLockFile):
               #    logging.info("Deleting lock file {} before releasing lock".format(sLockFile))
               #    os.remove(sLockFile)
               # else:
               #    logging.warning("Lock file {} does not exist. Cannot delete.".format(sLockFile))

            # Because lock acquired using "with oLock", the lock is auto released.
            # oLock.release()

         # 2021.11: Improve the message here.
         except filelock_mod.Timeout:
            logging.error("Timeout trying to acquire the lock. It is possible the VIP are not setup.")

         # 2021.11: Add this. User in us01 was seeing this. could not replicate.
         # Added catch of the exception
         #  WRN  Lock file <path> does not exist. Cannot delete. (Wrn = 1)
         #  ERR  Exception: [Errno 37] No locks available. (Err = 1)
         #  INFO Traceback (most recent call last):
         #  <traceback info>
         #  OSError: [Errno 37] No locks available
         # 2022.03: If the .lock file is not accessible (permissions) you see this
         # [Errno 13] Permission denied: <.lock file>
         # Force this to be an ERR as it means things failed.
         except OSError as exErr:
            sErr = str(exErr)
            if "Permission denied" in sErr:
               logging.error("Detected OSError exception: {}".format(sErr))
            else:
               logging.warning("Detected OSError exception: {}".format(sErr))

         # 2021.11: Add this. more protection from another exception
         except Exception as exErr:
            logging.warning("Detected Exception: {}".format(str(exErr)))

         finally:
            pass

            # 2021.11: Comment out.
            # If something has gone wrong, then remove the lock file
            # if os.path.exists(sLockFile):
            #    os.remove(sLockFile)
            #    logging.info("Deleting lock file {}".format(sLockFile))

      #-------------------------------------------------------------------------
      # Link
      # 2022.03: move this to after the setup. this means if there is an exception
      # during the setup, that may be benign, we still create the link.
      #-------------------------------------------------------------------------
      if sVipLink is not None:
         self.genVipLink(sVipLink)

   #============================================================================
   #
   #============================================================================
   def setupVip_run(self):
      if not self.checkVip(bPrintHdr=False):
         self.genModelListFile()
         self.execDwVipSetup()
         if self.sPostScript is not None:
            self.execPostScript()
      else:
         logging.info("VIP setup is up to date. Nothing to do.")

   #============================================================================
   # Generate a dw_vip_setup model list file
   #============================================================================
   def genModelListFile(self):
      logging.info("Generating dw_vip_setup model list file")
      if os.path.exists(self.sModelListFile):
         os.remove(self.sModelListFile)

      with open(self.sModelListFile, 'w') as fh:
         #----------------------------------------------------------------------
         # dw_vip_setup syntax
         #----------------------------------------------------------------------
         for sTitle in self.dTitle:
            sVersion = self.dTitle[sTitle]['sVersion']
            lModel   = self.dTitle[sTitle]['lModel']
            for sModel in lModel:
               fh.write("{} -v {}\n".format(sModel, sVersion))

   #============================================================================
   #
   #============================================================================
   def execPostScript(self):
      logging.hdr1("Running Post Script")

      #-------------------------------------------------------------------------
      # Generate Command
      #-------------------------------------------------------------------------
      sCmd = "{}".format(self.sPostScript)

      #-------------------------------------------------------------------------
      # Execute
      #-------------------------------------------------------------------------
      logging.info("Exec: {}".format(sCmd))
      dRet = exec_mod.execCmd([sCmd])

      if dRet['bPass']:
         logging.info("Post Script succeeded. Took {} secs.".format(dRet['iDuration']))
      else:
         logging.error("Post Script failed.")

   #============================================================================
   #
   #============================================================================
   def execDwVipSetup(self):
      #-------------------------------------------------------------------------
      # Generate Command
      # 2022.03: .lock file needs group write permissions. I noticed that the
      # the getVipDesignDir folder is 755 i.e. group write is not present.
      # This is a feature of dw_vip_setup and in general is what teams want.
      #-------------------------------------------------------------------------
      sCmdTech = ""
      for sTech in self.dTech:
         sVersion = self.dTech[sTech]['sVersion']
         sCmdTech += " -{} {}".format(sTech, sVersion)

      sExtraArgs = ""
      if self.sExtraArgs is not None:
         sExtraArgs = self.sExtraArgs[0]
      sCmd = "{}/bin/dw_vip_setup -path {} {} -add -model_list {} {}".format(os.environ['DESIGNWARE_HOME'], self.getVipDesignDir(), sCmdTech, self.sModelListFile, sExtraArgs)

      #-------------------------------------------------------------------------
      # Execute
      #-------------------------------------------------------------------------
      logging.info("Exec: {}".format(sCmd))
      dRet = exec_mod.execCmd([sCmd])

      if dRet['bPass']:
         logging.info("VIP setup succeeded. Took {} secs.".format(dRet['iDuration']))
      else:
         logging.error("VIP setup failed.")

   #============================================================================
   # Generate a link
   #============================================================================
   def genVipLink(self, sLink):
      logging.info("Creating link {} -> {}".format(sLink, self.getVipDesignDir()))
      if os.path.islink(sLink):
         os.remove(sLink)
      os.symlink(self.getVipDesignDir(), sLink)

#******************************************************************************#
#                                                                              #
#                                      CLI                                     #
#                                                                              #
#******************************************************************************#
class CmdLine:
   def __init__(self, lArg=None):
      self.lArg   = lArg
      self.oArg   = None

      try:
         self._parseCmdLine()
         self._checkCmdLine()
      except Exception:
         raise

   #============================================================================
   # Getters
   #============================================================================
   def getArg(self):
      return self.oArg

   #============================================================================
   # parse the command line and check parameters
   #============================================================================
   def _parseCmdLine(self):
      #-------------------------------------------------------------------------
      # Define Command Line Arguments
      # - default: the value the variable will have if the cmdline switch NOT used
      # - const  : the value the variable will have if the cmdline switch IS used
      #            but no argument is specified.
      #-------------------------------------------------------------------------
      oArgParser = argparse.ArgumentParser(add_help=False)

      #-------------------------------------------------------------------------
      #
      #-------------------------------------------------------------------------
      oArgParser.add_argument(
         '--rootpath',  '-rootpath', '-p',
         metavar="<folder>",
         dest = "sRootPath",
         default=["."],
         required=False,
         nargs=1,
         help="Root path to setup VIP. VIP will be setup in <RootPath>/<DesignDir> where <DesignDir> is calculated or provided on command line with --designdir")

      oArgParser.add_argument(
         '--designdir',  '-designdir', '-dd',
         metavar="<folder>",
         dest = "sDesignDir",
         default=[None],
         required=False,
         nargs=1,
         help="The design dir is by default auto calculated based on VIP technology and model information")

      oArgParser.add_argument(
         '--modellistfile', '-modellistfile', '-mlf',
         metavar="<file>",
         dest = "sModelListFile",
         default=['model_list'],
         required=False,
         nargs=1,
         help="Model list file. Defaults to model_list")

      oArgParser.add_argument(
         '--modellist', '-modellist', '-ml',
         metavar="<list>",
         dest = "lModelList",
         default=None,
         required=False,
         nargs="+",
         help="model list information e.g. <title> <version> <model>[,<model>]")

      oArgParser.add_argument(
         '--argfile', '-argfile', '-af',
         metavar="<list>",
         dest = "sArgFile",
         default=['ivip.arg'],
         required=False,
         nargs=1,
         help="Argument file for IVip")

      oArgParser.add_argument(
         '--linkfile', '-linkfile', '-lf',
         metavar="<list>",
         dest = "sLinkFile",
         default=[None],
         required=False,
         nargs=1,
         help="Create a link to the vip setup dir. ")

      oArgParser.add_argument(
         '--postscript', '-postscript', '-ps',
         metavar="<list>",
         dest = "sPostScript",
         default=[None],
         required=False,
         nargs=1,
         help="Script to run after VIP Cache created.")

      oArgParser.add_argument(
         '--techlist', '-techlist', '-tl',
         metavar="<list>",
         dest = "lTech",
         default=None,
         required=False,
         nargs="+",
         help="VIP Technology e.g. <tech> <version> <tech> <version>")

      oArgParser.add_argument(\
         '--setup', '-setup', \
         dest="bSetup", \
         default=None, \
         required=False, \
         action="store_true", \
         help="Setup vip")

      oArgParser.add_argument(\
         '--check', '-check', \
         dest="bCheck", \
         default=None, \
         required=False, \
         action="store_true", \
         help="Check vip")

      oArgParser.add_argument(
         '--extraargs', '-extraargs',
         metavar="<args>",
         dest = "sExtraArgs",
         default=None,
         required=False,
         nargs=1,
         help="Extra arguments to pass through to dw_vip_setup XXXX")

      oArgParser.add_argument(\
         '--nolock', '-nolock', \
         dest="bDisableLock", \
         default=False, \
         required=False, \
         action="store_true", \
         help="Disable the use of the locking mechanism")

      #-------------------------------------------------------------------------
      # Get Command Line Arguments
      #-------------------------------------------------------------------------
      sProg    = 'IVip (IIP VIP)'
      sDesc    = 'Interfaces for setup VIP'
      sEpilog  = ''
      parser = argparse.ArgumentParser( \
         parents           = [oArgParser],
         prog              = sProg,
         formatter_class   = argparse.RawDescriptionHelpFormatter,
         description       = sDesc,
         epilog            = sEpilog)

      if self.lArg is not None:
         self.oArg = parser.parse_args(self.lArg)
      else:
         self.oArg = parser.parse_args()

   #============================================================================
   #
   #============================================================================
   def _checkCmdLine(self):
      self.iErr = 0

      #-------------------------------------------------------------------------
      # --modellist
      #-------------------------------------------------------------------------
      self.oArg.dTitle = None
      if self.oArg.lModelList is not None:
         self._checkCmdLine_ModelList()

      #-------------------------------------------------------------------------
      # --argfile
      #-------------------------------------------------------------------------
      if self.oArg.sArgFile is not None:
         self._checkCmdLine_ArgFile()

      #-------------------------------------------------------------------------
      # --argfile
      #-------------------------------------------------------------------------
      if self.oArg.sPostScript[0] is not None:
         self._checkCmdLine_PostScriptFile()

      #-------------------------------------------------------------------------
      # --techlist
      #-------------------------------------------------------------------------
      self.oArg.dTech = None
      if self.oArg.lTech is not None:
         self._checkCmdLine_Tech()

      #-------------------------------------------------------------------------
      #
      #-------------------------------------------------------------------------
      if self.iErr > 0:
         sys.exit(1)

   #============================================================================
   #
   #============================================================================
   def _checkCmdLine_ModelList(self):
      iLen = len(self.oArg.lModelList)
      if iLen % 3 != 0:
         self.iErr += 1
         print("ERR  --modellist must have multiples of 3 values i.e. <title> <version> <model>[,<model>]")
      else:
         dTitle = {}
         for lInfo in self.chunks(self.oArg.lModelList, 3):
            sTitle = lInfo[0]
            sVer   = lInfo[1]
            lModel = lInfo[2].split(",")

            dTitle[sTitle] = {}
            dTitle[sTitle]['sVersion']  = sVer
            dTitle[sTitle]['lModel']    = lModel

         self.oArg.dTitle = dTitle

   #============================================================================
   #
   #============================================================================
   def _checkCmdLine_Tech(self):
      iLen = len(self.oArg.lTech)
      if iLen % 2 != 0:
         self.iErr += 1
         print("ERR  --tech must have multiples of 2 values i.e. <technology> <version>")
      else:
         dTech = {}
         for lInfo in self.chunks(self.oArg.lTech, 2):
            sTech  = lInfo[0]
            sVer   = lInfo[1]

            dTech[sTech] = {}
            dTech[sTech]['sVersion']  = sVer

         self.oArg.dTech = dTech

   #============================================================================
   #
   #============================================================================
   def _checkCmdLine_ModelListFile(self):
      if not os.path.exists(self.oArg.sModelListFile[0]):
         self.iErr += 1
         print("ERR  --modellist {} does not exist.".format(self.oArg.sModelListFile[0]))

   #============================================================================
   #
   #============================================================================
   def _checkCmdLine_PostScriptFile(self):
      if not os.path.exists(self.oArg.sPostScript[0]):
         self.iErr += 1
         print("ERR  --postscript {} does not exist.".format(self.oArg.sPostScript[0]))

   #============================================================================
   #
   #============================================================================
   def _checkCmdLine_ArgFile(self):
      if self.oArg.sArgFile[0] != "ivip.arg" and not os.path.exists(self.oArg.sArgFile[0]):
         self.iErr += 1
         print("ERR  --argfile {} does not exist.".format(self.oArg.sArgFile[0]))

   #============================================================================
   #
   #============================================================================
   def chunks(self, lLst, iN):
      """Yield successive n-sized chunks from lst."""
      for i in range(0, len(lLst), iN):
         yield lLst[i:i + iN]

#===============================================================================
#
#===============================================================================
if __name__ == "__main__":
   main()
