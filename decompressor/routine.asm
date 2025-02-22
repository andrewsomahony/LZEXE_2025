
;Diagram of RAM after all data has been moved into place and decompression has begun
;Direction of addresses points down, so higher up in the diagram is a LOWER address
;in RAM

; -------------------------
; |
; |   Compressed data
; |   Decompression routine header
; |   Decompression routine code
; |   Compressed relocation table
; |
; -------------------------
; -------------------------
; |
; |
; |
; |
; |
; |  Decompressed Data?
; |
; |
; |
; |
; |
; -------------------------
; -------------------------
; |
; |
; |
; |   Compressed Data
; |
; |
; |
; -------------------------
; -------------------------
; |
; |
; |   Decompression Routine
; |
; |
; -------------------------

;    LZEXE Header:
;    All values are read as little endian, as this was designed to run
;   on the x86 family of processors

;    0x00 - 0x01: Original IP
;    0x02 - 0x03: Original CS
;    0x04 - 0x05: Original SP
;    0x06 - 0x07: Original SS
;    0x08 - 0x09: size of compressed data in paragraphs
;    0x0A - 0x0B: size of compressed data + size of uncompressed data + size of decompression routine information
;                  in paragraphs (I think?)
;    0x0C - 0x0D: size of decompression routine + header + footer in bytes

_lzexeHeader:

; 0x0000000000000000
_originalIP:
  dw 0x0000

; 0x0000000000000002
_originalCS:
  dw 0x0000

; 0x0000000000000004
_originalSP:
  dw 0x0080

; 0x0000000000000006
_originalSS:
  dw 0x160C

; 0x0000000000000008
_sizeOfCompressedDataInParagraphs:
  dw 0x062D

; 0x000000000000000A
_sizeOfUncompressedDataInParagraphs:
  dw 0x0FF9

; 0x000000000000000C
_sizeOfDecompressionRoutine:
  dw 0x0182

; This method moves the decompression routine as high as possible in RAM, to make room
; for the compressed data as well as the decompressed data

_moveDecompressionRoutine:
; Push the ES register to the stack
; DOS starts a program with the address to the 256-byte PSP (Program Segment Prefix)
; in both the DS and ES registers.  We need to use this later when we have decompressed
; our final image, so we save it to be popped when we are done decompressing

; 0x000000000000000e:  06 
                                       push      es

; Push the value of whatever code segment we were loaded at
; 0x000000000000000f:  0E                
                                       push      cs

; Pop the code segment value into our data segment
; 0x0000000000000010:  1F
                                       pop       ds

; Load how many bytes we are going to move for our decompression routine
; 0x0000000000000011:  8B 0E 0C 00       
                                       mov       cx, word [_sizeOfDecompressionRoutine]

; The size doubles as the address of the last byte + 1, so we can place it in our source
; and destination registers in preparation for our move
; 0x0000000000000015:  8B F1            
                                       mov       si, cx

; Decrement our source register by 1, as we are loading into this memory address, so it is
; our byte count minus 1, as we are zero-indexed
; 0x0000000000000017:  4E
                                       dec       si

; Load our destination register with our source register, as we are using 2 different segment
; registers to represent a full address in x86 Real Mode
; 0x0000000000000018:  89 F7
                                       mov       di, si

; Load our data segment (currently equal to our code segment) into bx
; 0x000000000000001a:  8C DB
                                       mov       bx, ds

; Add the size of our uncompressed data to bx, as the segment address already is at the end of the loaded image,
; which is the compressed data and the decompression routine, so we already have the size of the compressed data
; ready to go
; 0x000000000000001c:  03 1E 0A 00
                                       add       bx, word [_sizeOfUncompressedDataInParagraphs]

; Load our destination segment with bx, which is where we are moving our decompression routine to
; 0x0000000000000020:  8E C3            
                                       mov       es, bx

; Set our direction flag, which means that every time we have a moves instruction, the registers in
; question will be DECREMENTED as we are loading our routine backwards to front
; 0x0000000000000022:  FD                
                                       std

; Copy our compression routine and all its data from ds:si (which is our current code segment) to
; es:di, which is the code segment higher up in RAM
; 0x0000000000000023:  F3 A4             
                                       rep movsb ;byte es:[di], byte [si]

