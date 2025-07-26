#include <ntddk.h>
#include <ntstrsafe.h>
#define KDB_DRIVER_NAME L"\\Driver\\Kbdclass"
#define DELAY_ONE_MILLISECOND -10
#define LAG_MITIGATION_THRESHOLD_MS 50  // Threshold in milliseconds to filter duplicate keys
#define MAX_TRACKED_KEYS 256  // Maximum number of recent key events to track

ULONG gC2pKeyCount;

// Structure to track recent key events for lag mitigation
typedef struct _KEY_EVENT_TRACKER {
    USHORT MakeCode;
    USHORT Flags;
    LARGE_INTEGER Timestamp;
    BOOLEAN InUse;
} KEY_EVENT_TRACKER, *PKEY_EVENT_TRACKER;

// Global array to track recent key events
KEY_EVENT_TRACKER gRecentKeyEvents[MAX_TRACKED_KEYS];
ULONG gKeyEventIndex = 0;
KSPIN_LOCK gKeyTrackerSpinLock;
NTSTATUS
ObReferenceObjectByName(
	PUNICODE_STRING ObjectName,
	ULONG Attributes,
	PACCESS_STATE PassedAccessState,
	ACCESS_MASK DesiredAccess,
	POBJECT_TYPE ObjectType,
	KPROCESSOR_MODE AccessMode,
	PVOID ParseContext,
	PVOID *Object);
