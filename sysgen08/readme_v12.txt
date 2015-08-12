V1.2 changes
-----------
- revamp routines to only use files included with the assembler (no longer uses MPLAB .dev files).
	uses the '8bit_device.info' file and the asm .INC files, making the generator compatible with 
	either MPASM or MPASMX

- usage is a bit different from previous versions... 
	you now select the MPASM/MPASMX folder location instead of the 'Microchip' folder

- improved config settings as these now come from the .info file instead of comments in the .inc files.
	this fixes a few more bogus config entries that v1.1 didn't catch.

- improve ram allocation algorithm (fixes 18Fxx39 devices)


V1.1 changes
-----------
- fix misc issues that were causing a mismatch between the 'xxx devices found' message and the list of
	devices shown (the list was missing devices)

changes to cModelItem.pas:

- define PROD as 16bit register
	enabled by default, can be changed via commenting out {$DEFINE PROD_AS_16BIT}

- add '#const _wdt_type' to identify the watchdog config type
	0   WDT(WDT) = [OFF, ON]
	1   WDTEN(WDTEN) = [OFF, ON]
	2   WDTEN(WDTEN) = [OFF, NOSLP, SWON, ON]
	3   WDTEN(WDTEN) = [OFF, NOSLP, ON, SWDTDIS]
	enabled by default, can be changed via commenting out {$DEFINE _WDT_TYPE}

- fix '#variable _maxram' allocation 
	in some cases, the original was leaving some bank15 ram on the table, but for others it wasn't 
	accounting for SFR's in the upper bank15 and was treating them as available ram.
	some of the asm .inc files _BADRAM settings are incomplete, which didn't help. 
	(fixes J11, J72, J94, K22, K80 + others)

- fix bogus config fuse generation
	code was getting confused because some asm .inc files have an '=' in what is meant to be a pure 
	comment line, and this was fooling the pos test for '> 0'. ie for the 18F26J13 we were getting bogus
	'96MHZ(96MHZ) = [0]' and 'WRITE(WRITE) = [0]' config entries because of extraneous '=' chars
	in the description lines. (devices affected include J11, J13, J50, and J53 families)

- fix EDATA definition. was using wrong address (J60 devices w/ethernet)

- removed 'RESERVED' config settings. multiple entries were causing issues w/PLLDIV (J94/J99) 

- fix missing PORT registers for 100-pin 9xJ94/J99 devices. PORTK/PORTL were causing problems since 
	they're not in the normal spot. also, fix '#const _no_portx' statements	
	