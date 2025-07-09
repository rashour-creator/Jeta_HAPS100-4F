#===============================================================================
# Copyright Synopsys, INC. All rights reserved. You need to read the file
# auxiliary/copyright.txt for full copyright protection details.
#===============================================================================
import os
import subprocess
import time
import logging

#===============================================================================
#
#===============================================================================
def execCmd(lCmd, bPrint=True, dEnv={}):
   dReturn              = {}
   dReturn['bPass']     = False
   dReturn['iRetVal']   = 1
   dReturn['sCmd']      = ""
   dReturn['lLog']      = []
   dReturn['sDuration'] = ""
   dReturn['iDuration'] = ""

   try:
      #-------------------------------------------------------------------------
      # Env
      #-------------------------------------------------------------------------
      dEnviron = os.environ.copy()
      dEnviron.update(dEnv)

      #-------------------------------------------------------------------------
      # Exec
      #-------------------------------------------------------------------------
      if isinstance(lCmd, list):
         sCmd     = " ".join(lCmd)
      else:
         sCmd     = lCmd

      tsStart  = time.time()
      p        = subprocess.Popen( \
                  lCmd, \
                  shell=True, \
                  stdout=subprocess.PIPE, \
                  stderr=subprocess.STDOUT, \
                  universal_newlines=True, \
                  env=dEnviron \
                 )

      out      = p.communicate()[0]

      lLog     = out.split("\n")
      tsEnd    = time.time()
      iRetVal  = p.returncode

      #-------------------------------------------------------------------------
      # Print
      #-------------------------------------------------------------------------
      if bPrint:
         for line in lLog:
            logging.info("{}".format(line))

      #-------------------------------------------------------------------------
      # Return
      #-------------------------------------------------------------------------
      if iRetVal == 0:
         dReturn['bPass']     = True
      else:
         dReturn['bPass']     = False

      dReturn['iRetVal']      = iRetVal
      dReturn['sCmd']         = sCmd
      dReturn['lLog']         = lLog
      dReturn['iDuration']    = int(tsEnd - tsStart)

   except OSError as e:
      logging.error("Execution failed:", e, file=sys.stderr)

   #----------------------------------------------------------------------------
   # Return
   #----------------------------------------------------------------------------
   return dReturn
