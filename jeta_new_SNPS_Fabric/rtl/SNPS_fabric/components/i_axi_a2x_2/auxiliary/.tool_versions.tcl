
#==============================================================================#
# This file is no longer used by coreTools. It is preserved for legacy         #
# purposes. The version information in the file is correct.                    #
# The equivalent information is stored in the coreKit. An API exists that      #
# allows the following actions.                                                #
# 1. Changing the Min/Max version of a Tool/VIP                                #
# 2. Disabling checking a Tool/VIP                                             #
#                                                                              #
# The following command provides more information on how to use the API.       #
# coreTools> ::RCE_Public::print_tool_version_help                             #
#==============================================================================#
namespace eval ::RCEFLOW {}
set ::RCEFLOW::toolVersionsMin(FusionCompiler) "T-2022.03-SP5"
set ::RCEFLOW::toolVersionsMin(ProtoCompiler) "2020.12-1"
set ::RCEFLOW::toolVersionsMin(RTL_Architect) "T-2022.03-SP5"
set ::RCEFLOW::toolVersionsMin(SpyGlass) "T-2022.06-SP1-1"
set ::RCEFLOW::toolVersionsMin(SpyGlass_SG_EngCouncil) "2022.12"
set ::RCEFLOW::toolVersionsMin(SpyGlass_SG_GuideWare) "2022.06"
set ::RCEFLOW::toolVersionsMin(VCS) "T-2022.06-SP2"
set ::RCEFLOW::toolVersionsMin(VC_LP) "T-2022.06-SP2"
set ::RCEFLOW::toolVersionsMin(VC_SpyGlass) "2022.06-SP1-1a"
set ::RCEFLOW::toolVersionsMin(VC_Static) "T-2022.06-SP2"
set ::RCEFLOW::toolVersionsMin(VcSpyGlass_SG_EngCouncil) "2022.12"
set ::RCEFLOW::toolVersionsMin(Verdi) "T-2022.06-SP2"
set ::RCEFLOW::toolVersionsMin(dc_shell) "T-2022.03-SP5"
set ::RCEFLOW::toolVersionsMin(fm_shell) "T-2022.03-SP5"
set ::RCEFLOW::toolVersionsMin(pt_shell) "T-2022.03-SP5"
set ::RCEFLOW::toolVersionsMin(synplicity) "S-2021.09-SP2"
set ::RCEFLOW::toolVersionsMin(vip:amba_svt) "U-2022.12"
set ::RCEFLOW::toolVersionsMin(vip:svt) "T-2022.09"

set ::RCEFLOW::toolVersionsMax(FusionCompiler) ""
set ::RCEFLOW::toolVersionsMax(ProtoCompiler) ""
set ::RCEFLOW::toolVersionsMax(RTL_Architect) ""
set ::RCEFLOW::toolVersionsMax(SpyGlass) ""
set ::RCEFLOW::toolVersionsMax(SpyGlass_SG_EngCouncil) ""
set ::RCEFLOW::toolVersionsMax(SpyGlass_SG_GuideWare) ""
set ::RCEFLOW::toolVersionsMax(VCS) ""
set ::RCEFLOW::toolVersionsMax(VC_LP) ""
set ::RCEFLOW::toolVersionsMax(VC_SpyGlass) ""
set ::RCEFLOW::toolVersionsMax(VC_Static) ""
set ::RCEFLOW::toolVersionsMax(VcSpyGlass_SG_EngCouncil) ""
set ::RCEFLOW::toolVersionsMax(Verdi) ""
set ::RCEFLOW::toolVersionsMax(dc_shell) ""
set ::RCEFLOW::toolVersionsMax(fm_shell) ""
set ::RCEFLOW::toolVersionsMax(pt_shell) ""
set ::RCEFLOW::toolVersionsMax(synplicity) ""
set ::RCEFLOW::toolVersionsMax(vip:amba_svt) ""
set ::RCEFLOW::toolVersionsMax(vip:svt) ""

