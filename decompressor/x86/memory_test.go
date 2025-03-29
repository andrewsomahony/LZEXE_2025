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

	output_error := real_mode_memory.OutputByte(address_to_use, byte_to_use)
	assert.Nil(testing_handle, output_error)

	input_byte, input_error := real_mode_memory.InputByte(address_to_use)
	assert.Nil(testing_handle, input_error)
	assert.Equal(testing_handle, input_byte, byte_to_use)
}
