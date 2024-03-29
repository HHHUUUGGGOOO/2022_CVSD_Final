// -----------------------------------------------------------------------------
// Simulation: Final_polar_decoder
// -----------------------------------------------------------------------------

// define files
// -----------------------------------------------------------------------------
//../00_TESTBED/define.v

// testbench
// -----------------------------------------------------------------------------
../00_TESTBED/testfixture.v
../00_TESTBED/LLR_mem.v
../00_TESTBED/DEC_mem.v

// design files
// -----------------------------------------------------------------------------
./polar_decoder.v
./ProcessElement.v
./P_node.v
./reliability_ROM.v
