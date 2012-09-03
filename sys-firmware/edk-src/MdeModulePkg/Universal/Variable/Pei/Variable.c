/** @file

  Implement ReadOnly Variable Services required by PEIM and install
  PEI ReadOnly Varaiable2 PPI. These services operates the non volatile storage space.

Copyright (c) 2006 - 2010, Intel Corporation. All rights reserved.<BR>
This program and the accompanying materials
are licensed and made available under the terms and conditions of the BSD License
which accompanies this distribution.  The full text of the license may be found at
http://opensource.org/licenses/bsd-license.php

THE PROGRAM IS DISTRIBUTED UNDER THE BSD LICENSE ON AN "AS IS" BASIS,
WITHOUT WARRANTIES OR REPRESENTATIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED.
Module Name:

**/


#include "Variable.h"

//
// Module globals
//
EFI_PEI_READ_ONLY_VARIABLE2_PPI mVariablePpi = {
  PeiGetVariable,
  PeiGetNextVariableName
};

EFI_PEI_PPI_DESCRIPTOR     mPpiListVariable = {
  (EFI_PEI_PPI_DESCRIPTOR_PPI | EFI_PEI_PPI_DESCRIPTOR_TERMINATE_LIST),
  &gEfiPeiReadOnlyVariable2PpiGuid,
  &mVariablePpi
};

EFI_GUID mEfiVariableIndexTableGuid = EFI_VARIABLE_INDEX_TABLE_GUID;


/**
  Provide the functionality of the variable services.
  
  @param  FileHandle   Handle of the file being invoked. 
                       Type EFI_PEI_FILE_HANDLE is defined in FfsFindNextFile().
  @param  PeiServices  General purpose services available to every PEIM.

  @retval EFI_SUCCESS  If the interface could be successfully installed
  @retval Others       Returned from PeiServicesInstallPpi()

**/
EFI_STATUS
EFIAPI
PeimInitializeVariableServices (
  IN       EFI_PEI_FILE_HANDLE       FileHandle,
  IN CONST EFI_PEI_SERVICES          **PeiServices
  )
{
  EFI_BOOT_MODE BootMode;
  EFI_STATUS    Status;

  //
  // Check if this is recovery boot path. If no, publish the variable access capability
  // to other modules. If yes, the content of variable area is not reliable. Therefore,
  // in this case we should not provide variable service to other pei modules. 
  // 
  Status = (*PeiServices)->GetBootMode (PeiServices, &BootMode);
  ASSERT_EFI_ERROR (Status);
  
  if (BootMode == BOOT_IN_RECOVERY_MODE) {
    return EFI_UNSUPPORTED;
  }

  return PeiServicesInstallPpi (&mPpiListVariable);

}

/**

  Gets the pointer to the first variable header in given variable store area.

  @param VarStoreHeader  Pointer to the Variable Store Header.

  @return Pointer to the first variable header

**/
VARIABLE_HEADER *
GetStartPointer (
  IN VARIABLE_STORE_HEADER       *VarStoreHeader
  )
{
  //
  // The end of variable store
  //
  return (VARIABLE_HEADER *) HEADER_ALIGN (VarStoreHeader + 1);
}


/**
  This code gets the pointer to the last variable memory pointer byte.

  @param  VarStoreHeader  Pointer to the Variable Store Header.

  @return VARIABLE_HEADER* pointer to last unavailable Variable Header.

**/
VARIABLE_HEADER *
GetEndPointer (
  IN VARIABLE_STORE_HEADER       *VarStoreHeader
  )
{
  //
  // The end of variable store
  //
  return (VARIABLE_HEADER *) HEADER_ALIGN ((UINTN) VarStoreHeader + VarStoreHeader->Size);
}


/**
  This code checks if variable header is valid or not.

  @param  Variable  Pointer to the Variable Header.

  @retval TRUE      Variable header is valid.
  @retval FALSE     Variable header is not valid.

**/
BOOLEAN
IsValidVariableHeader (
  IN  VARIABLE_HEADER   *Variable
  )
{
  if (Variable == NULL || Variable->StartId != VARIABLE_DATA ) {
    return FALSE;
  }

  return TRUE;
}


