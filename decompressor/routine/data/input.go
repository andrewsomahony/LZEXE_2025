package routine

import "github.com/andrewsomahony/LZEXE_2025/x86"

// This structure represents the input data that our decompression
// routine expects

type RoutineInputData struct {
	StartAddress x86.RealModeMemoryAddress
	Data []byte
}
