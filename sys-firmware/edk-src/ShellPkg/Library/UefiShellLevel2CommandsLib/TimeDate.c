/** @file
  Main file for time, timezone, and date shell level 2 and shell level 3 functions.

  Copyright (c) 2009 - 2010, Intel Corporation. All rights reserved.<BR>
  This program and the accompanying materials
  are licensed and made available under the terms and conditions of the BSD License
  which accompanies this distribution.  The full text of the license may be found at
  http://opensource.org/licenses/bsd-license.php

  THE PROGRAM IS DISTRIBUTED UNDER THE BSD LICENSE ON AN "AS IS" BASIS,
  WITHOUT WARRANTIES OR REPRESENTATIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED.

**/

#include "UefiShellLevel2CommandsLib.h"

INT16
EFIAPI
AbsVal(
  INT16 v
  )
{
  if (v>0) {
    return (v);
  }
  return ((INT16)(-v));
}

BOOLEAN
EFIAPI
InternalIsTimeLikeString (
  IN CONST CHAR16   *String,
  IN CONST CHAR16   Char,
  IN CONST UINTN    Min,
  IN CONST UINTN    Max,
  IN CONST BOOLEAN  MinusOk
  )
{
  UINTN Count;
  Count = 0;

  if (MinusOk) {
    //
    // A single minus is ok.
    //
    if (*String == L'-') {
      String++;
    }
  }

  //
  // the first char must be numeric.
  //
  if (!ShellIsDecimalDigitCharacter(*String)) {
    return (FALSE);
  }
  //
  // loop through the characters and use the lib function
  //
  for ( ; String != NULL && *String != CHAR_NULL ; String++){
    if (*String == Char) {
      Count++;
      if (Count > Max) {
        return (FALSE);
      }
      continue;
    }
    if (!ShellIsDecimalDigitCharacter(*String)) {
      return (FALSE);
    }
  }
  if (Count < Min) {
    return (FALSE);
  }
  return (TRUE);
}

SHELL_STATUS
EFIAPI
CheckAndSetDate (
  IN CONST CHAR16 *DateString
  )
{
  EFI_TIME      TheTime;
  EFI_STATUS    Status;
  CONST CHAR16  *Walker;

  if (!InternalIsTimeLikeString(DateString, L'/', 2, 2, FALSE)) {
    return (SHELL_INVALID_PARAMETER);
  }

  Status = gRT->GetTime(&TheTime, NULL);
  ASSERT_EFI_ERROR(Status);

  Walker = DateString;

  TheTime.Month = 0xFF;
  TheTime.Day   = 0xFF;
  TheTime.Year  = 0xFFFF;

  TheTime.Month = (UINT8)StrDecimalToUintn (Walker);
  Walker = StrStr(Walker, L"/");
  if (Walker != NULL && *Walker == L'/') {
    Walker = Walker + 1;
  }
  if (Walker != NULL && Walker[0] != CHAR_NULL) {
    TheTime.Day = (UINT8)StrDecimalToUintn (Walker);
    Walker = StrStr(Walker, L"/");
    if (Walker != NULL && *Walker == L'/') {
      Walker = Walker + 1;
    }
    if (Walker != NULL && Walker[0] != CHAR_NULL) {
      TheTime.Year = (UINT16)StrDecimalToUintn (Walker);
    }
  }

  if (TheTime.Year < 100) {
    if (TheTime.Year >= 98) {
      TheTime.Year = (UINT16)(1900 + TheTime.Year);
    } else {
      TheTime.Year = (UINT16)(2000 + TheTime.Year);
    }
  }

  Status = gRT->SetTime(&TheTime);

  if (!EFI_ERROR(Status)){
    return (SHELL_SUCCESS);
  }
  return (SHELL_INVALID_PARAMETER);
}

