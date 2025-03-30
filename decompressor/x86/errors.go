package x86

import "github.com/joomcode/errorx"

var (
	X86Errors = errorx.NewNamespace("x86errors")

	InvalidRealModeAddress = X86Errors.NewType("invalid_real_mode_address")
)
