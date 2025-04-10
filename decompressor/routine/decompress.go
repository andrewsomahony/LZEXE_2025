package routine

import (
	routine "github.com/andrewsomahony/LZEXE_2025/decompressor/routine/data"
	"github.com/andrewsomahony/LZEXE_2025/decompressor/x86"
)

// Decompresses LZEXE compressed data, represented in the input data
func Decompress(inputData routine.RoutineInputData) routine.RoutineOutputData {
	// Create a new decompression routine environment to store our result
	environment := x86.NewRealModeEnvironment()

	// We first need to check our data header, as there is a signature there

	// We can checksum our assembly language routine, namely the decompression routine
	// movement code, and the decompression routine itself, to make sure that we are 
	// working with an LZEXE-encoded file

	// We don't need to move any data around like the routine does, so once we are comfortable
	// that we are working with an LZEXE file, we can simply find our compressed data using 
	// our header information and start running through it

	// Our relocation table is stored in the decompression code, right at the end at a fixed
	// offset, so we know how to get there as well

	// Return our result
	return routine.RoutineOutputData{}
}