/**
  Function for 'date' command.

  @param[in] ImageHandle  Handle to the Image (NULL if Internal).
  @param[in] SystemTable  Pointer to the System Table (NULL if Internal).
**/
SHELL_STATUS
EFIAPI
ShellCommandRunDate (
  IN EFI_HANDLE        ImageHandle,
  IN EFI_SYSTEM_TABLE  *SystemTable
  )
{
  EFI_STATUS    Status;
  LIST_ENTRY    *Package;
  EFI_TIME      TheTime;
  CHAR16        *ProblemParam;
  SHELL_STATUS  ShellStatus;

  ShellStatus  = SHELL_SUCCESS;
  ProblemParam = NULL;

  //
  // initialize the shell lib (we must be in non-auto-init...)
  //
  Status = ShellInitialize();
  ASSERT_EFI_ERROR(Status);

  //
  // parse the command line
  //
  Status = ShellCommandLineParse (SfoParamList, &Package, &ProblemParam, TRUE);
  if (EFI_ERROR(Status)) {
    if (Status == EFI_VOLUME_CORRUPTED && ProblemParam != NULL) {
      ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_GEN_PROBLEM), gShellLevel2HiiHandle, ProblemParam);
      FreePool(ProblemParam);
      ShellStatus = SHELL_INVALID_PARAMETER;
    } else {
      ASSERT(FALSE);
    }
  } else {
    //
    // check for "-?"
    //
    if (ShellCommandLineGetFlag(Package, L"-?")) {
      ASSERT(FALSE);
    } else if (ShellCommandLineGetRawValue(Package, 2) != NULL) {
      ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_GEN_TOO_MANY), gShellLevel2HiiHandle);
      ShellStatus = SHELL_INVALID_PARAMETER;
    } else {
      //
      // If there are 0 value parameters, then print the current date
      // else If there are any value paramerers, then print error
      //
      if (ShellCommandLineGetRawValue(Package, 1) == NULL) {
        //
        // get the current date
        //
        Status = gRT->GetTime(&TheTime, NULL);
        ASSERT_EFI_ERROR(Status);

        //
        // ShellPrintEx the date in SFO or regular format
        //
        if (ShellCommandLineGetFlag(Package, L"-sfo")) {
          ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_DATE_SFO_FORMAT), gShellLevel2HiiHandle, TheTime.Month, TheTime.Day, TheTime.Year);
        } else {
          ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_DATE_FORMAT), gShellLevel2HiiHandle, TheTime.Month, TheTime.Day, TheTime.Year);
        }
      } else {
        if (PcdGet8(PcdShellSupportLevel) == 2) {
          ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_GEN_TOO_MANY), gShellLevel2HiiHandle);
          ShellStatus = SHELL_INVALID_PARAMETER;
        } else {
          //
          // perform level 3 operation here.
          //
          ShellStatus = CheckAndSetDate(ShellCommandLineGetRawValue(Package, 1));
          if (ShellStatus != SHELL_SUCCESS) {
            ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_GEN_PROBLEM), gShellLevel2HiiHandle, ShellCommandLineGetRawValue(Package, 1));
            ShellStatus = SHELL_INVALID_PARAMETER;
          }
        }
      }
    }
  }
  //
  // free the command line package
  //
  ShellCommandLineFreeVarList (Package);

  //
  // return the status
  //
  return (ShellStatus);
}

//
// Note "-tz" is invalid for this (non-interactive) version of 'time'.
//
STATIC CONST SHELL_PARAM_ITEM TimeParamList2[] = {
  {L"-d", TypeValue},
  {NULL, TypeMax}
  };

STATIC CONST SHELL_PARAM_ITEM TimeParamList3[] = {
  {L"-d", TypeValue},
  {L"-tz", TypeValue},
  {NULL, TypeMax}
  };

