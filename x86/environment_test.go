package x86

import (
	"testing"
	"github.com/stretchr/testify/assert"
)

func TestRealModeEnvironmentByteIO(testing_handle *testing.T) {
	real_mode_environment := RealModeEnvironment{
		Memory: &realModeMemory{},
	}

	address_to_test := RealModeMemoryAddress{
		Segment: 4,
		Offset: 4,
	}
	real_mode_environment.Memory.OutputByte(address_to_test, byte(32))

	input_byte, _ := real_mode_environment.Memory.InputByte(address_to_test)
	assert.Equal(testing_handle, byte(32), input_byte)
}
