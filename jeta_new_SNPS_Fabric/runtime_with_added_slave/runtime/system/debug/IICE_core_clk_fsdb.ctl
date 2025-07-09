wvAddAllSignals
wvSetWindowTimeUnit 1 ns
wvSetMarker -name "trigger" 163840.000000 ID_RED5 line_solid
wvJumpToolbarUserMarker -name "trigger"
wvSelectSignal -delim . haps_soc.identify_cycle
wvSetPosition {(G1 0)}
wvMoveSelected
wvSelectSignal -delim . haps_soc.identify_sampleclock
wvSetPosition {(G1 1)}
wvMoveSelected