SHELL_STATUS
EFIAPI
CheckAndSetTime (
  IN CONST CHAR16 *TimeString,
  IN CONST INT16  Tz,
  IN CONST UINT8  Daylight
  )
{
  EFI_TIME      TheTime;
  EFI_STATUS    Status;
  CONST CHAR16  *Walker;

  if (TimeString != NULL && !InternalIsTimeLikeString(TimeString, L':', 1, 2, FALSE)) {
    return (SHELL_INVALID_PARAMETER);
  }

  Status = gRT->GetTime(&TheTime, NULL);
  ASSERT_EFI_ERROR(Status);

  if (TimeString != NULL) {
    Walker          = TimeString;
    TheTime.Hour    = 0xFF;
    TheTime.Minute  = 0xFF;

    TheTime.Hour    = (UINT8)StrDecimalToUintn (Walker);
    Walker          = StrStr(Walker, L":");
    if (Walker != NULL && *Walker == L':') {
      Walker = Walker + 1;
    }
    if (Walker != NULL && Walker[0] != CHAR_NULL) {
      TheTime.Minute = (UINT8)StrDecimalToUintn (Walker);
      Walker = StrStr(Walker, L":");
      if (Walker != NULL && *Walker == L':') {
        Walker = Walker + 1;
      }
      if (Walker != NULL && Walker[0] != CHAR_NULL) {
        TheTime.Second = (UINT8)StrDecimalToUintn (Walker);
      }
    }
  }

  if ((Tz >= -1440 && Tz <= 1440)||(Tz == 2047)) {
    TheTime.TimeZone = Tz;
  }
  if (Daylight <= 3 && Daylight != 2) {
    TheTime.Daylight = Daylight;
  }
  Status = gRT->SetTime(&TheTime);

  if (!EFI_ERROR(Status)){
    return (SHELL_SUCCESS);
  }

  return (SHELL_INVALID_PARAMETER);
}

