package x86

import (
	"github.com/andrewsomahony/LZEXE_2025/decompressor/environment"
	"github.com/andrewsomahony/LZEXE_2025/decompressor/memory"
)

type RealModeEnvironment struct {
	memory memory.IMemory[RealModeMemoryAddress]
	environment.IDecompressorEnvironment[RealModeMemoryAddress]
}

func NewRealModeEnvironment() *RealModeEnvironment {
	return &RealModeEnvironment{
		memory: &realModeMemory{},
	}
}

func (real_mode_environment *RealModeEnvironment) GetMemory() memory.IMemory[RealModeMemoryAddress] {
	return real_mode_environment.memory
}

