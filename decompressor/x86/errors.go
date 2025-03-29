package x86

import "github.com/joomcode/errorx"

var (
	X86Errors = errorx.NewNamespace("x86errors")

	InvalidAddress = X86Errors.NewType("invalid_address")
)