/**
  Function for 'time' command.

  @param[in] ImageHandle  Handle to the Image (NULL if Internal).
  @param[in] SystemTable  Pointer to the System Table (NULL if Internal).
**/
SHELL_STATUS
EFIAPI
ShellCommandRunTime (
  IN EFI_HANDLE        ImageHandle,
  IN EFI_SYSTEM_TABLE  *SystemTable
  )
{
  EFI_STATUS    Status;
  LIST_ENTRY    *Package;
  CHAR16        *Message;
  EFI_TIME      TheTime;
  CHAR16        *ProblemParam;
  SHELL_STATUS  ShellStatus;
  INT16         Tz;
  UINT8         Daylight;
  CONST CHAR16  *TempLocation;
  UINTN         TzMinutes;

  ShellStatus  = SHELL_SUCCESS;
  ProblemParam = NULL;

  //
  // Initialize variables
  //
  Message = NULL;

  //
  // initialize the shell lib (we must be in non-auto-init...)
  //
  Status = ShellInitialize();
  ASSERT_EFI_ERROR(Status);

  //
  // parse the command line
  //
  if (PcdGet8(PcdShellSupportLevel) == 2) {
    Status = ShellCommandLineParseEx (TimeParamList2, &Package, &ProblemParam, TRUE, TRUE);
  } else {
    ASSERT(PcdGet8(PcdShellSupportLevel) == 3);
    Status = ShellCommandLineParseEx (TimeParamList3, &Package, &ProblemParam, TRUE, TRUE);
  }
  if (EFI_ERROR(Status)) {
    if (Status == EFI_VOLUME_CORRUPTED && ProblemParam != NULL) {
      ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_GEN_PROBLEM), gShellLevel2HiiHandle, ProblemParam);
      FreePool(ProblemParam);
      ShellStatus = SHELL_INVALID_PARAMETER;
    } else {
      ASSERT(FALSE);
    }
  } else {
    //
    // check for "-?"
    //
    Status = gRT->GetTime(&TheTime, NULL);
    ASSERT_EFI_ERROR(Status);
    if (ShellCommandLineGetFlag(Package, L"-?")) {
      ASSERT(FALSE);
    } else if (ShellCommandLineGetRawValue(Package, 2) != NULL) {
      ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_GEN_TOO_MANY), gShellLevel2HiiHandle);
      ShellStatus = SHELL_INVALID_PARAMETER;
    } else {
      //
      // If there are no parameters, then print the current time
      //
      if (ShellCommandLineGetRawValue(Package, 1) == NULL
        && !ShellCommandLineGetFlag(Package, L"-d")
        && !ShellCommandLineGetFlag(Package, L"-tz")) {
        //
        // ShellPrintEx the current time
        //
        if (TheTime.TimeZone == 2047) {
          TzMinutes = 0;
        } else {
          TzMinutes = AbsVal(TheTime.TimeZone) % 60;
        }

        ShellPrintHiiEx (
          -1,
          -1,
          NULL,
          STRING_TOKEN (STR_TIME_FORMAT),
          gShellLevel2HiiHandle,
          TheTime.Hour,
          TheTime.Minute,
          TheTime.Second,
          TheTime.TimeZone==2047?L" ":(TheTime.TimeZone > 0?L"-":L"+"),
          TheTime.TimeZone==2047?0:AbsVal(TheTime.TimeZone) / 60,
          TzMinutes
         );
         ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_GEN_CRLF), gShellLevel2HiiHandle);
      } else if (ShellCommandLineGetFlag(Package, L"-d") && ShellCommandLineGetValue(Package, L"-d") == NULL) {
        if (TheTime.TimeZone == 2047) {
          TzMinutes = 0;
        } else {
          TzMinutes = AbsVal(TheTime.TimeZone) % 60;
        }

        ShellPrintHiiEx (
          -1,
          -1,
          NULL,
          STRING_TOKEN (STR_TIME_FORMAT),
          gShellLevel2HiiHandle,
          TheTime.Hour,
          TheTime.Minute,
          TheTime.Second,
          TheTime.TimeZone==2047?L" ":(TheTime.TimeZone > 0?L"-":L"+"),
          TheTime.TimeZone==2047?0:AbsVal(TheTime.TimeZone) / 60,
          TzMinutes
         );
          switch (TheTime.Daylight) {
            case 0:
              ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_TIME_DSTNA), gShellLevel2HiiHandle);
              break;
            case EFI_TIME_ADJUST_DAYLIGHT:
              ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_TIME_DSTST), gShellLevel2HiiHandle);
              break;
            case EFI_TIME_IN_DAYLIGHT:
              ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_TIME_DSTDT), gShellLevel2HiiHandle);
              break;
            default:
              ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_GEN_UEFI_FUNC_ERROR), gShellLevel2HiiHandle, L"gRT->GetTime", L"TheTime.Daylight", TheTime.Daylight);
          }
      } else {
        if (PcdGet8(PcdShellSupportLevel) == 2) {
          ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_GEN_TOO_MANY), gShellLevel2HiiHandle);
          ShellStatus = SHELL_INVALID_PARAMETER;
        } else {
          //
          // perform level 3 operation here.
          //
          if ((TempLocation = ShellCommandLineGetValue(Package, L"-tz")) != NULL) {
            if (TempLocation[0] == L'-') {
              Tz = (INT16)(0 - StrDecimalToUintn(++TempLocation));
            } else {
              Tz = (INT16)StrDecimalToUintn(TempLocation);
            }
            if (!(Tz >= -1440 && Tz <= 1440) && Tz != 2047) {
              ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_GEN_PROBLEM), gShellLevel2HiiHandle, L"-d");
              ShellStatus = SHELL_INVALID_PARAMETER;
            }
          } else {
            //
            // intentionally out of bounds value will prevent changing it...
            //
            Tz = 1441;
          }
          TempLocation = ShellCommandLineGetValue(Package, L"-d");
          if (TempLocation != NULL) {
            Daylight = (UINT8)StrDecimalToUintn(TempLocation);
            if (Daylight != 0 && Daylight != 1 && Daylight != 3) {
              ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_GEN_PROBLEM), gShellLevel2HiiHandle, L"-d");
              ShellStatus = SHELL_INVALID_PARAMETER;
            }
          } else {
            //
            // invalid = will not use
            //
            Daylight = 0xFF;
          }
          if (ShellStatus == SHELL_SUCCESS) {
            ShellStatus = CheckAndSetTime(ShellCommandLineGetRawValue(Package, 1), Tz, Daylight);
            if (ShellStatus != SHELL_SUCCESS) {
              ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_GEN_PROBLEM), gShellLevel2HiiHandle, ShellCommandLineGetRawValue(Package, 1));
              ShellStatus = SHELL_INVALID_PARAMETER;
            }
          }
        }
      }
    }
  }

  //
  // free the command line package
  //
  ShellCommandLineFreeVarList (Package);

  //
  // return the status
  //
  return (ShellStatus);
}