extern POBJECT_TYPE IoDriverObjectType;
typedef struct _C2P_DEV_EXT
{
	ULONG NodeSize;
	PDEVICE_OBJECT pFilterDeviceObject;
	KSPIN_LOCK IoRequestspinLock;
	KEVENT IoInProgressEvent;
	PDEVICE_OBJECT TargetDeviceObject;
	PDEVICE_OBJECT LowerDeviceObject;
}C2P_DEV_EXT,*PC2P_DEV_EXT;
typedef struct _KEYBOARD_INPUT_DATA{
	USHORT UnitId;
	USHORT MakeCode;
	USHORT Flags;
	USHORT Reserved;
	ULONG ExtraInformation;
}KEYBOARD_INPUT_DATA,*PKEYBOARD_INPUT_DATA;
VOID MakeCodeToASCII(USHORT MakeCode,USHORT Flags,PCHAR Ascii)//Ascii is 16 bytes
{
	if(Flags>=2)
	{
		if(Flags==2)
		{
			switch(MakeCode)
			{
			case 0x2a:
				{
					RtlStringCchCopyA(Ascii, 16, " ");
					break;
				}
			case 0x5b:
			case 0x5c:
				{
					RtlStringCchCopyA(Ascii, 16, "Windows Key");
					break;
				}
			case 0x48:
				{
					RtlStringCchCopyA(Ascii, 16, "Up Key");
					break;
				}
			case 0x50:
				{
					RtlStringCchCopyA(Ascii, 16, "Down Key");
					break;
				}
			case 0x4b:
				{
					RtlStringCchCopyA(Ascii, 16, "Left Key");
					break;
				}
			case 0x4d:
				{
					RtlStringCchCopyA(Ascii, 16, "Right Key");
					break;
				}
			case 0x53:
				{
					RtlStringCchCopyA(Ascii, 16, "Del Key");
					break;
				}
			default:
				{
					RtlStringCchCopyA(Ascii, 16, "Error");
					break;
				}
			}
		}
		if(Flags==3)
		{
			switch(MakeCode)
			{
			case 0x2a:
				{
					RtlStringCchCopyA(Ascii, 16, " ");
					break;
				}
			case 0x5b:
			case 0x5c:
				{
					RtlStringCchCopyA(Ascii, 16, "Windows Key");
					break;
				}
			case 0x48:
				{
					RtlStringCchCopyA(Ascii, 16, "Up Key");
					break;
				}
			case 0x50:
				{
					RtlStringCchCopyA(Ascii, 16, "Down Key");
					break;
				}
			case 0x4b:
				{
					RtlStringCchCopyA(Ascii, 16, "Left Key");
					break;
				}
			case 0x4d:
				{
					RtlStringCchCopyA(Ascii, 16, "Right Key");
					break;
				}
			case 0x53:
				{
					RtlStringCchCopyA(Ascii, 16, "Del Key");
					break;
				}
			default:
				{
					RtlStringCchCopyA(Ascii, 16, "Error");
					break;
				}
			}
		}
		return;
	}
	switch(MakeCode)
	{
	case 0x1d:
		{
			RtlStringCchCopyA(Ascii, 12, "Ctrl");
			break;
		}
	case 0x1c:
		{
			RtlStringCchCopyA(Ascii, 12, "Enter");
			break;
		}
	case 0x3a:
		{
			RtlStringCchCopyA(Ascii, 12, "CapsLock");
			break;
		}
	case 0x2a:
	case 0x36:
		{
			RtlStringCchCopyA(Ascii, 12, "Shift");
			break;
		}
	case 0x02:
		{
			RtlStringCchCopyA(Ascii, 12, "1");
			break;
		}
	case 0x4f:
		{
			RtlStringCchCopyA(Ascii, 12, "Num1");
			break;
		}
	case 0x03:
		{
			RtlStringCchCopyA(Ascii, 12, "2");
			break;
		}
	case 0x50:
		{
			RtlStringCchCopyA(Ascii, 12, "Num2");
			break;
		}
	case 0x04:
		{
			RtlStringCchCopyA(Ascii, 12, "3");
			break;
		}
	case 0x51:
		{
			RtlStringCchCopyA(Ascii, 12, "Num3");
			break;
		}
	case 0x05:
		{
			RtlStringCchCopyA(Ascii, 12, "4");
			break;
		}
	case 0x4b:
		{
			RtlStringCchCopyA(Ascii, 12, "Num4");
			break;
		}
	case 0x06:
		{
			RtlStringCchCopyA(Ascii, 12, "5");
			break;
		}
	case 0x4c:
		{
			RtlStringCchCopyA(Ascii, 12, "Num5");
			break;
		}
	case 0x07:
		{
			RtlStringCchCopyA(Ascii, 12, "6");
			break;
		}
	case 0x4d:
		{
			RtlStringCchCopyA(Ascii, 12, "Num6");
			break;
		}
	case 0x08:
		{
			RtlStringCchCopyA(Ascii, 12, "7");
			break;
		}
	case 0x47:
		{
			RtlStringCchCopyA(Ascii, 12, "Num7");
			break;
		}
	case 0x09:
		{
			RtlStringCchCopyA(Ascii, 12, "8");
			break;
		}
	case 0x48:
		{
			RtlStringCchCopyA(Ascii, 12, "Num8");
			break;
		}
	case 0x0a:
		{
			RtlStringCchCopyA(Ascii, 12, "9");
			break;
		}
	case 0x49:
		{
			RtlStringCchCopyA(Ascii, 12, "Num9");
			break;
		}
	case 0x0b:
		{
			RtlStringCchCopyA(Ascii, 12, "0");
			break;
		}
	case 0x52:
		{
			RtlStringCchCopyA(Ascii, 12, "Num0");
			break;
		}
	case 0x1e:
		{
			RtlStringCchCopyA(Ascii, 12, "a");
			break;
		}
	case 0x30:
		{
			RtlStringCchCopyA(Ascii, 12, "b");
			break;
		}
	case 0x2e:
		{
			RtlStringCchCopyA(Ascii, 12, "c");
			break;
		}
	case 0x20:
		{
			RtlStringCchCopyA(Ascii, 12, "d");
			break;
		}
	case 0x12:
		{
			RtlStringCchCopyA(Ascii, 12, "e");
			break;
		}
	case 0x21:
		{
			RtlStringCchCopyA(Ascii, 12, "f");
			break;
		}
	case 0x22:
		{
			RtlStringCchCopyA(Ascii, 12, "g");
			break;
		}
	case 0x23:
		{
			RtlStringCchCopyA(Ascii, 12, "h");
			break;
		}
	case 0x17:
		{
			RtlStringCchCopyA(Ascii, 12, "i");
			break;
		}
	case 0x24:
		{
			RtlStringCchCopyA(Ascii, 12, "j");
			break;
		}
	case 0x25:
		{
			RtlStringCchCopyA(Ascii, 12, "k");
			break;
		}
	case 0x26:
		{
			RtlStringCchCopyA(Ascii, 12, "l");
			break;
		}
	case 0x32:
		{
			RtlStringCchCopyA(Ascii, 12, "m");
			break;
		}
	case 0x31:
		{
			RtlStringCchCopyA(Ascii, 12, "n");
			break;
		}
	case 0x18:
		{
			RtlStringCchCopyA(Ascii, 12, "o");
			break;
		}
	case 0x19:
		{
			RtlStringCchCopyA(Ascii, 12, "p");
			break;
		}
	case 0x10:
		{
			RtlStringCchCopyA(Ascii, 12, "q");
			break;
		}
	case 0x13:
		{
			RtlStringCchCopyA(Ascii, 12, "r");
			break;
		}
	case 0x1f:
		{
			RtlStringCchCopyA(Ascii, 12, "s");
			break;
		}
	case 0x14:
		{
			RtlStringCchCopyA(Ascii, 12, "t");
			break;
		}
	case 0x16:
		{
			RtlStringCchCopyA(Ascii, 12, "u");
			break;
		}
	case 0x2f:
		{
			RtlStringCchCopyA(Ascii, 12, "v");
			break;
		}
	case 0x11:
		{
			RtlStringCchCopyA(Ascii, 12, "w");
			break;
		}
	case 0x2d:
		{
			RtlStringCchCopyA(Ascii, 12, "x");
			break;
		}
	case 0x15:
		{
			RtlStringCchCopyA(Ascii, 12, "y");
			break;
		}
	case 0x2c:
		{
			RtlStringCchCopyA(Ascii, 12, "z");
			break;
		}
	case 0x39:
		{
			RtlStringCchCopyA(Ascii, 12, "Space");
			break;
		}
	case 0x0e:
		{
			RtlStringCchCopyA(Ascii, 12, "BackSpace");
			break;
		}
	case 0x0f:
		{
			RtlStringCchCopyA(Ascii, 12, "Tab");
			break;
		}
	case 0x45:
		{
			RtlStringCchCopyA(Ascii, 12, "NumLock");
			break;
		}
	case 0x33:
		{
			RtlStringCchCopyA(Ascii, 12, ",");
			break;
		}
	case 0x34:
		{
			RtlStringCchCopyA(Ascii, 12, ".");
			break;
		}
	case 0x35:
		{
			RtlStringCchCopyA(Ascii, 12, "/");
			break;
		}
	case 0x27:
		{
			RtlStringCchCopyA(Ascii, 12, ";");
			break;
		}
	case 0x28:
		{
			RtlStringCchCopyA(Ascii, 12, "'");
			break;
		}
	case 0x1a:
		{
			RtlStringCchCopyA(Ascii, 12, "[");
			break;
		}
	case 0x1b:
		{
			RtlStringCchCopyA(Ascii, 12, "]");
			break;
		}
	case 0x2b:
		{
			RtlStringCchCopyA(Ascii, 12, "\\");
			break;
		}
	case 0x0c:
		{
			RtlStringCchCopyA(Ascii, 12, "-");
			break;
		}
	case 0x0d:
		{
			RtlStringCchCopyA(Ascii, 12, "=");
			break;
		}
	default:
		{
			RtlStringCchCopyA(Ascii, 12, "Error");
			return;
		}
	}
	if(Flags==0)
	{
		RtlStringCchCatA(Ascii, 16, " Down");
	}
	else
	{
		RtlStringCchCatA(Ascii, 16, " Up");
	}
	return;
}

