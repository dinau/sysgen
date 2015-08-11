Sysgen16 V1.2
-------------

- program no longer uses MPLAB .dev files, only XC16 .inc and .gld files
	remove selection of MPLAB folder (can now be used with MPLABX directory)
	
- add 'dsPIC30/33' checkbox to enable generating files for those devices

- add gld version to the .bas file output header
    *  Part support version v1.24.A(02-Jan-2015)
	** Part support version vv1_21.A

- RAM and ROM values are now obtained from the linker .gld file instead of
	the .dev file

- add new entries to the system header (mostly for info purposes) 
	#variable _ivtbase = &H000004          ' ivt addr
	#variable _ivtlen = &H0001FC           ' ivt size
	#variable _codebase = &H000200         ' program start addr
	#variable _codelen = &H0055EC          ' program size

	if applicable:
	#variable _aivtbase = &H000104         ' aivt addr
	#variable _aivtlen = &H0000FC          ' aivt size
	#variable _auxflashbase = &H7FC000     ' aux flash addr
	#variable _auxflash = &H003FFA         ' aux flash size

- attempt to recognize more peripheral registers to get a better accounting of 
	available peripherals since different families can use different register
	names (ie '#const _dma = &H01')

- add code to detect dual-panel flash devices with config FBOOT (ie 24FJ128GA406)
