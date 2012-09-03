/** @file
  This module contains EBC support routines that are customized based on
  the target x64 processor.

Copyright (c) 2006 - 2010, Intel Corporation. All rights reserved.<BR>
This program and the accompanying materials
are licensed and made available under the terms and conditions of the BSD License
which accompanies this distribution.  The full text of the license may be found at
http://opensource.org/licenses/bsd-license.php

THE PROGRAM IS DISTRIBUTED UNDER THE BSD LICENSE ON AN "AS IS" BASIS,
WITHOUT WARRANTIES OR REPRESENTATIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED.

**/

#include "EbcInt.h"
#include "EbcExecute.h"

//
// NOTE: This is the stack size allocated for the interpreter
//       when it executes an EBC image. The requirements can change
//       based on whether or not a debugger is present, and other
//       platform-specific configurations.
//
#define VM_STACK_SIZE   (1024 * 8)
#define EBC_THUNK_SIZE  64

#define STACK_REMAIN_SIZE (1024 * 4)


/**
  Pushes a 64 bit unsigned value to the VM stack.

  @param VmPtr  The pointer to current VM context.
  @param Arg    The value to be pushed.

**/
VOID
PushU64 (
  IN VM_CONTEXT *VmPtr,
  IN UINT64     Arg
  )
{
  //
  // Advance the VM stack down, and then copy the argument to the stack.
  // Hope it's aligned.
  //
  VmPtr->Gpr[0] -= sizeof (UINT64);
  *(UINT64 *) VmPtr->Gpr[0] = Arg;
  return;
}