; bx still holds our destination segment, so push it to the stack in preparation for a FAR return
; 0x0000000000000025:  53                
                                       push      bx

; 2b is the offset of our decompression routine in the data that is moved, so set that to the offset
; that we will jump to as part of our FAR return
; 0x0000000000000026:  B8 2B 00          
                                       mov       ax, 0x2b

; Push our offset to the stack
; 0x0000000000000029:  50                
                                       push      ax

; Perform a FAR return, which will pop the IP (offset) from the stack, followed by the segment requested,
; and set the CS:IP registers to those values.
; This will, for readability, jump to _moveCompressedData down below :D
; 0x000000000000002a:  CB                
                                       retf

; This is the first method that runs as part of our decompression routine
; its job is to move the compressed data from where it was loaded to right below our decompression
; routine in RAM.  It has to potentially do this in 64k increments, due to the size of the registers
; available on Real Mode in x86 (16 bit)
; The direction flag is never cleared, so we are still moving our values backwards, from higher addresses
; to lower addresses in RAM
; Our registers are also not cleared, so BX still holds the value of our current code segment
_moveCompressedData:

; Load the size of our compressed data into BP
; We need to store this size because our initial CS in our DOS header
; is the size of our compressed data, as our routine is below it, but because we don't 
; know where in memory we are loaded without extra code, it's just quicker to use a
; header slot and read our pre-generated size into memory
; 0x000000000000002b:  2E 8B 2E 08 00    
                                       mov       bp, word cs:[_sizeOfCompressedDataInParagraphs]

; Move our data segment, currently the segment that we were loaded at, into DX
; 0x0000000000000030:  8C DA            
                                       mov       dx, ds

; This method moves a block of compressed data to its new location,
; specified by the ES segment register
; Inputs:
;   BP: Size of the data to move, in units of "paragraphs" (1 paragraph = 16 bytes)
;   DX: The segment we were loaded at, which is the start of the decompression routine   
_doMoveCompressedData:

; Move BP (current size of compressed data) into AX
; 0x0000000000000032:  89 E8           
                                       mov       ax, bp

; See if AX is greater than 4kb; as AX is in units of "paragraphs" (16 bytes each),
; we are seeing if the size of our compressed data is >64 kb
; 0x0000000000000034:  3D 00 10        
                                       cmp       ax, 0x1000

; If the size of our compressed data is less than 64kb, we can proceed and use it straight
; 0x0000000000000037:  76 03           
                                       jbe       _moveCompressedDataBlock

; If the size of our compressed data is > 64kb, then we need to load it in chunks, as we can
; only operate on 64kb at a time in x86 real mode
; 0x0000000000000039:  B8 00 10        
                                       mov       ax, 0x1000

; This method performs the actual movement of our compressed data block, whose size is
; given in the AX register
; Inputs:
;   AX: The amount of data to move, in units of "paragraphs" (1 paragraph = 16 bytes)
_moveCompressedDataBlock:

; For each loop, subtract the amount of data we are moving from BP, which is the register we are
; checking to see if we can continue the loop

; 0x000000000000003c:  29 C5             
                                       sub       bp, ax

; DS is equal to our initial data segment, so we want to subtract it by the amount we are moving to
; create our segment register for moving.
; 0x000000000000003e:  29 C2           
                                       sub       dx, ax

; bx is equal to our current code segment, which will be our destination segment for the compressed
; data.
; 0x0000000000000040:  29 C3             
                                       sub       bx, ax

; Our data segment (DS) is where our source data is coming from, which is DX, which is our initial load
; segment minus the size of data we are moving,
; so it has our compressed data right above where the decompression routine is
; 0x0000000000000042:  8E DA             
                                       mov       ds, dx

; The ES register is where the destination data will be, we set it to BX, which is our current code segment
; minus the size of data we are moving, so it will be placed right above the decompression routine in memory
; 0x0000000000000044:  8E C3             
                                       mov       es, bx

; Move 3 into our cl (cx low) register
; 0x0000000000000046:  B1 03             
                                       mov       cl, 3

; Convert # of paragraphs into # of words, as our loop will use a movesw instruction
; 0x0000000000000048:  D3 E0             
                                       shl       ax, cl

; Move the AX register into our COUNT register (CX)
; 0x000000000000004a:  89 C1             
                                       mov       cx, ax

