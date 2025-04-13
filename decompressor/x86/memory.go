package x86

import (
	"bytes"
	"encoding/binary"
)

const REAL_MODE_MEMORY_SIZE = 1 << 20

// Real mode can only store up to 1 MB (20 bit address space),
// so we can allocate it right as part of our struct
type realModeMemory struct {
	buffer [REAL_MODE_MEMORY_SIZE]byte
}

func (real_mode_memory *realModeMemory) GetSize() uint64 {
	// Return our memory size
	return uint64(len(real_mode_memory.buffer))
}

// Checks a flat address to make sure that it is within our bounds
// Also makes sure the address + the length fits within our bounds as well
func (real_mode_memory *realModeMemory) addressRangeIsValid(flat_address FlatAddress, length uint32) error {
	if flat_address >= FlatAddress(real_mode_memory.GetSize()) {
		// Return an invalid real mode address error
		return InvalidRealModeAddress.New("%d", flat_address)
	} else if flat_address + FlatAddress(length) > FlatAddress(real_mode_memory.GetSize()) {
		return InvalidRealModeAddress.New("%d + %d", flat_address, length)
	} else {
		// All good, we can return nil to indicate no error
		return nil
	}
}

// Utility method to get a memory slice from a real mode address and a length
// Checks to make sure the requested address is valid as well
func (real_mode_memory *realModeMemory) getMemorySlice(address RealModeMemoryAddress, length uint32) ([]byte, error) {
	// Create our flat address
	flat_address := address.ToFlatAddress()
	var memory_slice []byte

	// Check if our flat address is valid
	error := real_mode_memory.addressRangeIsValid(flat_address, length)

	// If our address is valid, we can get our memory slice
	if nil == error {
		memory_slice = real_mode_memory.buffer[flat_address:flat_address + FlatAddress(length)] 
	}

	// Return our slice or error
	return memory_slice, error
}

func (real_mode_memory *realModeMemory) OutputByte(address RealModeMemoryAddress, byteValue byte) error {
	memory_slice, error := real_mode_memory.getMemorySlice(address, 1)

  if nil == error {
  	// Address is valid, we can modify our slice
  	memory_slice[0] = byteValue
  }
	return error
}

func (real_mode_memory *realModeMemory) OutputWord(address RealModeMemoryAddress, wordValue uint16) error {
	memory_slice, error := real_mode_memory.getMemorySlice(address, 2)

	if nil == error {
		// x86 real mode uses little endian, so we need to do so as well
		binary.LittleEndian.PutUint16(memory_slice, wordValue)
	}

	// Return our error if we have one
	return error
}

func (real_mode_memory *realModeMemory) OutputDWord(address RealModeMemoryAddress, dwordValue uint32) error {
	// Although x86 real mode doesn't support DWORD, 
	// we still implement this to implement the entire interface
	memory_slice, error := real_mode_memory.getMemorySlice(address, 4)

	if nil == error {
		// x86 real mode uses little endian, so we need to do so as well
		binary.LittleEndian.PutUint32(memory_slice, dwordValue)
	}

	// Return our error if we have one
	return error
}
func (real_mode_memory *realModeMemory) OutputQWord(address RealModeMemoryAddress, qwordValue uint64) error {
	// Although x86 real mode doesn't support QWORD, 
	// we still implement this to implement the entire interface
	memory_slice, error := real_mode_memory.getMemorySlice(address, 8)

	if nil == error {
		// x86 real mode uses little endian, so we need to do so as well
		binary.LittleEndian.PutUint64(memory_slice, qwordValue)
	}

	// Return our error if we have one
	return error
}

func (real_mode_memory *realModeMemory) InputByte(address RealModeMemoryAddress) (byte, error) {
	memory_slice, error := real_mode_memory.getMemorySlice(address, 1)
	var return_byte byte

	if nil == error {
		return_byte = memory_slice[0]
	}

	return return_byte, error
}
func (real_mode_memory *realModeMemory) InputWord(address RealModeMemoryAddress) (uint16, error) {
	memory_slice, error := real_mode_memory.getMemorySlice(address, 2)
	var input_word uint16

	if nil == error {
		// Perform our read, using little endian as that's what x86 uses
		binary.Read(bytes.NewReader(memory_slice), binary.LittleEndian, &input_word)
	}

	return input_word, error
}
func (real_mode_memory *realModeMemory) InputDWord(address RealModeMemoryAddress) (uint32, error) {
	memory_slice, error := real_mode_memory.getMemorySlice(address, 4)
	var input_dword uint32

	if nil == error {
		// Perform our read, using little endian as that's what x86 uses
		binary.Read(bytes.NewReader(memory_slice), binary.LittleEndian, &input_dword)
	}

	return input_dword, error
}
func (real_mode_memory *realModeMemory) InputQWord(address RealModeMemoryAddress) (uint64, error) {
	memory_slice, error := real_mode_memory.getMemorySlice(address, 8)
	var input_qword uint64

	if nil == error {
		// Perform our read, using little endian as that's what x86 uses
		binary.Read(bytes.NewReader(memory_slice), binary.LittleEndian, &input_qword)
	}

	return input_qword, error
}

// Clone our buffer and return it
func (real_mode_memory *realModeMemory) GetBytes() []byte {
	// Allocate a new array the same size as our memory buffer
	return_value := make([]byte, real_mode_memory.GetSize())
	// Copy our buffer into our return value
	copy(return_value, real_mode_memory.buffer[:])

	// Return our new array
	return return_value
}



