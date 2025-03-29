package x86

// Represents a real mode memory address
type RealModeMemoryAddress struct {
	Segment uint32
	Offset uint16
}

type FlatAddress uint32

// Converts between a real mode segment:offset address and a flat address used to access memory
func (real_mode_address *RealModeMemoryAddress) RealModeAddressToFlatAddress() FlatAddress {
	// Shift the segment by 4 bits (multiply by 16) and then add the offset to get the flat address
	return FlatAddress(real_mode_address.Segment << 4 + uint32(real_mode_address.Offset))
}
