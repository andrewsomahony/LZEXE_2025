package routine

import "github.com/andrewsomahony/LZEXE_2025/decompressor/x86"

// This struct represents the data that we expect for our decompression
// routine output.  It essentially provides the information needed to
// re-assemble the original EXE

type RoutineOutputData struct {
	// The start address of our code execution
	CodeStartAddress x86.RealModeMemoryAddress
	// Our initial stack address
	StackStartAddress x86.RealModeMemoryAddress
	// Our relocation table, which consists of segment:offset
	// pairs and is used to relocate areas in the final EXE where
	// a segment address is present.  We don't need to relocate 
	// offsets as they stay the same within their respective segments.
	RelocationTable []x86.RealModeMemoryAddress
	// Our decompressed executable code
	ExecutableCode []byte
}