set ::RCEFLOW::verify_tool(FusionCompiler) 1
set ::RCEFLOW::verify_tool(ProtoCompiler) 1
set ::RCEFLOW::verify_tool(RTL_Architect) 1
set ::RCEFLOW::verify_tool(SpyGlass) 1
set ::RCEFLOW::verify_tool(SpyGlass_SG_EngCouncil) 1
set ::RCEFLOW::verify_tool(SpyGlass_SG_GuideWare) 1
set ::RCEFLOW::verify_tool(VCS) 1
set ::RCEFLOW::verify_tool(VC_LP) 1
set ::RCEFLOW::verify_tool(VC_SpyGlass) 1
set ::RCEFLOW::verify_tool(VC_Static) 1
set ::RCEFLOW::verify_tool(VcSpyGlass_SG_EngCouncil) 1
set ::RCEFLOW::verify_tool(Verdi) 1
set ::RCEFLOW::verify_tool(dc_shell) 1
set ::RCEFLOW::verify_tool(fm_shell) 1
set ::RCEFLOW::verify_tool(pt_shell) 1
set ::RCEFLOW::verify_tool(synplicity) 1
set ::RCEFLOW::verify_tool(vip:amba_svt) 1
set ::RCEFLOW::verify_tool(vip:svt) 1

set ::RCEFLOW::verify_tool_names(FusionCompiler) fc_shell
set ::RCEFLOW::verify_tool_names(ProtoCompiler) protocompiler
set ::RCEFLOW::verify_tool_names(RTL_Architect) rtl_shell
set ::RCEFLOW::verify_tool_names(SpyGlass) spyglass
set ::RCEFLOW::verify_tool_names(SpyGlass_SG_EngCouncil) ""
set ::RCEFLOW::verify_tool_names(SpyGlass_SG_GuideWare) ""
set ::RCEFLOW::verify_tool_names(VCS) vcs
set ::RCEFLOW::verify_tool_names(VC_LP) vcstatic
set ::RCEFLOW::verify_tool_names(VC_SpyGlass) vcstatic
set ::RCEFLOW::verify_tool_names(VC_Static) vcstatic
set ::RCEFLOW::verify_tool_names(VcSpyGlass_SG_EngCouncil) ""
set ::RCEFLOW::verify_tool_names(Verdi) verdi
set ::RCEFLOW::verify_tool_names(cc) cc
set ::RCEFLOW::verify_tool_names(cc_hpux) cc
set ::RCEFLOW::verify_tool_names(cc_linux) cc
set ::RCEFLOW::verify_tool_names(cc_solaris) cc
set ::RCEFLOW::verify_tool_names(dc_shell) dc_shell
set ::RCEFLOW::verify_tool_names(fm_shell) fm_shell
set ::RCEFLOW::verify_tool_names(gcc) gcc
set ::RCEFLOW::verify_tool_names(gcc_hpux) gcc
set ::RCEFLOW::verify_tool_names(gcc_linux) gcc
set ::RCEFLOW::verify_tool_names(gcc_solaris) gcc
set ::RCEFLOW::verify_tool_names(pt_shell) pt_shell
set ::RCEFLOW::verify_tool_names(synplicity) synplify
set ::RCEFLOW::verify_tool_names(vip:amba_svt) vip:./vip/svt/amba_svt
set ::RCEFLOW::verify_tool_names(vip:svt) vip:./vip/svt/common

namespace eval ::RCE {}
set ::RCE::toolVersionsMin(FusionCompiler) "T-2022.03-SP5"
set ::RCE::toolVersionsMin(ProtoCompiler) "2020.12-1"
set ::RCE::toolVersionsMin(RTL_Architect) "T-2022.03-SP5"
set ::RCE::toolVersionsMin(SpyGlass) "T-2022.06-SP1-1"
set ::RCE::toolVersionsMin(SpyGlass_SG_EngCouncil) "2022.12"
set ::RCE::toolVersionsMin(SpyGlass_SG_GuideWare) "2022.06"
set ::RCE::toolVersionsMin(VCS) "T-2022.06-SP2"
set ::RCE::toolVersionsMin(VC_LP) "T-2022.06-SP2"
set ::RCE::toolVersionsMin(VC_SpyGlass) "2022.06-SP1-1a"
set ::RCE::toolVersionsMin(VC_Static) "T-2022.06-SP2"
set ::RCE::toolVersionsMin(VcSpyGlass_SG_EngCouncil) "2022.12"
set ::RCE::toolVersionsMin(Verdi) "T-2022.06-SP2"
set ::RCE::toolVersionsMin(dc_shell) "T-2022.03-SP5"
set ::RCE::toolVersionsMin(fm_shell) "T-2022.03-SP5"
set ::RCE::toolVersionsMin(pt_shell) "T-2022.03-SP5"
set ::RCE::toolVersionsMin(synplicity) "S-2021.09-SP2"
set ::RCE::toolVersionsMin(vip:amba_svt) "U-2022.12"
set ::RCE::toolVersionsMin(vip:svt) "T-2022.09"

