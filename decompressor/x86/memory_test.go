package x86

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

// Function to allocate real mode memory for tests
func allocateNewRealModeMemory() realModeMemory {
	return realModeMemory{};
}

// Generic type to represent an input function
type InputFunctionType[VALUE_TYPE any] func(address RealModeMemoryAddress) (VALUE_TYPE, error)
// Generic type to represent an output function
type OutputFunctionType[VALUE_TYPE any] func(address RealModeMemoryAddress, value VALUE_TYPE) error

// Generic method to run a test on real mode memory with a specified value and IO functions
func runTest[VALUE_TYPE any](testing_handle *testing.T, valueToUse VALUE_TYPE, inputFunction InputFunctionType[VALUE_TYPE], outputFunction OutputFunctionType[VALUE_TYPE]) {
	valid_address := RealModeMemoryAddress{
		Segment: 4,
		Offset: 4,
	}
	invalid_address := RealModeMemoryAddress{
		Segment: 1 << 20,
		Offset: 1 << 16 - 1,
	}

	// Write to our invalid address
	output_error := outputFunction(invalid_address, valueToUse)
	assert.NotNil(testing_handle, output_error)

	// Write to our valid address
	output_error = outputFunction(valid_address, valueToUse)
	assert.Nil(testing_handle, output_error)

	// Try to read from our valid address
	input_byte, input_error := inputFunction(valid_address)
	// Make sure we don't have an error
	assert.Nil(testing_handle, input_error)
	// Make sure our input byte is the same as the one we wrote
	assert.Equal(testing_handle, valueToUse, input_byte)
}

func TestRealModeMemorySize(testing_handle *testing.T) {
	real_mode_memory := allocateNewRealModeMemory()

	assert.Equal(testing_handle, real_mode_memory.GetSize(), uint64(1 << 20))
}

func TestRealModeMemoryByteIO(testing_handle *testing.T) {
	// Create our real mode memory
	real_mode_memory := allocateNewRealModeMemory()

	runTest(testing_handle, byte(32), real_mode_memory.InputByte, real_mode_memory.OutputByte)
}

func TestRealModeMemoryWordIO(testing_handle *testing.T) {
	// Create our real mode memory
	real_mode_memory := allocateNewRealModeMemory()

	runTest(testing_handle, uint16(0xBEEF), real_mode_memory.InputWord, real_mode_memory.OutputWord)
}

func TestRealModeMemoryDwordIO(testing_handle *testing.T) {
	// Create our real mode memory
	real_mode_memory := allocateNewRealModeMemory()

	runTest(testing_handle, uint32(0xDEADBEEF), real_mode_memory.InputDWord, real_mode_memory.OutputDWord)
}

func TestRealModeMemoryQwordIO(testing_handle *testing.T) {
	// Create our real mode memory
	real_mode_memory := allocateNewRealModeMemory()

	runTest(testing_handle, uint64(0xFEEDDEADBEEFAAAA), real_mode_memory.InputQWord, real_mode_memory.OutputQWord)
}

func TestRealModeMemoryBytes(testing_handle *testing.T) {
	// Create our real mode memory
	real_mode_memory := allocateNewRealModeMemory()

	byte_to_use := byte(65)
	address_to_use := RealModeMemoryAddress{
		Segment: 4,
		Offset: 0,
	}

	// Write a byte to our memory
	real_mode_memory.OutputByte(address_to_use, byte_to_use)

	// Get a copy of our memory

	memory_buffer := real_mode_memory.GetBytes()

	// Make sure that we have our written value in our memory bytes
	assert.Equal(testing_handle, memory_buffer[address_to_use.ToFlatAddress()], byte_to_use)

	// Write a value to our memory bytes
	buffer_address := RealModeMemoryAddress{
		Segment: 6,
		Offset: 4,
	}
	buffer_byte := byte(32)

	memory_buffer[buffer_address.ToFlatAddress()] = buffer_byte

	// Make sure our actual memory doesn't have this written byte

	real_mode_memory_byte, real_mode_memory_error := real_mode_memory.InputByte(buffer_address)
	// Make sure we don't have an input error
	assert.Nil(testing_handle, real_mode_memory_error)

	// Make sure our real mode byte is not equal to our buffer byte
	assert.NotEqual(testing_handle, real_mode_memory_byte, buffer_byte)
}
