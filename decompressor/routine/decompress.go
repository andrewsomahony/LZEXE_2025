package routine

import (
	"github.com/andrewsomahony/LZEXE_2025/environment"
	routine "github.com/andrewsomahony/LZEXE_2025/routine/data"
	"github.com/andrewsomahony/LZEXE_2025/x86"
)

// This struct represents our decompression routine

type decompressionRoutine struct {
	environment environment.IDecompressorEnvironment[x86.RealModeMemoryAddress]
}

// Decompresses LZEXE compressed data, represented in the input data
func Decompress(inputData *routine.RoutineInputData) routine.RoutineOutputData {
	// Create a new decompression routine environment
	environment := x86.CreateNewRealModeEnvironment()

	// Create our decompression routine with the address of our environment
	// to represent the required interface
	decompression_routine := decompressionRoutine{
		environment: &environment,
	}

	// Return our result
	return routine.RoutineOutputData{}
}