/**
  This code gets the size of name of variable.

  @param  Variable  Pointer to the Variable Header.

  @return Size of variable in bytes in type UINTN.

**/
UINTN
NameSizeOfVariable (
  IN  VARIABLE_HEADER   *Variable
  )
{
  if (Variable->State    == (UINT8) (-1) ||
      Variable->DataSize == (UINT32) (-1) ||
      Variable->NameSize == (UINT32) (-1) ||
      Variable->Attributes == (UINT32) (-1)) {
    return 0;
  }
  return (UINTN) Variable->NameSize;
}


/**
  This code gets the size of data of variable.

  @param  Variable  Pointer to the Variable Header.

  @return Size of variable in bytes in type UINTN.

**/
UINTN
DataSizeOfVariable (
  IN  VARIABLE_HEADER   *Variable
  )
{
  if (Variable->State    == (UINT8)  (-1) ||
      Variable->DataSize == (UINT32) (-1) ||
      Variable->NameSize == (UINT32) (-1) ||
      Variable->Attributes == (UINT32) (-1)) {
    return 0;
  }
  return (UINTN) Variable->DataSize;
}

/**
  This code gets the pointer to the variable name.

  @param   Variable  Pointer to the Variable Header.

  @return  A CHAR16* pointer to Variable Name.

**/
CHAR16 *
GetVariableNamePtr (
  IN  VARIABLE_HEADER   *Variable
  )
{

  return (CHAR16 *) (Variable + 1);
}


/**
  This code gets the pointer to the variable data.

  @param   Variable  Pointer to the Variable Header.

  @return  A UINT8* pointer to Variable Data.

**/
UINT8 *
GetVariableDataPtr (
  IN  VARIABLE_HEADER   *Variable
  )
{
  UINTN Value;
  
  //
  // Be careful about pad size for alignment
  //
  Value =  (UINTN) GetVariableNamePtr (Variable);
  Value += NameSizeOfVariable (Variable);
  Value += GET_PAD_SIZE (NameSizeOfVariable (Variable));

  return (UINT8 *) Value;
}


/**
  This code gets the pointer to the next variable header.

  @param  Variable  Pointer to the Variable Header.

  @return  A VARIABLE_HEADER* pointer to next variable header.

**/
VARIABLE_HEADER *
GetNextVariablePtr (
  IN  VARIABLE_HEADER   *Variable
  )
{
  UINTN Value;

  if (!IsValidVariableHeader (Variable)) {
    return NULL;
  }

  Value =  (UINTN) GetVariableDataPtr (Variable);
  Value += DataSizeOfVariable (Variable);
  Value += GET_PAD_SIZE (DataSizeOfVariable (Variable));

  //
  // Be careful about pad size for alignment
  //
  return (VARIABLE_HEADER *) HEADER_ALIGN (Value);
}

/**
  This code gets the pointer to the variable name.

  @param  VarStoreHeader  Pointer to the Variable Store Header.

  @retval  EfiRaw      Variable store is raw
  @retval  EfiValid    Variable store is valid
  @retval  EfiInvalid  Variable store is invalid

**/
VARIABLE_STORE_STATUS
GetVariableStoreStatus (
  IN VARIABLE_STORE_HEADER *VarStoreHeader
  )
{
	
  if (CompareGuid (&VarStoreHeader->Signature, &gEfiVariableGuid) &&
      VarStoreHeader->Format == VARIABLE_STORE_FORMATTED &&
      VarStoreHeader->State == VARIABLE_STORE_HEALTHY
      ) {

    return EfiValid;
  }

  if (((UINT32 *)(&VarStoreHeader->Signature))[0] == 0xffffffff &&
      ((UINT32 *)(&VarStoreHeader->Signature))[1] == 0xffffffff &&
      ((UINT32 *)(&VarStoreHeader->Signature))[2] == 0xffffffff &&
      ((UINT32 *)(&VarStoreHeader->Signature))[3] == 0xffffffff &&
      VarStoreHeader->Size == 0xffffffff &&
      VarStoreHeader->Format == 0xff &&
      VarStoreHeader->State == 0xff
      ) {

    return EfiRaw;
  } else {
    return EfiInvalid;
  }
}


