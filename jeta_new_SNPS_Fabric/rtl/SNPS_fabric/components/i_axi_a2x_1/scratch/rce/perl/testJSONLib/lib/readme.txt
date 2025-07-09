#===============================================================================
# 2022.01
#===============================================================================
Add logcputime.pl

#===============================================================================
# Notes
#===============================================================================
NOTE: the shebang is a reuse-pragma which is configured when packaged in a
configurable filegroup in the corekit.
When testing locally here you need to run as follows

> perl logcputime.pl -json test.json -log 1234