/**
  Begin executing an EBC image. The address of the entry point is passed
  in via a processor register, so we'll need to make a call to get the
  value.

  This is a thunk function. Microsoft x64 compiler only provide fast_call
  calling convention, so the first four arguments are passed by rcx, rdx,
  r8, and r9, while other arguments are passed in stack.

  @param  Arg1                  The 1st argument.
  @param  Arg2                  The 2nd argument.
  @param  Arg3                  The 3rd argument.
  @param  Arg4                  The 4th argument.
  @param  Arg5                  The 5th argument.
  @param  Arg6                  The 6th argument.
  @param  Arg7                  The 7th argument.
  @param  Arg8                  The 8th argument.
  @param  Arg9                  The 9th argument.
  @param  Arg10                 The 10th argument.
  @param  Arg11                 The 11th argument.
  @param  Arg12                 The 12th argument.
  @param  Arg13                 The 13th argument.
  @param  Arg14                 The 14th argument.
  @param  Arg15                 The 15th argument.
  @param  Arg16                 The 16th argument.

  @return The value returned by the EBC application we're going to run.

**/
UINT64
EbcInterpret (
  IN OUT UINTN      Arg1,
  IN OUT UINTN      Arg2,
  IN OUT UINTN      Arg3,
  IN OUT UINTN      Arg4,
  IN OUT UINTN      Arg5,
  IN OUT UINTN      Arg6,
  IN OUT UINTN      Arg7,
  IN OUT UINTN      Arg8,
  IN OUT UINTN      Arg9,
  IN OUT UINTN      Arg10,
  IN OUT UINTN      Arg11,
  IN OUT UINTN      Arg12,
  IN OUT UINTN      Arg13,
  IN OUT UINTN      Arg14,
  IN OUT UINTN      Arg15,
  IN OUT UINTN      Arg16
  )
{
  //
  // Create a new VM context on the stack
  //
  VM_CONTEXT  VmContext;
  UINTN       Addr;
  EFI_STATUS  Status;
  UINTN       StackIndex;

  //
  // Get the EBC entry point from the processor register.
  // Don't call any function before getting the EBC entry
  // point because this will collab the return register.
  //
  Addr = EbcLLGetEbcEntryPoint ();

  //
  // Now clear out our context
  //
  ZeroMem ((VOID *) &VmContext, sizeof (VM_CONTEXT));

  //
  // Set the VM instruction pointer to the correct location in memory.
  //
  VmContext.Ip = (VMIP) Addr;

  //
  // Initialize the stack pointer for the EBC. Get the current system stack
  // pointer and adjust it down by the max needed for the interpreter.
  //
  Addr            = EbcLLGetStackPointer ();

  //
  // Adjust the VM's stack pointer down.
  //

  Status = GetEBCStack((EFI_HANDLE)(UINTN)-1, &VmContext.StackPool, &StackIndex);
  if (EFI_ERROR(Status)) {
    return Status;
  }
  VmContext.StackTop = (UINT8*)VmContext.StackPool + (STACK_REMAIN_SIZE);
  VmContext.Gpr[0] = (UINT64) ((UINT8*)VmContext.StackPool + STACK_POOL_SIZE);
  VmContext.HighStackBottom = (UINTN) VmContext.Gpr[0];
  VmContext.Gpr[0] -= sizeof (UINTN);

  //
  // Align the stack on a natural boundary.
  //
  VmContext.Gpr[0] &= ~(sizeof (UINTN) - 1);

  //
  // Put a magic value in the stack gap, then adjust down again.
  //
  *(UINTN *) (UINTN) (VmContext.Gpr[0]) = (UINTN) VM_STACK_KEY_VALUE;
  VmContext.StackMagicPtr             = (UINTN *) (UINTN) VmContext.Gpr[0];

  //
  // The stack upper to LowStackTop is belong to the VM.
  //
  VmContext.LowStackTop   = (UINTN) VmContext.Gpr[0];

  //
  // For the worst case, assume there are 4 arguments passed in registers, store
  // them to VM's stack.
  //
  PushU64 (&VmContext, (UINT64) Arg16);
  PushU64 (&VmContext, (UINT64) Arg15);
  PushU64 (&VmContext, (UINT64) Arg14);
  PushU64 (&VmContext, (UINT64) Arg13);
  PushU64 (&VmContext, (UINT64) Arg12);
  PushU64 (&VmContext, (UINT64) Arg11);
  PushU64 (&VmContext, (UINT64) Arg10);
  PushU64 (&VmContext, (UINT64) Arg9);
  PushU64 (&VmContext, (UINT64) Arg8);
  PushU64 (&VmContext, (UINT64) Arg7);
  PushU64 (&VmContext, (UINT64) Arg6);
  PushU64 (&VmContext, (UINT64) Arg5);
  PushU64 (&VmContext, (UINT64) Arg4);
  PushU64 (&VmContext, (UINT64) Arg3);
  PushU64 (&VmContext, (UINT64) Arg2);
  PushU64 (&VmContext, (UINT64) Arg1);

  //
  // Interpreter assumes 64-bit return address is pushed on the stack.
  // The x64 does not do this so pad the stack accordingly.
  //
  PushU64 (&VmContext, (UINT64) 0);
  PushU64 (&VmContext, (UINT64) 0x1234567887654321ULL);

  //
  // For x64, this is where we say our return address is
  //
  VmContext.StackRetAddr  = (UINT64) VmContext.Gpr[0];

  //
  // We need to keep track of where the EBC stack starts. This way, if the EBC
  // accesses any stack variables above its initial stack setting, then we know
  // it's accessing variables passed into it, which means the data is on the
  // VM's stack.
  // When we're called, on the stack (high to low) we have the parameters, the
  // return address, then the saved ebp. Save the pointer to the return address.
  // EBC code knows that's there, so should look above it for function parameters.
  // The offset is the size of locals (VMContext + Addr + saved ebp).
  // Note that the interpreter assumes there is a 16 bytes of return address on
  // the stack too, so adjust accordingly.
  //  VmContext.HighStackBottom = (UINTN)(Addr + sizeof (VmContext) + sizeof (Addr));
  //

  //
  // Begin executing the EBC code
  //
  EbcExecute (&VmContext);

  //
  // Return the value in R[7] unless there was an error
  //
  ReturnEBCStack(StackIndex);
  return (UINT64) VmContext.Gpr[7];
}