// Function to check if a key event is a duplicate (lag-induced)
BOOLEAN IsLagInducedDuplicate(USHORT MakeCode, USHORT Flags)
{
    LARGE_INTEGER CurrentTime;
    LARGE_INTEGER TimeDifference;
    ULONG i;
    KIRQL OldIrql;
    BOOLEAN IsDuplicate = FALSE;
    
    // Only check for duplicates on key press events (not releases)
    if (Flags != 0) {
        return FALSE;
    }
    
    KeQuerySystemTime(&CurrentTime);
    
    KeAcquireSpinLock(&gKeyTrackerSpinLock, &OldIrql);
    
    // Check recent key events for duplicates
    for (i = 0; i < MAX_TRACKED_KEYS; i++) {
        if (gRecentKeyEvents[i].InUse && 
            gRecentKeyEvents[i].MakeCode == MakeCode &&
            gRecentKeyEvents[i].Flags == Flags) {
            
            TimeDifference.QuadPart = CurrentTime.QuadPart - gRecentKeyEvents[i].Timestamp.QuadPart;
            // Convert to milliseconds (100ns units to ms)
            TimeDifference.QuadPart = TimeDifference.QuadPart / 10000;
            
            if (TimeDifference.QuadPart < LAG_MITIGATION_THRESHOLD_MS) {
                IsDuplicate = TRUE;
                break;
            }
        }
    }
    
    // Add current event to tracking array if not a duplicate
    if (!IsDuplicate) {
        gRecentKeyEvents[gKeyEventIndex].MakeCode = MakeCode;
        gRecentKeyEvents[gKeyEventIndex].Flags = Flags;
        gRecentKeyEvents[gKeyEventIndex].Timestamp = CurrentTime;
        gRecentKeyEvents[gKeyEventIndex].InUse = TRUE;
        
        gKeyEventIndex = (gKeyEventIndex + 1) % MAX_TRACKED_KEYS;
    }
    
    KeReleaseSpinLock(&gKeyTrackerSpinLock, OldIrql);
    
    return IsDuplicate;
}

