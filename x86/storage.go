package x86

// Real mode can only store up to 1 MB (20 bit address space),
// so we can allocate it right as part of our struct
type realModeMemory struct {
	buffer [1 << 20]byte
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

// Returns the memory as a byte array
func (real_mode_memory *realModeMemory) GetBytes() ([]byte, uint64) {
	panic("not implemented") // TODO: Implement
}



