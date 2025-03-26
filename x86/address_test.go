package x86

import (
	"github.com/stretchr/testify/assert"
	"testing"
)

func TestConvertRealModeMemoryAddressToFlatAddress(testing_handle *testing.T) {
	address := RealModeMemoryAddress{
		Segment: 8,
		Offset: 16,
	}

	assert.Equal(testing_handle, uint32(144), address.RealModeAddressToFlatAddress())
}