/**
  Begin executing an EBC image. The address of the entry point is passed
  in via a processor register, so we'll need to make a call to get the
  value.

  @param  ImageHandle      image handle for the EBC application we're executing
  @param  SystemTable      standard system table passed into an driver's entry
                           point

  @return The value returned by the EBC application we're going to run.

**/
UINT64
ExecuteEbcImageEntryPoint (
  IN EFI_HANDLE           ImageHandle,
  IN EFI_SYSTEM_TABLE     *SystemTable
  )
{
  //
  // Create a new VM context on the stack
  //
  VM_CONTEXT  VmContext;
  UINTN       Addr;
  EFI_STATUS  Status;
  UINTN       StackIndex;

  //
  // Get the EBC entry point from the processor register. Make sure you don't
  // call any functions before this or you could mess up the register the
  // entry point is passed in.
  //
  Addr = EbcLLGetEbcEntryPoint ();

  //
  // Now clear out our context
  //
  ZeroMem ((VOID *) &VmContext, sizeof (VM_CONTEXT));

  //
  // Save the image handle so we can track the thunks created for this image
  //
  VmContext.ImageHandle = ImageHandle;
  VmContext.SystemTable = SystemTable;

  //
  // Set the VM instruction pointer to the correct location in memory.
  //
  VmContext.Ip = (VMIP) Addr;

  //
  // Initialize the stack pointer for the EBC. Get the current system stack
  // pointer and adjust it down by the max needed for the interpreter.
  //
  Addr = EbcLLGetStackPointer ();

  Status = GetEBCStack(ImageHandle, &VmContext.StackPool, &StackIndex);
  if (EFI_ERROR(Status)) {
    return Status;
  }
  VmContext.StackTop = (UINT8*)VmContext.StackPool + (STACK_REMAIN_SIZE);
  VmContext.Gpr[0] = (UINT64) ((UINT8*)VmContext.StackPool + STACK_POOL_SIZE);
  VmContext.HighStackBottom = (UINTN) VmContext.Gpr[0];
  VmContext.Gpr[0] -= sizeof (UINTN);


  //
  // Put a magic value in the stack gap, then adjust down again
  //
  *(UINTN *) (UINTN) (VmContext.Gpr[0]) = (UINTN) VM_STACK_KEY_VALUE;
  VmContext.StackMagicPtr             = (UINTN *) (UINTN) VmContext.Gpr[0];

  //
  // Align the stack on a natural boundary
  VmContext.Gpr[0] &= ~(sizeof(UINTN) - 1);
  //
  VmContext.LowStackTop   = (UINTN) VmContext.Gpr[0];

  //
  // Simply copy the image handle and system table onto the EBC stack.
  // Greatly simplifies things by not having to spill the args.
  //
  PushU64 (&VmContext, (UINT64) SystemTable);
  PushU64 (&VmContext, (UINT64) ImageHandle);

  //
  // VM pushes 16-bytes for return address. Simulate that here.
  //
  PushU64 (&VmContext, (UINT64) 0);
  PushU64 (&VmContext, (UINT64) 0x1234567887654321ULL);

  //
  // For x64, this is where we say our return address is
  //
  VmContext.StackRetAddr  = (UINT64) VmContext.Gpr[0];

  //
  // Entry function needn't access high stack context, simply
  // put the stack pointer here.
  //

  //
  // Begin executing the EBC code
  //
  EbcExecute (&VmContext);

  //
  // Return the value in R[7] unless there was an error
  //
  ReturnEBCStack(StackIndex);
  return (UINT64) VmContext.Gpr[7];
}


