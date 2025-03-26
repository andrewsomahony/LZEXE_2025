package x86

import (
	"github.com/andrewsomahony/LZEXE_2025/memory"
)

type RealModeEnvironment struct {
	Memory memory.IMemory[RealModeMemoryAddress]
}