typedef struct {
  INT16         TimeZone;
  EFI_STRING_ID StringId;
} TIME_ZONE_ITEM;

STATIC CONST SHELL_PARAM_ITEM TimeZoneParamList2[] = {
  {L"-l", TypeFlag},
  {L"-f", TypeFlag},
  {NULL, TypeMax}
  };
STATIC CONST SHELL_PARAM_ITEM TimeZoneParamList3[] = {
  {L"-l", TypeFlag},
  {L"-f", TypeFlag},
  {L"-s", TypeValue},
  {NULL, TypeMax}
  };

  STATIC CONST TIME_ZONE_ITEM TimeZoneList[] = {
    {720, STRING_TOKEN (STR_TIMEZONE_M12)},
    {660, STRING_TOKEN (STR_TIMEZONE_M11)},
    {600, STRING_TOKEN (STR_TIMEZONE_M10)},
    {540, STRING_TOKEN (STR_TIMEZONE_M9)},
    {480, STRING_TOKEN (STR_TIMEZONE_M8)},
    {420, STRING_TOKEN (STR_TIMEZONE_M7)},
    {360, STRING_TOKEN (STR_TIMEZONE_M6)},
    {300, STRING_TOKEN (STR_TIMEZONE_M5)},
    {270, STRING_TOKEN (STR_TIMEZONE_M430)},
    {240, STRING_TOKEN (STR_TIMEZONE_M4)},
    {210, STRING_TOKEN (STR_TIMEZONE_M330)},
    {180, STRING_TOKEN (STR_TIMEZONE_M3)},
    {120, STRING_TOKEN (STR_TIMEZONE_M2)},
    {60 , STRING_TOKEN (STR_TIMEZONE_M1)},
    {0   , STRING_TOKEN (STR_TIMEZONE_0)},
    {-60  , STRING_TOKEN (STR_TIMEZONE_P1)},
    {-120 , STRING_TOKEN (STR_TIMEZONE_P2)},
    {-180 , STRING_TOKEN (STR_TIMEZONE_P3)},
    {-210 , STRING_TOKEN (STR_TIMEZONE_P330)},
    {-240 , STRING_TOKEN (STR_TIMEZONE_P4)},
    {-270 , STRING_TOKEN (STR_TIMEZONE_P430)},
    {-300 , STRING_TOKEN (STR_TIMEZONE_P5)},
    {-330 , STRING_TOKEN (STR_TIMEZONE_P530)},
    {-345 , STRING_TOKEN (STR_TIMEZONE_P545)},
    {-360 , STRING_TOKEN (STR_TIMEZONE_P6)},
    {-390 , STRING_TOKEN (STR_TIMEZONE_P630)},
    {-420 , STRING_TOKEN (STR_TIMEZONE_P7)},
    {-480 , STRING_TOKEN (STR_TIMEZONE_P8)},
    {-540 , STRING_TOKEN (STR_TIMEZONE_P9)},
    {-570 , STRING_TOKEN (STR_TIMEZONE_P930)},
    {-600 , STRING_TOKEN (STR_TIMEZONE_P10)},
    {-660 , STRING_TOKEN (STR_TIMEZONE_P11)},
    {-720 , STRING_TOKEN (STR_TIMEZONE_P12)},
    {-780 , STRING_TOKEN (STR_TIMEZONE_P13)},
    {-840 , STRING_TOKEN (STR_TIMEZONE_P14)}
  };

