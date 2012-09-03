/** @file
  Function prototype for USB Keyboard Driver.

Copyright (c) 2004 - 2008, Intel Corporation. All rights reserved.<BR>
This program and the accompanying materials
are licensed and made available under the terms and conditions of the BSD License
which accompanies this distribution.  The full text of the license may be found at
http://opensource.org/licenses/bsd-license.php

THE PROGRAM IS DISTRIBUTED UNDER THE BSD LICENSE ON AN "AS IS" BASIS,
WITHOUT WARRANTIES OR REPRESENTATIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED.

**/

#ifndef _EFI_KEYBOARD_H_
#define _EFI_KEYBOARD_H_


#include "EfiKey.h"

#define USB_KEYBOARD_LAYOUT_PACKAGE_GUID \
  { \
    0xc0f3b43, 0x44de, 0x4907, { 0xb4, 0x78, 0x22, 0x5f, 0x6f, 0x62, 0x89, 0xdc } \
  }

#define USB_KEYBOARD_LAYOUT_KEY_GUID \
  { \
    0x3a4d7a7c, 0x18a, 0x4b42, { 0x81, 0xb3, 0xdc, 0x10, 0xe3, 0xb5, 0x91, 0xbd } \
  }

#define USB_KEYBOARD_KEY_COUNT            104

#define USB_KEYBOARD_LANGUAGE_STR_LEN     5         // RFC4646 Language Code: "en-US"
#define USB_KEYBOARD_DESCRIPTION_STR_LEN  (16 + 1)  // Description: "English Keyboard"

#pragma pack (1)
typedef struct {
  //
  // This 4-bytes total array length is required by PreparePackageList()
  //
  UINT32                 Length;

  //
  // Keyboard Layout package definition
  //
  EFI_HII_PACKAGE_HEADER PackageHeader;
  UINT16                 LayoutCount;

  //
  // EFI_HII_KEYBOARD_LAYOUT
  //
  UINT16                 LayoutLength;
  EFI_GUID               Guid;
  UINT32                 LayoutDescriptorStringOffset;
  UINT8                  DescriptorCount;
  EFI_KEY_DESCRIPTOR     KeyDescriptor[USB_KEYBOARD_KEY_COUNT];
  UINT16                 DescriptionCount;
  CHAR16                 Language[USB_KEYBOARD_LANGUAGE_STR_LEN];
  CHAR16                 Space;
  CHAR16                 DescriptionString[USB_KEYBOARD_DESCRIPTION_STR_LEN];
} USB_KEYBOARD_LAYOUT_PACK_BIN;
#pragma pack()
/**
  Uses USB I/O to check whether the device is a USB keyboard device.

  @param  UsbIo    Pointer to a USB I/O protocol instance.

  @retval TRUE     Device is a USB keyboard device.
  @retval FALSE    Device is a not USB keyboard device.

**/
BOOLEAN
EFIAPI
IsUSBKeyboard (
  IN  EFI_USB_IO_PROTOCOL       *UsbIo
  );

/**
  Initialize USB keyboard device and all private data structures.

  @param  UsbKeyboardDevice  The USB_KB_DEV instance.

  @retval EFI_SUCCESS        Initialization is successful.
  @retval EFI_DEVICE_ERROR   Keyboard initialization failed.

**/
EFI_STATUS
EFIAPI
InitUSBKeyboard (
  IN OUT USB_KB_DEV   *UsbKeyboardDevice
  );

/**
  Initialize USB keyboard layout.

  This function initializes Key Convertion Table for the USB keyboard device.
  It first tries to retrieve layout from HII database. If failed and default
  layout is enabled, then it just uses the default layout.

  @param  UsbKeyboardDevice      The USB_KB_DEV instance.

  @retval EFI_SUCCESS            Initialization succeeded.
  @retval EFI_NOT_READY          Keyboard layout cannot be retrieve from HII
                                 database, and default layout is disabled.
  @retval Other                  Fail to register event to EFI_HII_SET_KEYBOARD_LAYOUT_EVENT_GUID group.

**/
EFI_STATUS
EFIAPI
InitKeyboardLayout (
  OUT USB_KB_DEV   *UsbKeyboardDevice
  );

/**
  Destroy resources for keyboard layout.

  @param  UsbKeyboardDevice    The USB_KB_DEV instance.

**/
VOID
EFIAPI
ReleaseKeyboardLayoutResources (
  IN OUT USB_KB_DEV              *UsbKeyboardDevice
  );

/**
  Handler function for USB keyboard's asynchronous interrupt transfer.

  This function is the handler function for USB keyboard's asynchronous interrupt transfer
  to manage the keyboard. It parses the USB keyboard input report, and inserts data to
  keyboard buffer according to state of modifer keys and normal keys. Timer for repeat key
  is also set accordingly.

  @param  Data             A pointer to a buffer that is filled with key data which is
                           retrieved via asynchronous interrupt transfer.
  @param  DataLength       Indicates the size of the data buffer.
  @param  Context          Pointing to USB_KB_DEV instance.
  @param  Result           Indicates the result of the asynchronous interrupt transfer.

  @retval EFI_SUCCESS      Asynchronous interrupt transfer is handled successfully.
  @retval EFI_DEVICE_ERROR Hardware error occurs.

**/
EFI_STATUS
EFIAPI
KeyboardHandler (
  IN  VOID          *Data,
  IN  UINTN         DataLength,
  IN  VOID          *Context,
  IN  UINT32        Result
  );

