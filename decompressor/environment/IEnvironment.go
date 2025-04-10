package environment

import (
	"github.com/andrewsomahony/LZEXE_2025/decompressor/memory"
)

type IDecompressorEnvironment[ADDRESS_TYPE any] interface {
	GetMemory() memory.IMemory[ADDRESS_TYPE]
}