SHELL_STATUS
EFIAPI
CheckAndSetTimeZone (
  IN CONST CHAR16 *TimeZoneString
  )
{
  EFI_TIME      TheTime;
  EFI_STATUS    Status;
  CONST CHAR16  *Walker;
  UINTN         LoopVar;

  if (TimeZoneString == NULL) {
    return (SHELL_INVALID_PARAMETER);
  }

  if (TimeZoneString != NULL && !InternalIsTimeLikeString(TimeZoneString, L':', 1, 1, TRUE)) {
    return (SHELL_INVALID_PARAMETER);
  }

  Status = gRT->GetTime(&TheTime, NULL);
  ASSERT_EFI_ERROR(Status);

  Walker = TimeZoneString;
  if (*Walker == L'-') {
    TheTime.TimeZone = (INT16)((StrDecimalToUintn (++Walker)) * 60);
  } else {
    TheTime.TimeZone = (INT16)((StrDecimalToUintn (Walker)) * -60);
  }
  Walker = StrStr(Walker, L":");
  if (Walker != NULL && *Walker == L':') {
    Walker = Walker + 1;
  }
  if (Walker != NULL && Walker[0] != CHAR_NULL) {
    if (TheTime.TimeZone < 0) {
      TheTime.TimeZone = (INT16)(TheTime.TimeZone - (UINT8)StrDecimalToUintn (Walker));
    } else {
      TheTime.TimeZone = (INT16)(TheTime.TimeZone + (UINT8)StrDecimalToUintn (Walker));
    }
  }

  Status = EFI_INVALID_PARAMETER;

  for ( LoopVar = 0
      ; LoopVar < sizeof(TimeZoneList) / sizeof(TimeZoneList[0])
      ; LoopVar++
     ){
    if (TheTime.TimeZone == TimeZoneList[LoopVar].TimeZone) {
        Status = gRT->SetTime(&TheTime);
        break;
    }
  }

  if (!EFI_ERROR(Status)){
    return (SHELL_SUCCESS);
  }
  return (SHELL_INVALID_PARAMETER);
}