set ::RCE::toolVersionsMax(FusionCompiler) ""
set ::RCE::toolVersionsMax(ProtoCompiler) ""
set ::RCE::toolVersionsMax(RTL_Architect) ""
set ::RCE::toolVersionsMax(SpyGlass) ""
set ::RCE::toolVersionsMax(SpyGlass_SG_EngCouncil) ""
set ::RCE::toolVersionsMax(SpyGlass_SG_GuideWare) ""
set ::RCE::toolVersionsMax(VCS) ""
set ::RCE::toolVersionsMax(VC_LP) ""
set ::RCE::toolVersionsMax(VC_SpyGlass) ""
set ::RCE::toolVersionsMax(VC_Static) ""
set ::RCE::toolVersionsMax(VcSpyGlass_SG_EngCouncil) ""
set ::RCE::toolVersionsMax(Verdi) ""
set ::RCE::toolVersionsMax(dc_shell) ""
set ::RCE::toolVersionsMax(fm_shell) ""
set ::RCE::toolVersionsMax(pt_shell) ""
set ::RCE::toolVersionsMax(synplicity) ""
set ::RCE::toolVersionsMax(vip:amba_svt) ""
set ::RCE::toolVersionsMax(vip:svt) ""

set ::RCE::verify_tool(FusionCompiler) 1
set ::RCE::verify_tool(ProtoCompiler) 1
set ::RCE::verify_tool(RTL_Architect) 1
set ::RCE::verify_tool(SpyGlass) 1
set ::RCE::verify_tool(SpyGlass_SG_EngCouncil) 1
set ::RCE::verify_tool(SpyGlass_SG_GuideWare) 1
set ::RCE::verify_tool(VCS) 1
set ::RCE::verify_tool(VC_LP) 1
set ::RCE::verify_tool(VC_SpyGlass) 1
set ::RCE::verify_tool(VC_Static) 1
set ::RCE::verify_tool(VcSpyGlass_SG_EngCouncil) 1
set ::RCE::verify_tool(Verdi) 1
set ::RCE::verify_tool(dc_shell) 1
set ::RCE::verify_tool(fm_shell) 1
set ::RCE::verify_tool(pt_shell) 1
set ::RCE::verify_tool(synplicity) 1
set ::RCE::verify_tool(vip:amba_svt) 1
set ::RCE::verify_tool(vip:svt) 1

set ::RCE::verify_tool_names(FusionCompiler) fc_shell
set ::RCE::verify_tool_names(ProtoCompiler) protocompiler
set ::RCE::verify_tool_names(RTL_Architect) rtl_shell
set ::RCE::verify_tool_names(SpyGlass) spyglass
set ::RCE::verify_tool_names(SpyGlass_SG_EngCouncil) ""
set ::RCE::verify_tool_names(SpyGlass_SG_GuideWare) ""
set ::RCE::verify_tool_names(VCS) vcs
set ::RCE::verify_tool_names(VC_LP) vcstatic
set ::RCE::verify_tool_names(VC_SpyGlass) vcstatic
set ::RCE::verify_tool_names(VC_Static) vcstatic
set ::RCE::verify_tool_names(VcSpyGlass_SG_EngCouncil) ""
set ::RCE::verify_tool_names(Verdi) verdi
set ::RCE::verify_tool_names(cc) cc
set ::RCE::verify_tool_names(cc_hpux) cc
set ::RCE::verify_tool_names(cc_linux) cc
set ::RCE::verify_tool_names(cc_solaris) cc
set ::RCE::verify_tool_names(dc_shell) dc_shell
set ::RCE::verify_tool_names(fm_shell) fm_shell
set ::RCE::verify_tool_names(gcc) gcc
set ::RCE::verify_tool_names(gcc_hpux) gcc
set ::RCE::verify_tool_names(gcc_linux) gcc
set ::RCE::verify_tool_names(gcc_solaris) gcc
set ::RCE::verify_tool_names(pt_shell) pt_shell
set ::RCE::verify_tool_names(synplicity) synplify
set ::RCE::verify_tool_names(vip:amba_svt) vip:./vip/svt/amba_svt
set ::RCE::verify_tool_names(vip:svt) vip:./vip/svt/common