; Convert the AX register into our memory offset by shifting left one more time, which, combined
; with the shift left of 3 earlier, effectively multiplies it by 4, yielding an address instead of
; # of paragraphs
; 0x000000000000004c:  D1 E0             
                                       shl       ax, 1

; As we are loading backwards, our first destination cannot be the size of data, but rather 2 bytes
; past it as we are using zero indexing, so decrement ax twice
; (The 2 dec's were obviously less memory than a sub ax, 2 were)
; 0x000000000000004e:  48                
                                       dec       ax
; 0x000000000000004f:  48             
                                       dec       ax

; Set our source offset register (SI) to ax
; 0x0000000000000050:  8B F0             
                                       mov       si, ax

; Set our destination offset register (DI) to ax
; 0x0000000000000052:  8B F8             
                                       mov       di, ax

; Repeat our move for the number of words we are moving, represented in the CX register
; 0x0000000000000054:  F3 A5             
                                       rep movsw ;word es:[di], word [si]

; Check if our main count register is 0, and if so, we are done!
; 0x0000000000000056:  09 ED             
                                       or        bp, bp

; If we still have more data to move, then jump back to the data size checker for another
; round of moving data.
; 0x0000000000000058:  75 D8             
                                       jne       _doMoveCompressedData

; We're done moving data!  Fall through to our decompression algorithm

; This method performs our actual decompression, by looping through the compressed data
; and running our algorithm
_decompressData:
; Clear our direction flag, so all movs and lods instructions increment the relevant
; registers as opposed to decrementing them
; 0x000000000000005a:  FC                
                                       cld

; The dx register, from the move above, is equal to the original location in memory that
; DOS loaded us at.  This is because we moved our data from there backwards, so we decremented
; until we hit the top of our original EXE data.  We will overwrite this data with the decompressed
; image, as we don't need any of the data there anymore as we have moved it to a higher RAM location

; Set our ES register to the DX register
; 0x000000000000005b:  8E C2             
                                       mov       es, dx

; Set our DS register to the BX register, which is at the start of our compressed data.
; 0x000000000000005d:  8E DB             
                                       mov       ds, bx

; Clear our SI register in preparation to fetch our decompressed data from the corresponding
; segment and location
; 0x000000000000005f:  31 F6             
                                       xor       si, si

; Clear our DI register in preparation to put our decompressed data at the corresponding
; segment and location
; 0x0000000000000061:  31 FF             
                                       xor       di, di

; Set our DX register to 16, which is our block size and a counter
; We operate on word values, so each bit represents one iteration of
; our loop
; 0x0000000000000063:  BA 10 00          
                                       mov       dx, 0x10

; Grab a word value from our compressed data
; 0x0000000000000066:  AD               
                                       lodsw     ;ax, word [si]

; Set our BP register to our current compressed word value
; 0x0000000000000067:  89 C5             
                                       mov       bp, ax

; This routine assumes a value in BP as well as a count in DX, and simply shifts
; the BP value 1 to the right to obtain the next bit to process, and decrements the
; dx register as well
_processCompressedDataLoop:
; Shift our BP register right by 1
; 0x0000000000000069:  D1 ED             
                                       shr       bp, 1

; Decrement our DX register, which we are using for this loop as a counter
; 0x000000000000006b:  4A                
                                       dec       dx

; If the zero flag is not set (DX != 0), then perform the jump
; This is important, as the DEC instruction will update the zero flag, which is what JNE checks,
; but ONLY the zero flag
; The updates to AX, BP, and DL are unrolled as having a routine and a CALL presumably is slower
; as it has to jump around and access the stack, while we want as few memory access as possible.

; 0x000000000000006c:  75 05             
                                       jne       _checkCompressedBitValue

; If DX is zero, then grab another word from the compressed data
; 0x000000000000006e:  AD                
                                       lodsw     ;ax, word [si]

; Set our BP register to our current compressed word value
; 0x000000000000006f:  89 C5             
                                       mov       bp, ax

; Set the DL register to 16, which is the size of our loop as we are operating on whole words
; Looks like dh is never set as we are always at 16 maximum for this loop, so we only need to set
; it once, at the top, and then we can just set dl for the rest of the iterations, saving 1 byte
; in the process
; 0x0000000000000071:  B2 10             
                                       mov       dl, 0x10

; Check the carry flag; if the carry flag is 0 then perform the jump
; The carry flag will be 0 if the bit at our current compressed word is 0
; If we got here from mov dl, 0x10, the carry flag may still be 0, and we have to operate on
; the final bit from our previous compressed word value
_checkCompressedBitValue:
; 0x0000000000000073:  73 03             
                                       jae       _process0Bit

; If the carry flag is 1, that means that our bit value in our compressed word was a 1,
; so we just simply set the byte at our destination address to the byte at our source address
; Anytime we have a 1 first, this is what happens as it indicates there is no compression of
; whatever byte we are currently pointing to and we can just move it straight and proceed
_1BitWithoutA0BitPrecedingIt:

; Load a byte from our compressed data into our destination buffer.  No compression at all
; 0x0000000000000075:  A4                
                                       movsb     ;byte es:[di], byte [si]

; Jump back to our loop increment, which is shifting our compressed value right by 1 to check
; the carry flag, and decrementing the DX register
; 0x0000000000000076:  EB F1             
                                       jmp       _processCompressedDataLoop

; If the carry flag is a 0, then we can proceed with the following code, this means that the value
; in our compressed word was 0, so we need to parse the information that we have

; This method is run whenever we run into a 0 bit with a 1 or nothing preceding it; the 0 indicates some
; sort of compression, so we need to proceed and see what it is
_process0Bit:

; Clear our CX register
; 0x0000000000000078:  31 C9             
                                       xor       cx, cx

; Get another bit from our compressed word register
; 0x000000000000007a:  D1 ED             
                                       shr       bp, 1

; Decrement our loop count variable
; 0x000000000000007c:  4A                
                                       dec       dx

; If our loop count is > 0, then we can jump over the following code
; 0x000000000000007d:  75 05             
                                       jne       0x84

; If our loop count is 0, then load another word from our compressed data
; 0x000000000000007f:  AD                
                                       lodsw     ;ax, word [si]

; Load up our BP register with the loaded compressed word
; 0x0000000000000080:  89 C5             
                                       mov       bp, ax

; Reset our loop counter
; 0x0000000000000082:  B2 10             
                                       mov       dl, 0x10

; If our carry flag is 1, that means the next bit after the 0 bit was a 1 and we can jump
; forwards
; 0x0000000000000084:  72 22             
                                       jb        0xa8

; If our carry flag is 0, then we have a 0 followed by a 0 in our compressed word
; Shift right and obtain the next bit in our compressed word
; This bit will be put into the carry flag and obtained down below, at _0BitFollowedBy0Bit
; 0x0000000000000086:  D1 ED             
                                       shr       bp, 1

; Decrement our loop counter
; 0x0000000000000088:  4A                
                                       dec       dx

; If our loop counter isn't 0, then jump forwards, otherwise, refresh our compressed word
; for the next pass
; 0x0000000000000089:  75 05             
                                       jne       _0BitFollowedBy0Bit

; If our loop counter is 0, then load another compressed word into AX
; 0x000000000000008b:  AD                
                                       lodsw     ;ax, word [si]

; Load AX into BP
; 0x000000000000008c:  89 C5             
                                       mov       bp, ax

; Reset our loop counter
; 0x000000000000008e:  B2 10             
                                       mov       dl, 0x10

; We have a 0 followed by a 0, so we need to rotate CX left by 1, which will take
; the carry flag value and put it in CX's LSB, and set the new carry flag to CX's
; original MSB
; We do this because we need both bits from our compressed stream to determine the length
; of the sequence that we will copy to our destination, so we need to obtain the carry flag,
; which is the bit that we obtained at instruction address 0x86 above. 
_0BitFollowedBy0Bit:

; Rotate our current CX left by 1; this will take the current carry flag and put it in
; CX's LSB, and set the new carry flag to the previous CX value's MSB
; CX is holding our current count, so by putting the CF in its LSB, we are setting the first
; bit of the count
; 0x0000000000000090:  D1 D1             
                                       rcl       cx, 1

; Shift our compressed word right by 1 to get our second count bit in the carry flag
; 0x0000000000000092:  D1 ED             
                                       shr       bp, 1

; Decrement our loop count
; 0x0000000000000094:  4A                
                                       dec       dx

; If DX is > 0, meaning we have more bits, then jump to another RCL
; 0x0000000000000095:  75 05             
                                       jne       0x9c

; If we have no bits left, get another compressed word and load it into AX
; 0x0000000000000097:  AD                
                                       lodsw     ;ax, word [si]

; Move AX into BP
; 0x0000000000000098:  89 C5             
                                       mov       bp, ax

; Reset our loop counter
; 0x000000000000009a:  B2 10             
                                       mov       dl, 0x10

; Rotate CX by 1 left, which will get the previous bit value from our compressed word,
; as it puts the current CF into the LSB
; This is putting our second count bit into CX
; 0x000000000000009c:  D1 D1             
                                       rcl       cx, 1

; Increment our carry flag
; 0x000000000000009e:  41                
                                       inc       cx

; Increment our carry flag
; 0x000000000000009f:  41                
                                       inc       cx

; Now we have the count of the number of bytes we want to copy into our destination
; in CX.  This count, if the 2 stream bits are both 1, and given the increments above,
; has a maximum of 5

; SI is holding a relative position in our destination buffer of a
; byte to use for a number of times equal to CX, so load it into AL
; This allows us to store an offset with max value of -256, but only
; store it in 1 byte.  Clever.
; 0x00000000000000a0:  AC                
                                       lodsb     ;al, byte [si]

; Sign extend our BX register as our relative position is negative
; 0x00000000000000a1:  B7 FF             
                                       mov       bh, 0xff
; Load our relative position into the low byte of BX
; 0x00000000000000a3:  8A D8             
                                       mov       bl, al

; Jump to our loop, which will load the byte at the relative position
; located at DI + BX in our destination buffer into our destination buffer
; for CX number of times.  This is the decompression at work!

; 0x00000000000000a5:  E9 13 00          
                                       jmp       _copyByteSequenceLoop

; We jump here when we have a 0 bit in our compressed word, followed by a 1 bit
_0BitFollowedBy1Bit:

; Load compressed data into AX
; This can serve as either both our offset and count, or just our offset
; 0x00000000000000a8:  AD                
                                       lodsw     ;ax, word [si]

; Load our AX register into BX
; 0x00000000000000a9:  8B D8             
                                       mov       bx, ax

; Set the low byte of CX to 3
; !!! Is the high byte still used?  I don't think so
; 0x00000000000000ab:  B1 03             
                                       mov       cl, 3

; Shift the high byte of BX (our compressed word) by 3 right, (divide it by 8)
; We do this because the count for this specific compression offset can be stored
; within the 16 bit value, which is another clever compression example

; Shift BH right by 3 to remove the compression count, if it exists
; 0x00000000000000ad:  D2 EF             
                                       shr       bh, cl

; Set the most significant 3 bits of BX to 1
; This serves to sign-extend the value that we shifted right, to produce
; a negative offset, which will serve as our fetch address
; 0x00000000000000af:  80 CF E0          
                                       or        bh, 0xe0

; See if the count for this compression is stored within the 16-bit value,
; within bits 8, 9, and 10
; 0x00000000000000b2:  80 E4 07         
                                       and       ah, 7

; If there is no count, then we need to jump to further process this compressed
; word
; 0x00000000000000b5:  74 0C             
                                       je        _checkForEndOr64kBoundaryOr8bitCount

; Move AH (our count) into our CX register
; 0x00000000000000b7:  88 E1             
                                       mov       cl, ah
; Increment our CX register
; 0x00000000000000b9:  41                
                                       inc       cx
; Increment our CX register
; 0x00000000000000ba:  41                
                                       inc       cx

; This is our decompression loop.  It takes the byte at the relative offset of BX
; from DI (our current decompressed buffer), and places it at our current DI position
; for CX iterations.  Note: DI gets incremented for a STOSB, so we are decompressing
; SEQUENCES of bytes as opposed to 1 repeating byte here
_copyByteSequenceLoop:

; Load the byte at our BX offset in our destination buffer into AL
; 0x00000000000000bb:  26 8A 01          
                                       mov       al, byte es:[bx + di]

; Store the byte in the AL register into our destination buffer, incrementing the
; DI pointer as well
; 0x00000000000000be:  AA                
                                       stosb     ;byte es:[di], al

; Loop for CX number of iterations
; 0x00000000000000bf:  E2 FA             
                                       loop      _copyByteSequenceLoop

; Jump all the way back to processing a new bit in our compressed word
; 0x00000000000000c1:  EB A6             
                                       jmp       _processCompressedDataLoop

; This routine checks to see if we are finished, or if we are near(?)
; the 64k boundary, in which case, we need to make modifications to our
; segment registers so that we don't loop back to the same address for
; our buffers, but rather make sure to increment the segment registers
; NOTE: This routine has a BX offset ready to go, so if it determines that we are
; ok, then we can use it and it jumps back to the decompression loop

_checkForEndOr64kBoundaryOr8bitCount:
; Load the next compressed byte in our buffer into AL
; This could be our "done" flag (=0), our "adjust" flag (=1),
; or a count of bytes for our sequence to copy over
; 0x00000000000000c3:  AC                
                                       lodsb     ;al, byte [si]

; Check if AL is 0
; 0x00000000000000c4:  08 C0             
                                       or        al, al

; If AL is 0, then we are done decompressing and can jump forwards to decompress
; our relocation table
; 0x00000000000000c6:  74 34             
                                       je        _decompressAndUpdateRelocationTable

; If AL is 1, then we need to jump forwards to the code that modifies our source and destination
; segments, as this represents a segment boundary indicator
; 0x00000000000000c8:  3C 01             
                                       cmp       al, 1

; If AL is 1, then we need to modify our segment registers
; 0x00000000000000ca:  74 05             
                                       je        0xd1

; If AL is not 1, then it is greater than 1, and it is a count of bytes that
; are associated with the BX offset that we calculated before jumping here.
; Our BX offset is a longer value than with the other decompression loop BX 
; value (which is only max -256 bytes), so we can verify that we don't need 
; to make any modifications to our segment registers and can simply proceed as is

; Move AL into CL
; 0x00000000000000cc:  88 C1             
                                       mov       cl, al

; Increment our CX register
; Note, we only do this once, as we know we have a minumum value of 2 in CX, while
; the minimum sequence count is 3, so we just increment once to hit the minimum
; 0x00000000000000ce:  41                
                                       inc       cx

; Jump to our decompression loop now that we have our CX register set
; 0x00000000000000cf:  EB EA          
                                       jmp       _copyByteSequenceLoop

; We want to shift our segments by 8 KB, as our maximum offset size for
; decompression into our destination buffer is 0x2000, which is 8 KB.
; Therefore, when we detect we are about to cross this boundary in
; the compressed data, we shift our ES and DS by 8 KB to allow our offsets
; to continue to work

_modifySegmentRegisters:

; First shift ES:DI by 8 KB

; Load our DI register into BX
; 0x00000000000000d1:  89 FB             
                                       mov       bx, di
; Divide DI by 16 and get the remainder (modulus 16)
; 0x00000000000000d3:  83 E7 0F          
                                       and       di, 0xf
; Add 8k to DI
; 0x00000000000000d6:  81 C7 00 20      
                                       add       di, 0x2000
; Set our CL to 4
; 0x00000000000000da:  B1 04             
                                       mov       cl, 4
; Shift our BX register right by 4 (divide by 16)
; BX is equal to the current DI, which is our destination buffer pointer
; 0x00000000000000dc:  D3 EB             
                                       shr       bx, cl

; Move our ES register into AX
; 0x00000000000000de:  8C C0             
                                       mov       ax, es

; Add BX to AX
; AX is our current ES register
; BX is our current DI register divided by 16 (16-byte boundary)
; 0x00000000000000e0:  01 D8             
                                       add       ax, bx

; Subtract 512 from AX
; As we have a segment register value in AX, we treat it as such,
; so this, when the MMU works with the register, will actually be
; subtracting by 8k
; 0x00000000000000e2:  2D 00 02          
                                       sub       ax, 0x200
; Move AX back into ES
; 0x00000000000000e5:  8E C0             
                                       mov       es, ax

; Move SI into BX
; 0x00000000000000e7:  89 F3             
                                       mov       bx, si

; Get our 16 byte modulus of our current SI register
; 0x00000000000000e9:  83 E6 0F          
                                       and       si, 0xf

; Divide our BX register by 16 (CL still set from above)
; 0x00000000000000ec:  D3 EB             
                                       shr       bx, cl

; Move our DS register into AX
; 0x00000000000000ee:  8C D8             
                                       mov       ax, ds

; Add BX (our shifted SI value) to AX
; 0x00000000000000f0:  01 D8             
                                       add       ax, bx

; Move AX back into the DS register
; 0x00000000000000f2:  8E D8             
                                       mov       ds, ax

; Jump all the way back to processing our compressed data
; The data that yielded this call to begin with was only designed
; to yield this call, so we need to refill our registers and
; counts from scratch
; 0x00000000000000f4:  E9 72 FF          
                                       jmp       _processCompressedDataLoop

; A little Easter Egg/CTF target :D
; These are the initials of the creator of LZEXE, Fabrice Bellard
; Also the first ever flag I found, technically, when I was giving
; this code a crack in 2020
; 0x00000000000000f7:  2A                "*"
; 0x00000000000000f8:  46                "F"
; 0x00000000000000f9:  41                "A"
; 0x00000000000000fa:  42                "B"
; 0x00000000000000fb:  2A                "*"

; This uses some sort of offset decompression, which, instead of storing
; 2 16-bit values for each entry, stores an offset from the current entry
; to the next entry
_decompressAndUpdateRelocationTable:
; Push our current code segment (the decompression code)
; 0x00000000000000fc:  0E                
                                       push      cs
; Set our DS to our current CS
; 0x00000000000000fd:  1F                
                                       pop       ds
; 0x158 is the offset to the compressed relocation table, located
; at the end of the decompression code
; 0x00000000000000fe:  BE 58 01          
                                       mov       si, 0x158

; Pop our PSP (Program Segment Prefix) address into BX
; We pushed this value right at the start of our program
; 0x0000000000000101:  5B                
                                       pop       bx

; Offset BX by 16 bytes to get to the actual start of the program code
; NOTE: The PSP is 256 bytes large, but as we have a segment address in
; BX, we are treating it as such, and can therefore only offset by 16,
; as the x86 MMU will multiply it by 16, yielding 256.
; This took ages for me to realize :D
; 0x0000000000000102:  83 C3 10          
                                       add       bx, 0x10

; Set our DX register to the start of the program code (shifted right by 16)
; 0x0000000000000105:  89 DA             
                                       mov       dx, bx
; Set our DI register to 0
; 0x0000000000000107:  31 FF             
                                       xor       di, di

; This method takes the next offset from our compressed relocation table and makes
; the necessary additions to our destination pointer to add our load offset to it
_loadRelocationTableEntry:
; Load a byte from our relocation table data into AL
; 0x0000000000000109:  AC                
                                       lodsb     ;al, byte [si]
; See if AL is 0 by OR'ing it with itself
; 0x000000000000010a:  08 C0             
                                       or        al, al
; If AL is 0, then we need to get a 16-bit value as our next relocation table
; entry offset, so jump down to that handler
; The
; 0x000000000000010c:  74 16             
                                       je        _processRelocationTable16bitEntry

; We don't have a 16-bit value, so we can use our 8-bit value as-is

; Set our AH register to 0
; We have an 8-bit offset, so we don't need the AH register and can then fall through
; to processing the offset that we have in AX
; 0x000000000000010e:  B4 00             
                                       mov       ah, 0

_processRelocationTableOffset:
; Add our AX value (as AH is 0) to our DI register
; 0x0000000000000110:  01 C7             
                                       add       di, ax

; Move our DI register to AX
; 0x0000000000000112:  8B C7             
                                       mov       ax, di

; Get the 16-byte modulus of our DI register
; 0x0000000000000114:  83 E7 0F          
                                       and       di, 0xf

; Move 4 into our CL register
; 0x0000000000000117:  B1 04             
                                       mov       cl, 4

; Shift our AX register right by 4 (divide by 16)
; 0x0000000000000119:  D3 E8             
                                       shr       ax, cl

; Add our AX register to our DX register
; DX currently is the start segment of our original program's code,
; and AX is our shifted DI register
; 0x000000000000011b:  01 C2             
                                       add       dx, ax

; Set our ES segment register to DX
; 0x000000000000011d:  8E C2             
                                       mov       es, dx

; Add our BX register (load offset) to the relocation entry pointed to
; by ES:DI, which we have set with the code above
; 0x000000000000011f:  26 01 1D          
                                       add       word es:[di], bx

; Jump back to process another relocation entry
; 0x0000000000000122:  EB E5             
                                       jmp       _loadRelocationTableEntry

; We have a 0 value for our flag byte

_processRelocationTable16bitEntry:
; If our relocation flag is 0, load the next word into our AX register
; 0x0000000000000124:  AD                
                                       lodsw     ;ax, word [si]
; OR AX with itself to see if it's equal to 0
; 0x0000000000000125:  09 C0             
                                       or        ax, ax
; If AX is nonzero, then jump down to the AX checker
; 0x0000000000000127:  75 08             
                                       jne       0x131

; If AX is 0, then add 0xFFF to our DX value.
; DX being the current relocation table location in our decompressed
; code
; 0x0000000000000129:  81 C2 FF 0F       
                                       add       dx, 0xfff

; Move the DX register into the ES register
; !!! Why is this ever needed, as we are setting the ES register before
; !!! modifying relocation table entries?
; !!! I don't think that this is required, as we are setting ES before
; !!! modifying a relocation table entry, maybe it was left over from
; !!! a previous version that was trying to reduce the number of sets
; !!! of ES?
; 0x000000000000012d:  8E C2             
                                       mov       es, dx

; Jump back to processing
; 0x000000000000012f:  EB D8             
                                       jmp       _loadRelocationTableEntry

; See if our AX register is 1, if so, then we are done
; 0x0000000000000131:  3D 01 00          
                                       cmp       ax, 1

; If our AX register is not equal to 1, then jump to our offset handling,
; as the AX register is storing an offset
; 0x0000000000000134:  75 DA             
                                       jne       _processRelocationTableOffset

; This method loads the original CS/IP and SS/SP from our header and sets
; the corresponding registers, before jumping to the CS:IP value, which is the start
; of the original program
_startDecompressedProgram:
; Set AX to our BX register, which is the address of the start
; of our program code (in paragraphs)
; 0x0000000000000136:  8B C3             
                                       mov       ax, bx

; Move our original stack pointer into our DI register
; 0x0000000000000138:  8B 3E 04 00       
                                       mov       di, word [_originalSP]

; Move our original stack segment into our SI register
; 0x000000000000013c:  8B 36 06 00     
                                       mov       si, word [_originalSS]

; Offset our original stack segment by our code start address
; 0x0000000000000140:  01 C6             
                                       add       si, ax

; Offset our original code segment by our code start address
; 0x0000000000000142:  01 06 02 00       
                                       add       word [_originalCS], ax

; Subtract 16 from our code start address to get back to our original load
; address (and the PSP)
; 0x0000000000000146:  2D 10 00          
                                       sub       ax, 0x10

; Set our DS register to the start of the PSP
; 0x0000000000000149:  8E D8             
                                       mov       ds, ax

; Set our ES register to the start of the PSP
; 0x000000000000014b:  8E C0             
                                       mov       es, ax

; Set our BX register to 0
; 0x000000000000014d:  31 DB             
                                       xor       bx, bx

; Disable interrupts as we are about to set our stack registers
; 0x000000000000014f:  FA                
                                       cli

; Set our stack segment to the SI regis+ter
; 0x0000000000000150:  8E D6             
                                       mov       ss, si
; Set our stack pointer to the DI register
; 0x0000000000000152:  8B E7             
                                       mov       sp, di

; Enable interrupts
; 0x0000000000000154:  FB                
                                       sti

; Jump to the 4 byte location described at the address cs:bx
; BX is 0, and at that address are our original IP and our original
; CS, which are then used to set CS and IP by the LJMP instruction,
; leading us to our original program, all decompressed and relocated
; and ready to go!

; 0x0000000000000155:  2E FF 2F          
                                       jmp      [cs:bx]

; We're done!

; Compressed original relocation table

; 0x0000000000000158:
; 01 DD 32 00 99 20 24 30 30 3A 3A 44 44 4E 00 1A 01 1E 28 28 32 32 46 19 20 00 34 2E 00 23 02 00 59 01 C3 43 00 09 02 00 01 00

