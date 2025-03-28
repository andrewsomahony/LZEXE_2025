package x86

// Represents a real mode memory address
type RealModeMemoryAddress struct {
	Segment uint16
	Offset uint16
}

// Converts between a real mode segment:offset address and a flat address used to access memory
func (real_mode_address *RealModeMemoryAddress) RealModeAddressToFlatAddress() uint32 {
	// Shift the segment by 4 bits (multiply by 16) and then add the offset to get the flat address
	return uint32(real_mode_address.Segment) << 4 + uint32(real_mode_address.Offset)
}
