package x86

// Real mode can only store up to 1 MB (20 bit address space),
// so we can allocate it right as part of our struct
type realModeMemory struct {
	buffer [1 << 20]byte
}

func (real_mode_memory *realModeMemory) GetSize() uint64 {
	// Return our memory size
	return 1 << 20
}

func (real_mode_memory *realModeMemory) OutputByte(address RealModeMemoryAddress, byteValue byte) error {
	panic("not implemented") // TODO: Implement
}
func (real_mode_memory *realModeMemory) OutputWord(address RealModeMemoryAddress, wordValue uint16) error {
	panic("not implemented") // TODO: Implement
}
func (real_mode_memory *realModeMemory) OutputDWord(address RealModeMemoryAddress, dwordValue uint32) error {
	panic("not implemented") // TODO: Implement
}
func (real_mode_memory *realModeMemory) OutputQWord(address RealModeMemoryAddress, qwordValue uint64) error {
	panic("not implemented") // TODO: Implement
}
func (real_mode_memory *realModeMemory) InputByte(address RealModeMemoryAddress) (byte, error) {
	panic("not implemented") // TODO: Implement
}
func (real_mode_memory *realModeMemory) InputWord(address RealModeMemoryAddress) (uint16, error) {
	panic("not implemented") // TODO: Implement
}
func (real_mode_memory *realModeMemory) InputDWord(address RealModeMemoryAddress) (uint32, error) {
	panic("not implemented") // TODO: Implement
}
func (real_mode_memory *realModeMemory) InputQWord(address RealModeMemoryAddress) (uint64, error) {
	panic("not implemented") // TODO: Implement
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



