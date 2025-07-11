#===============================================================================
# Copyright Synopsys, INC. All rights reserved. You need to read the file
# auxiliary/copyright.txt for full copyright protection details.
#===============================================================================
import logging

#===============================================================================
#
#===============================================================================
def printTable(lHead, llRow):
   #----------------------------------------------------------------------------
   # Col Widths
   #----------------------------------------------------------------------------
   llRow.append(lHead)
   lColWidth   = [(max([len(str(row[i])) for row in llRow]) + 3) for i in range(len(llRow[0])) ]

   iWidth      = sum(lColWidth)

   #----------------------------------------------------------------------------
   # Row Format
   #----------------------------------------------------------------------------
   row_format = "".join(["{:<" + str(iColWidth) + "}" for iColWidth in lColWidth])

   #----------------------------------------------------------------------------
   # Head + underline
   #----------------------------------------------------------------------------
   logging.info(row_format.format(*lHead))
   logging.info("{}".format("-"*iWidth))

   #----------------------------------------------------------------------------
   # Body
   #----------------------------------------------------------------------------
   for lRow in llRow[:-1]:
      logging.info(row_format.format(*lRow))
