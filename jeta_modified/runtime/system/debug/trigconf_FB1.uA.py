import sys
sys.path.append('/global/apps/protocompiler_2020.12-SP1-1/lib/hhd/scripts/python/trigmachine')
sys.path.append('/global/apps/protocompiler_2020.12-SP1-1/lib/python/packages/truths_1.2/truths')
from trigmachine import *

if __name__ == "__main__":
    watchPointsCfg = """
c0:
(1105,1105); 0; 1
"""
    stateMachineCfg="""statemachine addtrans -from 0 -to 0 -cond (c0) -trigger
"""
    stateMachineCfgList=[]
    stateMachineCfgList = stateMachineCfg.split('\n')
    hubname='FB1.uA'
    nBits = 4
    err_code = insert_config(nBits, watchPointsCfg, stateMachineCfgList, 0, hubname, 0)
    sys.exit(err_code)