/**
  This function compares a variable with variable entries in database.

  @param  Variable      Pointer to the variable in our database
  @param  VariableName  Name of the variable to compare to 'Variable'
  @param  VendorGuid    GUID of the variable to compare to 'Variable'
  @param  PtrTrack      Variable Track Pointer structure that contains Variable Information.

  @retval EFI_SUCCESS    Found match variable
  @retval EFI_NOT_FOUND  Variable not found

**/
EFI_STATUS
CompareWithValidVariable (
  IN  VARIABLE_HEADER               *Variable,
  IN  CONST CHAR16                  *VariableName,
  IN  CONST EFI_GUID                *VendorGuid,
  OUT VARIABLE_POINTER_TRACK        *PtrTrack
  )
{
  VOID  *Point;

  if (VariableName[0] == 0) {
    PtrTrack->CurrPtr = Variable;
    return EFI_SUCCESS;
  } else {
    //
    // Don't use CompareGuid function here for performance reasons.
    // Instead we compare the GUID a UINT32 at a time and branch
    // on the first failed comparison.
    //
    if ((((INT32 *) VendorGuid)[0] == ((INT32 *) &Variable->VendorGuid)[0]) &&
        (((INT32 *) VendorGuid)[1] == ((INT32 *) &Variable->VendorGuid)[1]) &&
        (((INT32 *) VendorGuid)[2] == ((INT32 *) &Variable->VendorGuid)[2]) &&
        (((INT32 *) VendorGuid)[3] == ((INT32 *) &Variable->VendorGuid)[3])
        ) {
      ASSERT (NameSizeOfVariable (Variable) != 0);
      Point = (VOID *) GetVariableNamePtr (Variable);
      if (CompareMem (VariableName, Point, NameSizeOfVariable (Variable)) == 0) {
        PtrTrack->CurrPtr = Variable;
        return EFI_SUCCESS;
      }
    }
  }

  return EFI_NOT_FOUND;
}