/**
  Create thunks for an EBC image entry point, or an EBC protocol service.

  @param  ImageHandle           Image handle for the EBC image. If not null, then
                                we're creating a thunk for an image entry point.
  @param  EbcEntryPoint         Address of the EBC code that the thunk is to call
  @param  Thunk                 Returned thunk we create here
  @param  Flags                 Flags indicating options for creating the thunk

  @retval EFI_SUCCESS           The thunk was created successfully.
  @retval EFI_INVALID_PARAMETER The parameter of EbcEntryPoint is not 16-bit
                                aligned.
  @retval EFI_OUT_OF_RESOURCES  There is not enough memory to created the EBC
                                Thunk.
  @retval EFI_BUFFER_TOO_SMALL  EBC_THUNK_SIZE is not larger enough.

**/
EFI_STATUS
EbcCreateThunks (
  IN EFI_HANDLE           ImageHandle,
  IN VOID                 *EbcEntryPoint,
  OUT VOID                **Thunk,
  IN  UINT32              Flags
  )
{
  UINT8       *Ptr;
  UINT8       *ThunkBase;
  UINT32      Index;
  UINT64      Addr;
  INT32       Size;
  INT32       ThunkSize;

  //
  // Check alignment of pointer to EBC code
  //
  if ((UINT32) (UINTN) EbcEntryPoint & 0x01) {
    return EFI_INVALID_PARAMETER;
  }

  Size      = EBC_THUNK_SIZE;
  ThunkSize = Size;

  Ptr = AllocatePool (Size);

  if (Ptr == NULL) {
    return EFI_OUT_OF_RESOURCES;
  }
  //
  //  Print(L"Allocate TH: 0x%X\n", (UINT32)Ptr);
  //
  // Save the start address so we can add a pointer to it to a list later.
  //
  ThunkBase = Ptr;

  //
  // Give them the address of our buffer we're going to fix up
  //
  *Thunk = (VOID *) Ptr;

  //
  // Add a magic code here to help the VM recognize the thunk..
  // mov rax, ca112ebccall2ebch  => 48 B8 BC 2E 11 CA BC 2E 11 CA
  //
  *Ptr = 0x48;
  Ptr++;
  Size--;
  *Ptr = 0xB8;
  Ptr++;
  Size--;
  Addr = (UINT64) 0xCA112EBCCA112EBCULL;
  for (Index = 0; Index < sizeof (Addr); Index++) {
    *Ptr = (UINT8) (UINTN) Addr;
    Addr >>= 8;
    Ptr++;
    Size--;
  }

  //
  // Add code bytes to load up a processor register with the EBC entry point.
  // mov r10, 123456789abcdef0h  => 49 BA F0 DE BC 9A 78 56 34 12
  // The first 8 bytes of the thunk entry is the address of the EBC
  // entry point.
  //
  *Ptr = 0x49;
  Ptr++;
  Size--;
  *Ptr = 0xBA;
  Ptr++;
  Size--;
  Addr = (UINT64) EbcEntryPoint;
  for (Index = 0; Index < sizeof (Addr); Index++) {
    *Ptr = (UINT8) (UINTN) Addr;
    Addr >>= 8;
    Ptr++;
    Size--;
  }

  //
  // Stick in a load of ecx with the address of appropriate VM function.
  // Using r11 because it's a volatile register and won't be used in this
  // point.
  // mov r11 123456789abcdef0h  => 49 BB F0 DE BC 9A 78 56 34 12
  //
  if ((Flags & FLAG_THUNK_ENTRY_POINT) != 0) {
    Addr = (UINTN) ExecuteEbcImageEntryPoint;
  } else {
    Addr = (UINTN) EbcInterpret;
  }

  //
  // mov r11 Addr => 0x49 0xBB
  //
  *Ptr = 0x49;
  Ptr++;
  Size--;
  *Ptr = 0xBB;
  Ptr++;
  Size--;
  for (Index = 0; Index < sizeof (Addr); Index++) {
    *Ptr = (UINT8) Addr;
    Addr >>= 8;
    Ptr++;
    Size--;
  }
  //
  // Stick in jump opcode bytes for jmp r11 => 0x41 0xFF 0xE3
  //
  *Ptr = 0x41;
  Ptr++;
  Size--;
  *Ptr = 0xFF;
  Ptr++;
  Size--;
  *Ptr = 0xE3;
  Size--;

  //
  // Double check that our defined size is ok (application error)
  //
  if (Size < 0) {
    ASSERT (FALSE);
    return EFI_BUFFER_TOO_SMALL;
  }
  //
  // Add the thunk to the list for this image. Do this last since the add
  // function flushes the cache for us.
  //
  EbcAddImageThunk (ImageHandle, (VOID *) ThunkBase, ThunkSize);

  return EFI_SUCCESS;
}