/**
  Function for 'timezone' command.

  @param[in] ImageHandle  Handle to the Image (NULL if Internal).
  @param[in] SystemTable  Pointer to the System Table (NULL if Internal).
**/
SHELL_STATUS
EFIAPI
ShellCommandRunTimeZone (
  IN EFI_HANDLE        ImageHandle,
  IN EFI_SYSTEM_TABLE  *SystemTable
  )
{
  //
  // non interactive
  //
  EFI_STATUS    Status;
  LIST_ENTRY    *Package;
  CHAR16        *ProblemParam;
  SHELL_STATUS  ShellStatus;
  UINT8         LoopVar;
  EFI_TIME      TheTime;
  BOOLEAN       Found;
  UINTN         TzMinutes;

  ShellStatus  = SHELL_SUCCESS;
  ProblemParam = NULL;

  //
  // initialize the shell lib (we must be in non-auto-init...)
  //
  Status = ShellInitialize();
  ASSERT_EFI_ERROR(Status);

  //
  // parse the command line
  //
  if (PcdGet8(PcdShellSupportLevel) == 2) {
    Status = ShellCommandLineParse (TimeZoneParamList2, &Package, &ProblemParam, FALSE);
  } else {
    ASSERT(PcdGet8(PcdShellSupportLevel) == 3);
    Status = ShellCommandLineParseEx (TimeZoneParamList3, &Package, &ProblemParam, FALSE, TRUE);
  }
  if (EFI_ERROR(Status)) {
    if (Status == EFI_VOLUME_CORRUPTED && ProblemParam != NULL) {
      ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_GEN_PROBLEM), gShellLevel2HiiHandle, ProblemParam);
      FreePool(ProblemParam);
      ShellStatus = SHELL_INVALID_PARAMETER;
    } else {
      ASSERT(FALSE);
    }
  } else {
    //
    // check for "-?"
    //
    if (ShellCommandLineGetCount(Package) > 1) {
      ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_GEN_TOO_MANY), gShellLevel2HiiHandle);
      ShellStatus = SHELL_INVALID_PARAMETER;
    } else if (ShellCommandLineGetFlag(Package, L"-?")) {
      ASSERT(FALSE);
    } else if (ShellCommandLineGetFlag(Package, L"-s")) {
      if ((ShellCommandLineGetFlag(Package, L"-l")) || (ShellCommandLineGetFlag(Package, L"-f"))) {
        ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_GEN_PROBLEM), gShellLevel2HiiHandle, L"-l or -f");
        ShellStatus = SHELL_INVALID_PARAMETER;
      } else {
        ASSERT(PcdGet8(PcdShellSupportLevel) == 3);
        if (ShellCommandLineGetValue(Package, L"-s") == NULL) {
          ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_GEN_NO_VALUE), gShellLevel2HiiHandle, L"-s");
          ShellStatus = SHELL_INVALID_PARAMETER;
        } else {
          //
          // Set the time zone
          //
          ShellStatus = CheckAndSetTimeZone(ShellCommandLineGetValue(Package, L"-s"));
          if (ShellStatus != SHELL_SUCCESS) {
            ShellPrintHiiEx(-1, -1, NULL, STRING_TOKEN (STR_GEN_PROBLEM), gShellLevel2HiiHandle, ShellCommandLineGetValue(Package, L"-s"));
            ShellStatus = SHELL_INVALID_PARAMETER;
          }
        }
      }
    } else if (ShellCommandLineGetFlag(Package, L"-l")) {
      //
      // Print a list of all time zones
      //
      for ( LoopVar = 0
          ; LoopVar < sizeof(TimeZoneList) / sizeof(TimeZoneList[0])
          ; LoopVar++
         ){
        ShellPrintHiiEx (-1, -1, NULL, TimeZoneList[LoopVar].StringId, gShellLevel2HiiHandle);
      }
    } else {
      //
      // Get Current Time Zone Info
      //
      Status = gRT->GetTime(&TheTime, NULL);
      ASSERT_EFI_ERROR(Status);

      if (TheTime.TimeZone != 2047) {
        Found = FALSE;
        for ( LoopVar = 0
            ; LoopVar < sizeof(TimeZoneList) / sizeof(TimeZoneList[0])
            ; LoopVar++
           ){
          if (TheTime.TimeZone == TimeZoneList[LoopVar].TimeZone) {
            if (ShellCommandLineGetFlag(Package, L"-f")) {
              //
              //  Print all info about current time zone
              //
              ShellPrintHiiEx (-1, -1, NULL, TimeZoneList[LoopVar].StringId, gShellLevel2HiiHandle);
            } else {
              //
              // Print basic info only
              //
              if (TheTime.TimeZone == 2047) {
                TzMinutes = 0;
              } else {
                TzMinutes = AbsVal(TheTime.TimeZone) % 60;
              }

              ShellPrintHiiEx (
                -1,
                -1,
                NULL,
                STRING_TOKEN(STR_TIMEZONE_SIMPLE),
                gShellLevel2HiiHandle,
                TheTime.TimeZone==2047?0:(TheTime.TimeZone > 0?L"-":L"+"),
                TheTime.TimeZone==2047?0:AbsVal(TheTime.TimeZone) / 60,
                TzMinutes);
            }
            Found = TRUE;
            break;
          }
        }
        if (!Found) {
          //
          // Print basic info only
          //
          if (TheTime.TimeZone == 2047) {
            TzMinutes = 0;
          } else {
            TzMinutes = AbsVal(TheTime.TimeZone) % 60;
          }
          ShellPrintHiiEx (
            -1,
            -1,
            NULL,
            STRING_TOKEN(STR_TIMEZONE_SIMPLE),
            gShellLevel2HiiHandle,
            TheTime.TimeZone==2047?0:(TheTime.TimeZone > 0?L"-":L"+"),
            TheTime.TimeZone==2047?0:AbsVal(TheTime.TimeZone) / 60,
            TzMinutes);
          if (ShellCommandLineGetFlag(Package, L"-f")) {
            ShellPrintHiiEx (-1, -1, NULL, STRING_TOKEN(STR_TIMEZONE_NI), gShellLevel2HiiHandle);
          }
        }
      } else {
        //
        // TimeZone was 2047 (unknown) from GetTime()
        //
      }
    }
  }

  //
  // free the command line package
  //
  ShellCommandLineFreeVarList (Package);

  return (ShellStatus);
}
