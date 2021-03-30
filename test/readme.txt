===========================
  FlashFiler Unit Tests
===========================

The folders in this directory contain the FlashFiler 2 (FF2) unit
tests.


----------------------------------------

!!! NOTE !!!

----------------------------------------

The FF2\test\data subdirectory contains tables & files used by the
unit tests. Please note the following requirements:

1. The tables & files may not be read-only.

2. You must unzip the file coleta.zip into its directory. The zip file
   is utilized due to the size of the files it contains.


----------------------------------------

The unit tests are dependent upon the following projects:

 - DUnit

   Website: http://sourceforge.net/projects/dunit/

 - TurboPower Abbrevia

   Website: http://sourceforge.net/projects/tpabbrevia

 - TurboPower ShellShock

   Website: TffDBTest

 - TurboPower SysTools

   Website: http://sourceforge.net/projects/tpsystools

The test projects assume the location of the DUnit source code,
relative to the FF2 installation, is as follows:


C:\
|
+---DUnit
|   |
|   +---Src
|
+---FF2
    |
    +---Test
        |
        +---<test folder>


Each test folder contains tests for a specific set of functionality in
FF2. Each test folder contains a project file (e.g., FFCursorTest.dpr)
and one or more units containing unit tests.

The FF2\Test\All folder contains a project that runs all of the unit
tests in the FF2\Test subfolders.