/**
  This function is called to execute an EBC CALLEX instruction.
  The function check the callee's content to see whether it is common native
  code or a thunk to another piece of EBC code.
  If the callee is common native code, use EbcLLCAllEXASM to manipulate,
  otherwise, set the VM->IP to target EBC code directly to avoid another VM
  be startup which cost time and stack space.

  @param  VmPtr            Pointer to a VM context.
  @param  FuncAddr         Callee's address
  @param  NewStackPointer  New stack pointer after the call
  @param  FramePtr         New frame pointer after the call
  @param  Size             The size of call instruction

**/
VOID
EbcLLCALLEX (
  IN VM_CONTEXT   *VmPtr,
  IN UINTN        FuncAddr,
  IN UINTN        NewStackPointer,
  IN VOID         *FramePtr,
  IN UINT8        Size
  )
{
  UINTN    IsThunk;
  UINTN    TargetEbcAddr;

  IsThunk       = 1;
  TargetEbcAddr = 0;

  //
  // Processor specific code to check whether the callee is a thunk to EBC.
  //
  if (*((UINT8 *)FuncAddr) != 0x48) {
    IsThunk = 0;
    goto Action;
  }
  if (*((UINT8 *)FuncAddr + 1) != 0xB8) {
    IsThunk = 0;
    goto Action;
  }
  if (*((UINT8 *)FuncAddr + 2) != 0xBC)  {
    IsThunk = 0;
    goto Action;
  }
  if (*((UINT8 *)FuncAddr + 3) != 0x2E)  {
    IsThunk = 0;
    goto Action;
  }
  if (*((UINT8 *)FuncAddr + 4) != 0x11)  {
    IsThunk = 0;
    goto Action;
  }
  if (*((UINT8 *)FuncAddr + 5) != 0xCA)  {
    IsThunk = 0;
    goto Action;
  }
  if (*((UINT8 *)FuncAddr + 6) != 0xBC)  {
    IsThunk = 0;
    goto Action;
  }
  if (*((UINT8 *)FuncAddr + 7) != 0x2E)  {
    IsThunk = 0;
    goto Action;
  }
  if (*((UINT8 *)FuncAddr + 8) != 0x11)  {
    IsThunk = 0;
    goto Action;
  }
  if (*((UINT8 *)FuncAddr + 9) != 0xCA)  {
    IsThunk = 0;
    goto Action;
  }
  if (*((UINT8 *)FuncAddr + 10) != 0x49)  {
    IsThunk = 0;
    goto Action;
  }
  if (*((UINT8 *)FuncAddr + 11) != 0xBA)  {
    IsThunk = 0;
    goto Action;
  }

  CopyMem (&TargetEbcAddr, (UINT8 *)FuncAddr + 12, 8);

Action:
  if (IsThunk == 1){
    //
    // The callee is a thunk to EBC, adjust the stack pointer down 16 bytes and
    // put our return address and frame pointer on the VM stack.
    // Then set the VM's IP to new EBC code.
    //
    VmPtr->Gpr[0] -= 8;
    VmWriteMemN (VmPtr, (UINTN) VmPtr->Gpr[0], (UINTN) FramePtr);
    VmPtr->FramePtr = (VOID *) (UINTN) VmPtr->Gpr[0];
    VmPtr->Gpr[0] -= 8;
    VmWriteMem64 (VmPtr, (UINTN) VmPtr->Gpr[0], (UINT64) (VmPtr->Ip + Size));

    VmPtr->Ip = (VMIP) (UINTN) TargetEbcAddr;
  } else {
    //
    // The callee is not a thunk to EBC, call native code.
    //
    EbcLLCALLEXNative (FuncAddr, NewStackPointer, FramePtr);

    //
    // Get return value and advance the IP.
    //
    VmPtr->Gpr[7] = EbcLLGetReturnValue ();
    VmPtr->Ip += Size;
  }
}

