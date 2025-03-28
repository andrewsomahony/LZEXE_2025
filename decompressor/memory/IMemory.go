package memory

type IMemory[ADDRESS_TYPE any] interface {
	GetSize() uint64
	OutputByte(address ADDRESS_TYPE, byteValue byte) error
	OutputWord(address ADDRESS_TYPE, wordValue uint16) error
	OutputDWord(address ADDRESS_TYPE, dwordValue uint32) error
	OutputQWord(address ADDRESS_TYPE, qwordValue uint64) error

	InputByte(address ADDRESS_TYPE) (byte, error)
	InputWord(address ADDRESS_TYPE) (uint16, error)
	InputDWord(address ADDRESS_TYPE) (uint32, error)
	InputQWord(address ADDRESS_TYPE) (uint64, error)

	// Returns the memory as a byte array
	GetBytes() []byte
}