VOID DriverUnload(PDRIVER_OBJECT driver)
{
	PC2P_DEV_EXT devExt;
	PDEVICE_OBJECT DeviceObject;
	LARGE_INTEGER lDelay;
	PRKTHREAD CurrentThread;
	lDelay=RtlConvertLongToLargeInteger(100*DELAY_ONE_MILLISECOND);
	CurrentThread=KeGetCurrentThread();
	KeSetPriorityThread(CurrentThread,LOW_REALTIME_PRIORITY);
	UNREFERENCED_PARAMETER(driver);
	DeviceObject=driver->DeviceObject;
	while(DeviceObject)
	{
		devExt=(PC2P_DEV_EXT)(DeviceObject->DeviceExtension);
		IoDetachDevice(devExt->LowerDeviceObject);
		IoDeleteDevice(DeviceObject);
		DeviceObject=DeviceObject->NextDevice;
	}
	ASSERT(NULL==driver->DeviceObject);
	while(gC2pKeyCount)
	{
		KeDelayExecutionThread(KernelMode,FALSE,&lDelay);
	}
	DbgPrint("Keyboard Filter Driver: Driver unloaded");
	return;
}
NTSTATUS kbDispatchGeneral(PDEVICE_OBJECT DeviceObject,PIRP Irp)
{
	DbgPrint("Keyboard Filter Driver: General message");
	IoSkipCurrentIrpStackLocation(Irp);
	return IoCallDriver(((PC2P_DEV_EXT)DeviceObject->DeviceExtension)->LowerDeviceObject,Irp);
}
NTSTATUS kbpower(PDEVICE_OBJECT DeviceObject,PIRP Irp)
{
	PC2P_DEV_EXT devExt;
	PoStartNextPowerIrp(Irp);
	IoSkipCurrentIrpStackLocation(Irp);
	devExt=(PC2P_DEV_EXT)DeviceObject->DeviceExtension;
	return PoCallDriver(devExt->LowerDeviceObject,Irp);
}
NTSTATUS kbpnp(PDEVICE_OBJECT DeviceObject,PIRP Irp)
{
	NTSTATUS status=STATUS_SUCCESS;
	PC2P_DEV_EXT devExt;
	PIO_STACK_LOCATION irpstack;
	devExt=(PC2P_DEV_EXT)(DeviceObject->DeviceExtension);
	irpstack=IoGetCurrentIrpStackLocation(Irp);
	switch(irpstack->MinorFunction)
	{
	case IRP_MN_REMOVE_DEVICE:
		{
			DbgPrint("Keyboard Filter Driver: USB device removed (PNP event)");
			IoSkipCurrentIrpStackLocation(Irp);
			IoCallDriver(devExt->LowerDeviceObject,Irp);
			IoDetachDevice(devExt->LowerDeviceObject);
			IoDeleteDevice(DeviceObject);
			status=STATUS_SUCCESS;
			break;
		}
	default:
		{
			IoSkipCurrentIrpStackLocation(Irp);
			status=IoCallDriver(devExt->LowerDeviceObject,Irp);
			break;
		}
	}
	return status;
}
NTSTATUS kbReadComplete(PDEVICE_OBJECT DeviceObject,PIRP Irp,PVOID Context)
{
	PIO_STACK_LOCATION stackirp;
	ULONG buf_len=0;
	ULONG i;
	PKEYBOARD_INPUT_DATA KeyData;
	PKEYBOARD_INPUT_DATA FilteredKeyData;
	PCHAR Ascii="1234567890123456";
	stackirp=IoGetCurrentIrpStackLocation(Irp);
	if(NT_SUCCESS(Irp->IoStatus.Status))
	{
		buf_len=Irp->IoStatus.Information/sizeof(KEYBOARD_INPUT_DATA);
		KeyData=Irp->AssociatedIrp.SystemBuffer;
		
		// Create a temporary buffer for filtered key data
		FilteredKeyData = (PKEYBOARD_INPUT_DATA)ExAllocatePoolWithTag(NonPagedPool, 
			buf_len * sizeof(KEYBOARD_INPUT_DATA), 'FKey');
		
		if (FilteredKeyData) {
			ULONG FilteredCount = 0;
			// Process each key event and filter out lag-induced duplicates
			for(i=0;i<buf_len;i++)
			{
				if (!IsLagInducedDuplicate(KeyData[i].MakeCode, KeyData[i].Flags)) {
					// Not a duplicate, include in filtered data
					FilteredKeyData[FilteredCount] = KeyData[i];
					FilteredCount++;
					
					MakeCodeToASCII(KeyData[i].MakeCode,KeyData[i].Flags,Ascii);
					DbgPrint("Keyboard Filter Driver: %s",Ascii);
				} else {
					// Filtered out duplicate key event
					MakeCodeToASCII(KeyData[i].MakeCode,KeyData[i].Flags,Ascii);
					DbgPrint("Keyboard Filter Driver: Filtered duplicate key: %s",Ascii);
				}
			}
			
			// Copy filtered data back to the original buffer
			for (i = 0; i < FilteredCount; i++) {
				KeyData[i] = FilteredKeyData[i];
			}
			
			// Update the information field with the new count
			Irp->IoStatus.Information = FilteredCount * sizeof(KEYBOARD_INPUT_DATA);
			
			ExFreePoolWithTag(FilteredKeyData, 'FKey');
		} else {
			// If allocation failed, process without filtering
			for(i=0;i<buf_len;i++)
			{
				MakeCodeToASCII(KeyData[i].MakeCode,KeyData[i].Flags,Ascii);
				DbgPrint("Keyboard Filter Driver: %s",Ascii);
			}
		}
	}
	gC2pKeyCount--;
	if(Irp->PendingReturned)
	{
		IoMarkIrpPending(Irp);
	}
	return Irp->IoStatus.Status;
}
NTSTATUS kbread(PDEVICE_OBJECT DeviceObject,PIRP Irp)
{
	NTSTATUS status=STATUS_SUCCESS;
	PC2P_DEV_EXT devExt;
	PIO_STACK_LOCATION currentirpstack;
	KEVENT waitEvent;
	KeInitializeEvent(&waitEvent,NotificationEvent,FALSE);
	if(Irp->CurrentLocation==1)
	{
		DbgPrint("Keyboard Filter Driver: Invalid current IRP stack location");
		status=STATUS_INVALID_DEVICE_REQUEST;
		Irp->IoStatus.Status=status;
		Irp->IoStatus.Information=0;
		IoCompleteRequest(Irp,IO_NO_INCREMENT);
		return status;
	}
	gC2pKeyCount++;
	devExt=(PC2P_DEV_EXT)(DeviceObject->DeviceExtension);
	currentirpstack=IoGetCurrentIrpStackLocation(Irp);
	IoCopyCurrentIrpStackLocationToNext(Irp);
	IoSetCompletionRoutine(Irp,kbReadComplete,DeviceObject,TRUE,TRUE,TRUE);
	return IoCallDriver(devExt->LowerDeviceObject,Irp);
}
NTSTATUS DriverEntry(PDRIVER_OBJECT driver,PUNICODE_STRING RegistryPath)
{
	ULONG i;
	UNICODE_STRING kbdname;
	NTSTATUS status;
	PDRIVER_OBJECT kbddriver=NULL;
	PC2P_DEV_EXT devExt;
	
	PDEVICE_OBJECT pFilterDriver=NULL;//Filter device
	PDEVICE_OBJECT pTargetDriver=NULL;//Target device
	PDEVICE_OBJECT pLowerDriver=NULL;//Lower device

	DbgPrint("Keyboard Filter Driver: Driver loaded");
	
	
	
	gC2pKeyCount=0;
	
	// Initialize key event tracking for lag mitigation
	KeInitializeSpinLock(&gKeyTrackerSpinLock);
	for(i=0;i<MAX_TRACKED_KEYS;i++)
	{
		gRecentKeyEvents[i].InUse = FALSE;
	}
	gKeyEventIndex = 0;
	
	for(i=0;i<IRP_MJ_MAXIMUM_FUNCTION;i++)
	{
		driver->MajorFunction[i]=kbDispatchGeneral;
	}
	driver->MajorFunction[IRP_MJ_READ]=kbread;
	driver->MajorFunction[IRP_MJ_POWER]=kbpower;
	driver->MajorFunction[IRP_MJ_PNP]=kbpnp;
	driver->DriverUnload=DriverUnload;
	RtlInitUnicodeString(&kbdname,KDB_DRIVER_NAME);
	status=ObReferenceObjectByName(&kbdname,OBJ_CASE_INSENSITIVE,NULL,FILE_ALL_ACCESS,IoDriverObjectType,KernelMode,NULL,&kbddriver);
	if(!NT_SUCCESS(status))
	{
		DbgPrint("Keyboard Filter Driver: ObReferenceObjectByName failed");
		return(status);
	}

	pTargetDriver=kbddriver->DeviceObject;
	while(pTargetDriver)
	{
		status=IoCreateDevice(driver,sizeof(C2P_DEV_EXT),NULL,pTargetDriver->DeviceType,pTargetDriver->Characteristics,FALSE,&pFilterDriver);
		if(!NT_SUCCESS(status))
		{
			DbgPrint("Keyboard Filter Driver: Failed to create filter device");
			ObDereferenceObject(kbddriver);
			return status;
		}
		pLowerDriver=IoAttachDeviceToDeviceStack(pFilterDriver,pTargetDriver);
		if(!pLowerDriver)
		{
			DbgPrint("Keyboard Filter Driver: Failed to attach device");
			IoDeleteDevice(pFilterDriver);
			pFilterDriver=NULL;
			ObDereferenceObject(kbddriver);
			return status;
		}
		devExt=(PC2P_DEV_EXT)(pFilterDriver->DeviceExtension);
		memset(devExt,0,sizeof(C2P_DEV_EXT));
		devExt->NodeSize=sizeof(C2P_DEV_EXT);
		//KeInitializeSpinLock - reference to Windows kernel system function
		KeInitializeSpinLock(&(devExt->IoRequestspinLock));
		KeInitializeEvent(&(devExt->IoInProgressEvent),NotificationEvent,FALSE);
		devExt->TargetDeviceObject=pTargetDriver;
		devExt->LowerDeviceObject=pLowerDriver;
		pFilterDriver->DeviceType=pLowerDriver->DeviceType;
		pFilterDriver->Characteristics=pLowerDriver->Characteristics;
		pFilterDriver->StackSize=pLowerDriver->StackSize+1;
		pFilterDriver->Flags|=pLowerDriver->Flags&(DO_BUFFERED_IO|DO_DIRECT_IO|DO_POWER_PAGABLE);
		pTargetDriver=pTargetDriver->NextDevice;
	}
	
	// Dereference the keyboard class driver object after we're done using it
	ObDereferenceObject(kbddriver);
	
	return STATUS_SUCCESS;
}