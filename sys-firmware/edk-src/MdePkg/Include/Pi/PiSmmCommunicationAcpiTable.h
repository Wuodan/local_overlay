/** @file
  PI SMM Communication ACPI Table Definition.

Copyright (c) 2011, Intel Corporation. All rights reserved.<BR>
This program and the accompanying materials are licensed and made available under 
the terms and conditions of the BSD License that accompanies this distribution.  
The full text of the license may be found at
http://opensource.org/licenses/bsd-license.php.                                          
    
THE PROGRAM IS DISTRIBUTED UNDER THE BSD LICENSE ON AN "AS IS" BASIS,                     
WITHOUT WARRANTIES OR REPRESENTATIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED.

**/

#ifndef __PI_SMM_COMMUNICATION_ACPI_TABLE__
#define __PI_SMM_COMMUNICATION_ACPI_TABLE__

#include <Uefi/UefiAcpiDataTable.h>

#pragma pack(1)
typedef struct {
  EFI_ACPI_DATA_TABLE  UefiAcpiDataTable;
  UINT32               SwSmiNumber;
  UINT64               BufferPtrAddress;
} EFI_SMM_COMMUNICATION_ACPI_TABLE;
#pragma pack()

#endif