/**
  Handler for Delayed Recovery event.

  This function is the handler for Delayed Recovery event triggered
  by timer.
  After a device error occurs, the event would be triggered
  with interval of EFI_USB_INTERRUPT_DELAY. EFI_USB_INTERRUPT_DELAY
  is defined in USB standard for error handling.

  @param  Event              The Delayed Recovery event.
  @param  Context            Points to the USB_KB_DEV instance.

**/
VOID
EFIAPI
USBKeyboardRecoveryHandler (
  IN    EFI_EVENT    Event,
  IN    VOID         *Context
  );

/**
  Retrieves a USB keycode after parsing the raw data in keyboard buffer.

  This function parses keyboard buffer. It updates state of modifier key for
  USB_KB_DEV instancem, and returns keycode for output.

  @param  UsbKeyboardDevice    The USB_KB_DEV instance.
  @param  KeyCode              Pointer to the USB keycode for output.

  @retval EFI_SUCCESS          Keycode successfully parsed.
  @retval EFI_NOT_READY        Keyboard buffer is not ready for a valid keycode

**/
EFI_STATUS
EFIAPI
USBParseKey (
  IN OUT  USB_KB_DEV  *UsbKeyboardDevice,
  OUT     UINT8       *KeyCode
  );

/**
  Converts USB Keycode ranging from 0x4 to 0x65 to EFI_INPUT_KEY.

  @param  UsbKeyboardDevice     The USB_KB_DEV instance.
  @param  KeyCode               Indicates the key code that will be interpreted.
  @param  Key                   A pointer to a buffer that is filled in with
                                the keystroke information for the key that
                                was pressed.

  @retval EFI_SUCCESS           Success.
  @retval EFI_INVALID_PARAMETER KeyCode is not in the range of 0x4 to 0x65.
  @retval EFI_INVALID_PARAMETER Translated EFI_INPUT_KEY has zero for both ScanCode and UnicodeChar.
  @retval EFI_NOT_READY         KeyCode represents a dead key with EFI_NS_KEY_MODIFIER
  @retval EFI_DEVICE_ERROR      Keyboard layout is invalid.

**/
EFI_STATUS
EFIAPI
UsbKeyCodeToEfiInputKey (
  IN  USB_KB_DEV      *UsbKeyboardDevice,
  IN  UINT8           KeyCode,
  OUT EFI_INPUT_KEY   *Key
  );

/**
  Resets USB keyboard buffer.

  @param  KeyboardBuffer     Points to the USB keyboard buffer.

**/
VOID
EFIAPI
InitUSBKeyBuffer (
  OUT  USB_KB_BUFFER   *KeyboardBuffer
  );

/**
  Check whether USB keyboard buffer is empty.

  @param  KeyboardBuffer     USB keyboard buffer

  @retval TRUE               Keyboard buffer is empty.
  @retval FALSE              Keyboard buffer is not empty.

**/
BOOLEAN
EFIAPI
IsUSBKeyboardBufferEmpty (
  IN  USB_KB_BUFFER   *KeyboardBuffer
  );

/**
  Check whether USB keyboard buffer is full.

  @param  KeyboardBuffer     USB keyboard buffer

  @retval TRUE               Keyboard buffer is full.
  @retval FALSE              Keyboard buffer is not full.

**/
BOOLEAN
EFIAPI
IsUSBKeyboardBufferFull (
  IN  USB_KB_BUFFER   *KeyboardBuffer
  );

/**
  Inserts a keycode into keyboard buffer.

  @param  KeyboardBuffer     Points to the USB keyboard buffer.
  @param  Key                Keycode to insert.
  @param  Down               TRUE means key is pressed.
                             FALSE means key is released.

**/
VOID
EFIAPI
InsertKeyCode (
  IN OUT  USB_KB_BUFFER *KeyboardBuffer,
  IN      UINT8         Key,
  IN      BOOLEAN       Down
  );

/**
  Remove a keycode from keyboard buffer and return it.

  @param  KeyboardBuffer     Points to the USB keyboard buffer.
  @param  UsbKey             Points to the buffer that contains keycode for output.

  @retval EFI_SUCCESS        Keycode successfully removed from keyboard buffer.
  @retval EFI_DEVICE_ERROR   Keyboard buffer is empty.

**/
EFI_STATUS
EFIAPI
RemoveKeyCode (
  IN OUT  USB_KB_BUFFER *KeyboardBuffer,
     OUT  USB_KEY       *UsbKey
  );

/**
  Handler for Repeat Key event.

  This function is the handler for Repeat Key event triggered
  by timer.
  After a repeatable key is pressed, the event would be triggered
  with interval of USBKBD_REPEAT_DELAY. Once the event is triggered,
  following trigger will come with interval of USBKBD_REPEAT_RATE.

  @param  Event              The Repeat Key event.
  @param  Context            Points to the USB_KB_DEV instance.

**/
VOID
EFIAPI
USBKeyboardRepeatHandler (
  IN    EFI_EVENT    Event,
  IN    VOID         *Context
  );

/**
  Sets USB keyboard LED state.

  @param  UsbKeyboardDevice  The USB_KB_DEV instance.

**/
VOID
EFIAPI
SetKeyLED (
  IN  USB_KB_DEV    *UsbKeyboardDevice
  );

#endif
