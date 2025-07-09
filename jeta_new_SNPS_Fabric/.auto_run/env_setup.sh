#!/bin/sh
## Created by Chitra Dilip Barvekar
## Edited by Ankit Dilip Wahane
## Do not touch without Author's or Editor's permission
BASE_DIR=`pwd`
CONFIG=''
INIT_DONE=`test -d "$WORK_DIR/work/vivadoips" || echo "no"`
DATE=`date +%F`
ENVSCRIPT="./env.sh"
if [[ $# -ne 0 ]]; then
    RUN_CONFIG=$1

    IFS='_' read -ra ENV_VAR <<< "$RUN_CONFIG"
    
    for element in "${ENV_VAR[@]}"
    do
        CUSTOM_VAR=`echo $element | tr '[:lower:]' '[:upper:]'`
        
        if [[ "$element" =~ "tdm" ]]; then
            CONFIG="${CONFIG}ENABLE_TDM=$CUSTOM_VAR "
        else
            CONFIG="${CONFIG}ENABLE_$CUSTOM_VAR=1 "
        fi
    done
else
    RUN_CONFIG="simple"
fi

ZIP_NAME="pcs_${RUN_CONFIG}_$DATE"

if [[ $WEEKLY_RUN == "true" ]]; then
    ZIP_NAME="${ZIP_NAME}_weekly"
    setenv PROTOCOMPILER_HOME /remote/sbgindia_rel/unix/latest_protocompilerTD/
fi

echo "setenv WORK_DIR $WORK_DIR" >> $ENVSCRIPT;
echo "setenv RUN_DIR $WORK_DIR" >> $ENVSCRIPT;
echo "setenv ZIP_NAME $ZIP_NAME" >> $ENVSCRIPT;
echo "setenv PCS_WORK $WORK_DIR/work" >> $ENVSCRIPT;

module list;
source $ENVSCRIPT
if [[ $INIT_DONE == "no" ]]; then
    test -d "$PCS_WORK" || mkdir $WORK_DIR/work
    pcs -xgen -y PCS_WORK=$PCS_WORK
    # workaround for setting proper xgen rtl directory
    xgen_path="$PCS_WORK/rtl/xgen.vc"
    rm -rf $xgen_path;
    echo "-sverilog" >> $xgen_path
    echo "$PCS_WORK/rtl/xactors_connect.v" >> $xgen_path
    echo "$PCS_WORK/rtl/axi_master_xactor.v" >> $xgen_path
    echo "$PCS_WORK/rtl/axi_mmio_master_xactor.v" >> $xgen_path
    pcs -b -bd ./scripts/axi_mmio.hbd PCS_WORK=$PCS_WORK
    pcs -b -bd ./scripts/axi_extmem.hbd PCS_WORK=$PCS_WORK
    pcs -ip ./scripts/mig_ddr4.hip -y PCS_WORK=$PCS_WORK

fi

pcs -y PCS_PROJECTNAME=$ZIP_NAME $CONFIG PCS_WORK=$PCS_WORK || exit 1

RESULT=`grep -q "SUCCESS" $PCS_WORK/$ZIP_NAME/pcs.log || echo "failed"`
if [[ $RESULT == "failed" ]]; then
    echo "Checking failed for $RUN_CONFIG"
    exit 1;
fi

pcs -hw -y PCS_PROJECTNAME=$ZIP_NAME $CONFIG PCS_WORK=$PCS_WORK

RESULT=`grep -q "cfg_close cfg0" $PCS_WORK/pcs_haps_app.log || echo "failed"`
if [[ $RESULT == "failed" ]]; then
    echo "Check the runtime some issue"
    exit 1;
fi

RESULT=`grep -q "job control turned off" ./app/cpp/vuart.txt || echo "failed"`
if [[ $RESULT == "failed" ]]; then
    echo "Check the runtime some issue"
    exit 1;
fi