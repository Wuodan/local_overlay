/** @file
  Main file for SetVar shell Debug1 function.

  Copyright (c) 2010, Intel Corporation. All rights reserved.<BR>
  This program and the accompanying materials
  are licensed and made available under the terms and conditions of the BSD License
  which accompanies this distribution.  The full text of the license may be found at
  http://opensource.org/licenses/bsd-license.php

  THE PROGRAM IS DISTRIBUTED UNDER THE BSD LICENSE ON AN "AS IS" BASIS,
  WITHOUT WARRANTIES OR REPRESENTATIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED.

**/

#include "UefiShellDebug1CommandsLib.h"

STATIC CONST SHELL_PARAM_ITEM ParamList[] = {
  {L"-guid", TypeValue},
  {L"-bs", TypeFlag},
  {L"-rt", TypeFlag},
  {L"-nv", TypeFlag},
  {NULL, TypeMax}
  };

SHELL_STATUS
EFIAPI
ShellCommandRunSetVar (
  IN EFI_HANDLE        ImageHandle,
  IN EFI_SYSTEM_TABLE  *SystemTable
  )
{
  EFI_STATUS          Status;
  LIST_ENTRY          *Package;
  CHAR16              *ProblemParam;
  SHELL_STATUS        ShellStatus;
  CONST CHAR16        *VariableName;
  CONST CHAR16        *Data;
  EFI_GUID            Guid;
  CONST CHAR16        *StringGuid;
  UINT32              Attributes;
  VOID                *Buffer;
  UINTN               Size;
  UINTN               LoopVar;
  EFI_DEVICE_PATH_PROTOCOL           *DevPath;
  EFI_DEVICE_PATH_FROM_TEXT_PROTOCOL *DevPathFromText;

  ShellStatus         = SHELL_SUCCESS;
  Status              = EFI_SUCCESS;
  Buffer              = NULL;
  Size                = 0;
  Attributes          = 0;
  DevPath             = NULL;

  //
  // initialize the shell lib (we must be in non-auto-init...)
  //
  Status = ShellInitialize();
  ASSERT_EFI_ERROR(Status);

  Status = CommandInit();
  ASSERT_EFI_ERROR(Status);

  //
  // parse the command line
  //
  Status = ShellCommandLineParse (ParamList, &Package, &ProblemParam, TRUE);
  if (EFI_ERROR(Status)) {
    if (Status == EFI_VOLUME_CORRUPTED && ProblemParam != NULL) {
      ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_GEN_PROBLEM), gShellDebug1HiiHandle, ProblemParam);
      FreePool(ProblemParam);
      ShellStatus = SHELL_INVALID_PARAMETER;
    } else {
      ASSERT(FALSE);
    }
  } else {
    if (ShellCommandLineGetCount(Package) < 2) {
      ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_GEN_TOO_FEW), gShellDebug1HiiHandle);
      ShellStatus = SHELL_INVALID_PARAMETER;
    } else if (ShellCommandLineGetCount(Package) > 3) {
      ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_GEN_TOO_MANY), gShellDebug1HiiHandle);
      ShellStatus = SHELL_INVALID_PARAMETER;
    } else {
      VariableName  = ShellCommandLineGetRawValue(Package, 1);
      Data          = ShellCommandLineGetRawValue(Package, 2);
      if (!ShellCommandLineGetFlag(Package, L"-guid")){
        CopyGuid(&Guid, &gEfiGlobalVariableGuid);
      } else {
        StringGuid = ShellCommandLineGetValue(Package, L"-guid");
        Status = ConvertStringToGuid(StringGuid, &Guid);
        if (EFI_ERROR(Status)) {
          ShellStatus = SHELL_NOT_FOUND;
        }
      }
      if (Data == NULL) {
        //
        // Display what's there
        //
        Status = gRT->GetVariable((CHAR16*)VariableName, &Guid, &Attributes, &Size, Buffer);
        if (Status == EFI_BUFFER_TOO_SMALL) {
          Buffer = AllocatePool(Size);
          Status = gRT->GetVariable((CHAR16*)VariableName, &Guid, &Attributes, &Size, Buffer);
        }
        if (!EFI_ERROR(Status)&& Buffer != NULL) {
          ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_SETVAR_PRINT), gShellDebug1HiiHandle, &Guid, VariableName, Size);
          for (LoopVar = 0 ; LoopVar < Size ; LoopVar++) {
            ShellPrintEx(-1, -1, L"%02x ", ((UINT8*)Buffer)[LoopVar]);
          }
          ShellPrintEx(-1, -1, L"\r\n");
        } else {
          ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_SETVAR_ERROR_GET), gShellDebug1HiiHandle, &Guid, VariableName, Status);
          ShellStatus = SHELL_ACCESS_DENIED;
        }
      } else if (StrCmp(Data, L"=") == 0) {
        //
        // Delete what's there!
        //
        Status = gRT->SetVariable((CHAR16*)VariableName, &Guid, Attributes, 0, NULL);
        if (EFI_ERROR(Status)) {
          ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_SETVAR_ERROR_SET), gShellDebug1HiiHandle, &Guid, VariableName, Status);
          ShellStatus = SHELL_ACCESS_DENIED;
        } else {
          ASSERT(ShellStatus == SHELL_SUCCESS);
        }
      } else {
        if (Data[0] == L'=') {
          Data++;
        }
        //
        // Change what's there
        //
        if (ShellCommandLineGetFlag(Package, L"-bs")) {
          Attributes |= EFI_VARIABLE_BOOTSERVICE_ACCESS;
        }
        if (ShellCommandLineGetFlag(Package, L"-rt")) {
          Attributes |= EFI_VARIABLE_RUNTIME_ACCESS;
        }
        if (ShellCommandLineGetFlag(Package, L"-nv")) {
          Attributes |= EFI_VARIABLE_NON_VOLATILE;
        }
        if (ShellIsHexOrDecimalNumber(Data, TRUE, FALSE)) {
          //
          // arbitrary buffer
          //
          Buffer = AllocateZeroPool((StrLen(Data) / 2));
          for (LoopVar = 0 ; LoopVar < (StrLen(Data) / 2) ; LoopVar++) {
            ((UINT8*)Buffer)[LoopVar] = (UINT8)(HexCharToUintn(Data[LoopVar*2]) * 16);
            ((UINT8*)Buffer)[LoopVar] = (UINT8)(((UINT8*)Buffer)[LoopVar] + HexCharToUintn(Data[LoopVar*2+1]));
          }
          Status = gRT->SetVariable((CHAR16*)VariableName, &Guid, Attributes, StrLen(Data) / 2, Buffer);
          if (EFI_ERROR(Status)) {
            ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_SETVAR_ERROR_SET), gShellDebug1HiiHandle, &Guid, VariableName, Status);
            ShellStatus = SHELL_ACCESS_DENIED;
          } else {
            ASSERT(ShellStatus == SHELL_SUCCESS);
          }
        } else if (StrnCmp(Data, L"\"", 1) == 0) {
          //
          // ascii text
          //
          Data++;
          Buffer = AllocateZeroPool(StrSize(Data) / 2);
          AsciiSPrint(Buffer, StrSize(Data) / 2, "%s", Data);
          ((CHAR8*)Buffer)[AsciiStrLen(Buffer)-1] = CHAR_NULL;

          Status = gRT->SetVariable((CHAR16*)VariableName, &Guid, Attributes, AsciiStrSize(Buffer)-sizeof(CHAR8), Buffer);
          if (EFI_ERROR(Status)) {
            ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_SETVAR_ERROR_SET), gShellDebug1HiiHandle, &Guid, VariableName, Status);
            ShellStatus = SHELL_ACCESS_DENIED;
          } else {
            ASSERT(ShellStatus == SHELL_SUCCESS);
          }
        } else if (StrnCmp(Data, L"L\"", 2) == 0) {
          //
          // ucs2 text
          //
          Data++;
          Data++;
          Buffer = AllocateZeroPool(StrSize(Data));
          UnicodeSPrint(Buffer, StrSize(Data), L"%s", Data);
          ((CHAR16*)Buffer)[StrLen(Buffer)-1] = CHAR_NULL;

          Status = gRT->SetVariable((CHAR16*)VariableName, &Guid, Attributes, StrSize(Buffer)-sizeof(CHAR16), Buffer);
          if (EFI_ERROR(Status)) {
            ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_SETVAR_ERROR_SET), gShellDebug1HiiHandle, &Guid, VariableName, Status);
            ShellStatus = SHELL_ACCESS_DENIED;
          } else {
            ASSERT(ShellStatus == SHELL_SUCCESS);
          }
        } else if (StrnCmp(Data, L"--", 2) == 0) {
          //
          // device path in text format
          //
          Data++;
          Data++;
          Status = gBS->LocateProtocol(&gEfiDevicePathFromTextProtocolGuid, NULL, (VOID**)&DevPathFromText);
          ASSERT_EFI_ERROR(Status);
          DevPath = DevPathFromText->ConvertTextToDevicePath(Data);
          if (DevPath == NULL) {
            ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_SETVAR_ERROR_DPFT), gShellDebug1HiiHandle, Status);
            ShellStatus = SHELL_INVALID_PARAMETER;
          } else {
            Status = gRT->SetVariable((CHAR16*)VariableName, &Guid, Attributes, GetDevicePathSize(DevPath), DevPath);
            if (EFI_ERROR(Status)) {
              ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_SETVAR_ERROR_SET), gShellDebug1HiiHandle, &Guid, VariableName, Status);
              ShellStatus = SHELL_ACCESS_DENIED;
            } else {
              ASSERT(ShellStatus == SHELL_SUCCESS);
            }
          }
        } else {
          ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_GEN_PROBLEM), gShellDebug1HiiHandle, Data);
          ShellStatus = SHELL_INVALID_PARAMETER;
        }
      }
    }
    ShellCommandLineFreeVarList (Package);
  }

  if (Buffer != NULL) {
    FreePool(Buffer);
  }

  if (DevPath != NULL) {
    FreePool(DevPath);
  }

  return (ShellStatus);
}
