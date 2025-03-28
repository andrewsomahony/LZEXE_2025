package x86

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestRealModeMemoryByteIO(testing_handle *testing.T) {
	byte_to_use := byte(32)

	address_to_use := RealModeMemoryAddress{
		Segment: 4,
		Offset: 4,
	}

	real_mode_memory := realModeMemory{}

	error := real_mode_memory.OutputByte(address_to_use, byte_to_use)
	assert.Nil(testing_handle, error)
}