/**
  This code finds variable in storage blocks (Non-Volatile).

  @param  PeiServices   General purpose services available to every PEIM.
  @param  VariableName  Name of the variable to be found
  @param  VendorGuid    Vendor GUID to be found.
  @param  PtrTrack      Variable Track Pointer structure that contains Variable Information.

  @retval  EFI_SUCCESS            Variable found successfully
  @retval  EFI_NOT_FOUND          Variable not found
  @retval  EFI_INVALID_PARAMETER  Invalid variable name

**/
EFI_STATUS
FindVariable (
  IN CONST EFI_PEI_SERVICES   **PeiServices,
  IN CONST  CHAR16            *VariableName,
  IN CONST  EFI_GUID          *VendorGuid,
  OUT VARIABLE_POINTER_TRACK  *PtrTrack
  )
{
  EFI_HOB_GUID_TYPE       *GuidHob;
  VARIABLE_STORE_HEADER   *VariableStoreHeader;
  VARIABLE_HEADER         *Variable;
  VARIABLE_HEADER         *LastVariable;
  VARIABLE_HEADER         *MaxIndex;
  VARIABLE_INDEX_TABLE    *IndexTable;
  UINT32                  Count;
  UINT32                  Offset;
  UINT8                   *VariableBase;
  BOOLEAN                 StopRecord;

  if (VariableName[0] != 0 && VendorGuid == NULL) {
    return EFI_INVALID_PARAMETER;
  }
  //
  // No Variable Address equals zero, so 0 as initial value is safe.
  //
  MaxIndex = 0;
  StopRecord = FALSE;

  GuidHob = GetFirstGuidHob (&mEfiVariableIndexTableGuid);
  if (GuidHob == NULL) {
    //
    // If it's the first time to access variable region in flash, create a guid hob to record
    // VAR_ADDED type variable info.
    // Note that as the resource of PEI phase is limited, only store the number of 
    // VARIABLE_INDEX_TABLE_VOLUME of VAR_ADDED type variables to reduce access time.
    //
    IndexTable = BuildGuidHob (&mEfiVariableIndexTableGuid, sizeof (VARIABLE_INDEX_TABLE));
    IndexTable->Length      = 0;
    IndexTable->StartPtr    = NULL;
    IndexTable->EndPtr      = NULL;
    IndexTable->GoneThrough = 0;
  } else {
    IndexTable = GET_GUID_HOB_DATA (GuidHob);
    for (Offset = 0, Count = 0; Count < IndexTable->Length; Count++) {
      //
      // traverse the variable info list to look for varible.
      // The IndexTable->Index[Count] records the distance of two neighbouring VAR_ADDED type variables.
      //
      ASSERT (Count < VARIABLE_INDEX_TABLE_VOLUME);
      Offset   += IndexTable->Index[Count];
      MaxIndex  = (VARIABLE_HEADER *)((CHAR8 *)(IndexTable->StartPtr) + Offset);
      if (CompareWithValidVariable (MaxIndex, VariableName, VendorGuid, PtrTrack) == EFI_SUCCESS) {
        PtrTrack->StartPtr  = IndexTable->StartPtr;
        PtrTrack->EndPtr    = IndexTable->EndPtr;

        return EFI_SUCCESS;
      }
    }

    if (IndexTable->GoneThrough != 0) {
      return EFI_NOT_FOUND;
    }
  }
  //
  // If not found in HOB, then let's start from the MaxIndex we've found.
  //
  if (MaxIndex != NULL) {
    Variable     = GetNextVariablePtr (MaxIndex);
    LastVariable = MaxIndex;
  } else {
    if ((IndexTable->StartPtr != NULL) || (IndexTable->EndPtr != NULL)) {
      Variable = IndexTable->StartPtr;
    } else {
      VariableBase = (UINT8 *) (UINTN) PcdGet64 (PcdFlashNvStorageVariableBase64);
      if (VariableBase == NULL) {
        VariableBase = (UINT8 *) (UINTN) PcdGet32 (PcdFlashNvStorageVariableBase);
      }
      
      VariableStoreHeader = (VARIABLE_STORE_HEADER *) (VariableBase + \
                            ((EFI_FIRMWARE_VOLUME_HEADER *) (VariableBase)) -> HeaderLength);

      if (GetVariableStoreStatus (VariableStoreHeader) != EfiValid) {
        return EFI_UNSUPPORTED;
      }

      if (~VariableStoreHeader->Size == 0) {
        return EFI_NOT_FOUND;
      }
      //
      // Find the variable by walk through non-volatile variable store
      //
      IndexTable->StartPtr  = GetStartPointer (VariableStoreHeader);
      IndexTable->EndPtr    = GetEndPointer (VariableStoreHeader);

      //
      // Start Pointers for the variable.
      // Actual Data Pointer where data can be written.
      //
      Variable = IndexTable->StartPtr;
    }

    LastVariable = IndexTable->StartPtr;
  }
  //
  // Find the variable by walk through non-volatile variable store
  //
  PtrTrack->StartPtr  = IndexTable->StartPtr;
  PtrTrack->EndPtr    = IndexTable->EndPtr;

  while ((Variable < IndexTable->EndPtr) && IsValidVariableHeader (Variable)) {
    if (Variable->State == VAR_ADDED) {
      //
      // Record Variable in VariableIndex HOB
      //
      if (IndexTable->Length < VARIABLE_INDEX_TABLE_VOLUME && !StopRecord) {
        Offset = (UINT32)((UINTN)Variable - (UINTN)LastVariable);
        //
        // The distance of two neighbouring VAR_ADDED variable is larger than 2^16, 
        // which is beyond the allowable scope(UINT16) of record. In such case, need not to
        // record the subsequent VAR_ADDED type variables again.
        //
        if ((Offset & 0xFFFF0000UL) != 0) {
          StopRecord = TRUE;
        }

        if (!StopRecord) {
          IndexTable->Index[IndexTable->Length++] = (UINT16) Offset;
        }
        LastVariable = Variable;
      }

      if (CompareWithValidVariable (Variable, VariableName, VendorGuid, PtrTrack) == EFI_SUCCESS) {
        return EFI_SUCCESS;
      }
    }

    Variable = GetNextVariablePtr (Variable);
  }
  //
  // If gone through the VariableStore, that means we never find in Firmware any more.
  //
  if ((IndexTable->Length < VARIABLE_INDEX_TABLE_VOLUME) && (!StopRecord)) {
    IndexTable->GoneThrough = 1;
  }

  PtrTrack->CurrPtr = NULL;

  return EFI_NOT_FOUND;
}

