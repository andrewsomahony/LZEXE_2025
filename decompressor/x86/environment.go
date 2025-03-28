package x86

import (
	"github.com/andrewsomahony/LZEXE_2025/memory"
)

type RealModeEnvironment struct {
	memory memory.IMemory[RealModeMemoryAddress]
}

func (real_mode_environment *RealModeEnvironment) GetMemory() memory.IMemory[RealModeMemoryAddress] {
	return real_mode_environment.memory
}

