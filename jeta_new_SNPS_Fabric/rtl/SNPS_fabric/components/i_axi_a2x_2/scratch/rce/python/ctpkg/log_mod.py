#===============================================================================
# Copyright Synopsys, INC. All rights reserved. You need to read the file
# auxiliary/copyright.txt for full copyright protection details.
#===============================================================================
import os
import sys
import time
import logging

#===============================================================================
# Setup logging
# - output goes to stdout and file
# - change the format of the messages
# - count critical, error & warning messages
# - add extra methods. logging.hdr0, logging.hdr1
# - add extra methods. log.start, log.end
#===============================================================================
class log:
   sScriptName       = ''
   tsStart           = int(time.time())
   consoleHandler    = None

   @staticmethod
   def initLogging(sScriptName='', sScriptLog=''):
      global consoleHandler
      log.sScriptName   = sScriptName
      log.sScriptLog    = sScriptLog

      #-------------------------------------------------------------------------
      # This adds new logging level: logging.hdr0(), logging.hdr1()
      #-------------------------------------------------------------------------
      log.addLoggingLevel('HDR0', 19)
      log.addLoggingLevel('HDR1', 18)

      #-------------------------------------------------------------------------
      # create a logger
      # - need to set the level to something low.
      #-------------------------------------------------------------------------
      rootLogger = logging.getLogger()
      rootLogger.setLevel(logging.DEBUG)

      #-------------------------------------------------------------------------
      # Formatter i.e. how messages are printed
      # - the 4.4 means allocates 4 chars and truncate string to 4 (.4)
      #-------------------------------------------------------------------------
      # fileFormatter     = logging.Formatter("%(levelname)-4.4s %(message)s")
      log.oFileFormatter = log.MyLogFormatter()
      log.oLogFormatter  = log.MyLogFormatter()

      #-------------------------------------------------------------------------
      # Log to files
      #-------------------------------------------------------------------------
      fileHandler    = logging.FileHandler(sScriptLog, mode='w')
      fileHandler.setLevel(logging.DEBUG)
      fileHandler.setFormatter(log.oFileFormatter )
      rootLogger.addHandler(fileHandler)

      #-------------------------------------------------------------------------
      # Log to stdout
      # - You can use the INFO, HDR0, HDR1, DEBUG to control the verbosity
      #-------------------------------------------------------------------------
      consoleHandler = logging.StreamHandler(sys.stdout)
      consoleHandler.setLevel(logging.HDR1)
      consoleHandler.setFormatter(log.oLogFormatter)
      rootLogger.addHandler(consoleHandler)

   @staticmethod
   def setLogLevel(iLevel):
      consoleHandler.setLevel(iLevel)

   #===============================================================================
   # Format the logging messages
   # 1. Abbreviate to CRI, ERR, WRN, INFO, DBG
   # 2. Count the CRI, ERR, WRN
   #
   # The "logging" supports different syntaxes (styles) to format messages.
   # - The style is one of %, '{' or '$'.
   #  - If one of these is not specified, then '%' will be used
   #  - If the style is '%', the message format string uses %(<dictionary key>)s styled string substitution; the possible keys are documented in LogRecord attributes.
   #  - If the style is '{', the message format string is assumed to be compatible with str.format() (using keyword arguments),
   #  - if the style is '$'  the message format string should conform to what is expected by string.Template.substitute().
   #
   # In the logger class you are effectively updating the style
   #  - logging._STYLES['{'][0](sStr)
   #                            ***  -> this is how to format the message.
   #                     * -----------> this means the '{' style
   #===============================================================================
   class MyLogFormatter(logging.Formatter):
      def __init__(self):
         self.iCritical, self.iError, self.iWarning = 0, 0, 0
         super().__init__()

      def format(self, record):
         dFormat   = {}
         if record.levelno == 50:
            self.iCritical  += 1
            dFormat[record.levelno] = logging._STYLES['{'][0]("CRI  {message} (Cri = %d)" % (self.iCritical))
         elif record.levelno == 40:
            self.iError     += 1
            dFormat[record.levelno] = logging._STYLES['{'][0]("ERR  {message} (Err = %d)" % (self.iError))
         elif record.levelno == 30:
            self.iWarning   += 1
            dFormat[record.levelno] = logging._STYLES['{'][0]("WRN  {message} (Wrn = %d)" % (self.iWarning))
         elif record.levelno == 20:
            dFormat[record.levelno] = logging._STYLES['{'][0]("INFO {message}" )
         elif record.levelno == 19:
            sStr  = "INFO #"+"="*79+"\n"
            sStr += "INFO # {message}\n"
            sStr += "INFO #"+"="*79
            dFormat[record.levelno] = logging._STYLES['{'][0](sStr)
         elif record.levelno == 18:
            sStr  = "INFO #"+"-"*79+"\n"
            sStr += "INFO # {message}\n"
            sStr += "INFO #"+"-"*79
            dFormat[record.levelno] = logging._STYLES['{'][0](sStr)
         elif record.levelno == 10:
            dFormat[record.levelno] = logging._STYLES['{'][0]("DBG  {message}" )

         self._style = dFormat.get(record.levelno, None)
         return logging.Formatter.format(self, record)

   #================================================================================
   # From http://stackoverflow.com/questions/2183233/how-to-add-a-custom-loglevel-to-pythons-logging-facility
   #================================================================================
   @staticmethod
   def addLoggingLevel(levelName, levelNum, methodName=None):
       """
       Comprehensively adds a new logging level to the `logging` module and the
       currently configured logging class.

       `levelName` becomes an attribute of the `logging` module with the value
       `levelNum`. `methodName` becomes a convenience method for both `logging`
       itself and the class returned by `logging.getLoggerClass()` (usually just
       `logging.Logger`). If `methodName` is not specified, `levelName.lower()` is
       used.

       To avoid accidental clobbering of existing attributes, this method will
       raise an `AttributeError` if the level name is already an attribute of the
       `logging` module or if the method name is already present

       Example
       -------
       >>> addLoggingLevel('TRACE', logging.DEBUG - 5)
       >>> logging.getLogger(__name__).setLevel("TRACE")
       >>> logging.getLogger(__name__).trace('that worked')
       >>> logging.trace('so did this')
       >>> logging.TRACE
       5

       """
       if not methodName:
           methodName = levelName.lower()

       if hasattr(logging, levelName):
          raise AttributeError('{} already defined in logging module'.format(levelName))
       if hasattr(logging, methodName):
          raise AttributeError('{} already defined in logging module'.format(methodName))
       if hasattr(logging.getLoggerClass(), methodName):
          raise AttributeError('{} already defined in logger class'.format(methodName))

       # This method was inspired by the answers to Stack Overflow post
       # http://stackoverflow.com/q/2183233/2988730, especially
       # http://stackoverflow.com/a/13638084/2988730
       def logForLevel(self, message, *args, **kwargs):
           if self.isEnabledFor(levelNum):
               self._log(levelNum, message, args, **kwargs)
       def logToRoot(message, *args, **kwargs):
           logging.log(levelNum, message, *args, **kwargs)

       logging.addLevelName(levelNum, levelName)
       setattr(logging, levelName, levelNum)
       setattr(logging.getLoggerClass(), methodName, logForLevel)
       setattr(logging, methodName, logToRoot)

   #================================================================================
   # Functions to call at start/end of the script
   #================================================================================
   @staticmethod
   def start(sArgv=None):
      logging.hdr0("Start {}".format(log.sScriptName))
      logging.info("PWD          : {}".format(os.getcwd()))
      logging.info("Date Time    : {}".format(time.strftime("%Y-%m-%d %H:%M:%S")))
      logging.info("Args         : {}".format(" ".join(sys.argv[1:])))
      if sArgv is not None:
         logging.info("Args (extra) : {}".format(sArgv))

   @staticmethod
   def end():
      iExitCode, sStatus = (0, "PASS") if log.getCriCount() == 0 and log.getErrCount() == 0 else (1, "FAIL")

      logging.hdr0("End {}".format(log.sScriptName))
      logging.info("No. Critical : {}".format(log.getCriCount()))
      logging.info("No. Error    : {}".format(log.getErrCount()))
      logging.info("No. Warning  : {}".format(log.getWrnCount()))
      logging.info("Duration     : {} sec".format(int(time.time()) - log.tsStart))
      logging.info("Status       : {} (ExitCode={})".format(sStatus, iExitCode))
      exit(iExitCode)

   def raiseExcIfErr(sMsg):
      if log.getCriErrCount() > 0:
         raise Exception(sMsg)
   def getCriErrCount():
      return log.oLogFormatter.iCritical + log.oLogFormatter.iError
   def getCriCount():
      return log.oLogFormatter.iCritical
   def getErrCount():
      return log.oLogFormatter.iError
   def getWrnCount():
      return log.oLogFormatter.iWarning