/**
  This service retrieves a variable's value using its name and GUID.

  Read the specified variable from the UEFI variable store. If the Data 
  buffer is too small to hold the contents of the variable, the error
  EFI_BUFFER_TOO_SMALL is returned and DataSize is set to the required buffer
  size to obtain the data.

  @param  This                  A pointer to this instance of the EFI_PEI_READ_ONLY_VARIABLE2_PPI.
  @param  VariableName          A pointer to a null-terminated string that is the variable's name.
  @param  VariableGuid          A pointer to an EFI_GUID that is the variable's GUID. The combination of
                                VariableGuid and VariableName must be unique.
  @param  Attributes            If non-NULL, on return, points to the variable's attributes.
  @param  DataSize              On entry, points to the size in bytes of the Data buffer.
                                On return, points to the size of the data returned in Data.
  @param  Data                  Points to the buffer which will hold the returned variable value.

  @retval EFI_SUCCESS           The variable was read successfully.
  @retval EFI_NOT_FOUND         The variable could not be found.
  @retval EFI_BUFFER_TOO_SMALL  The DataSize is too small for the resulting data. 
                                DataSize is updated with the size required for 
                                the specified variable.
  @retval EFI_INVALID_PARAMETER VariableName, VariableGuid, DataSize or Data is NULL.
  @retval EFI_DEVICE_ERROR      The variable could not be retrieved because of a device error.

**/
EFI_STATUS
EFIAPI
PeiGetVariable (
  IN CONST  EFI_PEI_READ_ONLY_VARIABLE2_PPI *This,
  IN CONST  CHAR16                          *VariableName,
  IN CONST  EFI_GUID                        *VariableGuid,
  OUT       UINT32                          *Attributes,
  IN OUT    UINTN                           *DataSize,
  OUT       VOID                            *Data
  )
{
  VARIABLE_POINTER_TRACK  Variable;
  UINTN                   VarDataSize;
  EFI_STATUS              Status;
  CONST EFI_PEI_SERVICES  **PeiServices;

  PeiServices = GetPeiServicesTablePointer ();
  if (VariableName == NULL || VariableGuid == NULL || DataSize == NULL) {
    return EFI_INVALID_PARAMETER;
  }
  //
  // Find existing variable
  //
  Status = FindVariable (PeiServices, VariableName, VariableGuid, &Variable);
  if (Variable.CurrPtr == NULL || Status != EFI_SUCCESS) {
    return Status;
  }
  //
  // Get data size
  //
  VarDataSize = DataSizeOfVariable (Variable.CurrPtr);
  if (*DataSize >= VarDataSize) {
    if (Data == NULL) {
      return EFI_INVALID_PARAMETER;
    }

    CopyMem (Data, GetVariableDataPtr (Variable.CurrPtr), VarDataSize);

    if (Attributes != NULL) {
      *Attributes = Variable.CurrPtr->Attributes;
    }

    *DataSize = VarDataSize;
    return EFI_SUCCESS;
  } else {
    *DataSize = VarDataSize;
    return EFI_BUFFER_TOO_SMALL;
  }
}

/**
  Return the next variable name and GUID.

  This function is called multiple times to retrieve the VariableName 
  and VariableGuid of all variables currently available in the system. 
  On each call, the previous results are passed into the interface, 
  and, on return, the interface returns the data for the next 
  interface. When the entire variable list has been returned, 
  EFI_NOT_FOUND is returned.

  @param  This              A pointer to this instance of the EFI_PEI_READ_ONLY_VARIABLE2_PPI.

  @param  VariableNameSize  On entry, points to the size of the buffer pointed to by VariableName.
                            On return, the size of the variable name buffer.
  @param  VariableName      On entry, a pointer to a null-terminated string that is the variable's name.
                            On return, points to the next variable's null-terminated name string.
  @param  VariableGuid      On entry, a pointer to an EFI_GUID that is the variable's GUID. 
                            On return, a pointer to the next variable's GUID.

  @retval EFI_SUCCESS           The variable was read successfully.
  @retval EFI_NOT_FOUND         The variable could not be found.
  @retval EFI_BUFFER_TOO_SMALL  The VariableNameSize is too small for the resulting
                                data. VariableNameSize is updated with the size
                                required for the specified variable.
  @retval EFI_INVALID_PARAMETER VariableName, VariableGuid or
                                VariableNameSize is NULL.
  @retval EFI_DEVICE_ERROR      The variable could not be retrieved because of a device error.

**/
EFI_STATUS
EFIAPI
PeiGetNextVariableName (
  IN CONST  EFI_PEI_READ_ONLY_VARIABLE2_PPI *This,
  IN OUT UINTN                              *VariableNameSize,
  IN OUT CHAR16                             *VariableName,
  IN OUT EFI_GUID                           *VariableGuid
  )
{
  VARIABLE_POINTER_TRACK  Variable;
  UINTN                   VarNameSize;
  EFI_STATUS              Status;
  CONST EFI_PEI_SERVICES  **PeiServices;

  PeiServices = GetPeiServicesTablePointer ();
  if (VariableName == NULL || VariableGuid == NULL || VariableNameSize == NULL) {
    return EFI_INVALID_PARAMETER;
  }

  Status = FindVariable (PeiServices, VariableName, VariableGuid, &Variable);
  if (Variable.CurrPtr == NULL || Status != EFI_SUCCESS) {
    return Status;
  }

  if (VariableName[0] != 0) {
    //
    // If variable name is not NULL, get next variable
    //
    Variable.CurrPtr = GetNextVariablePtr (Variable.CurrPtr);
  }

  while (!(Variable.CurrPtr >= Variable.EndPtr || Variable.CurrPtr == NULL)) {
    if (IsValidVariableHeader (Variable.CurrPtr)) {
      if (Variable.CurrPtr->State == VAR_ADDED) {
        ASSERT (NameSizeOfVariable (Variable.CurrPtr) != 0);

        VarNameSize = (UINTN) NameSizeOfVariable (Variable.CurrPtr);
        if (VarNameSize <= *VariableNameSize) {
          CopyMem (VariableName, GetVariableNamePtr (Variable.CurrPtr), VarNameSize);

          CopyMem (VariableGuid, &Variable.CurrPtr->VendorGuid, sizeof (EFI_GUID));

          Status = EFI_SUCCESS;
        } else {
          Status = EFI_BUFFER_TOO_SMALL;
        }

        *VariableNameSize = VarNameSize;
        return Status;
        //
        // Variable is found
        //
      } else {
        Variable.CurrPtr = GetNextVariablePtr (Variable.CurrPtr);
      }
    } else {
      break;
    }
  }

  return EFI_NOT_FOUND;
}
