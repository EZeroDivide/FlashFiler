01/29/2002 - Ben

Using the SQL Test Editor and SQL Test Runner
------------------------------------------------------------
Note: The SQL Test Editor and SQL Test Runner are in the 
FlashFiler 2 Test Source tree.


The SQL Test Editor
------------------------------------------------------------
The SQL Test Editor is used to create new and modify 
existing SQL Test cases. An SQL Test case consists of the
following:

 1. Basic information describing the test including an 
    issue id.
 2. A directory containing a set of FlashFiler tables to
    query against.
 3. Query parameters, including filter and timeout settings
 4. A specific query result to compare to.
 
All SQL Test cases are stored in a FlashFiler table names
SQLTests.FF2

Before the SQL Test Editor can be used, the SQLTests.FF2 
file must be checked out from VSS. It is located in 
  $/FlashFiler 2.0x/test/SQL Test Editor


Creating an SQL Test
------------------------------------------------------------
Complete the following steps to create an SQL Test Case

1. Start the SQL Test Editor and click add.
2. Navigate to the "Test Information" page and fill out the
   information.
   
   a. OrderID is used to specify when the test should be run
      by the test runner. The smaller the number the sooner
      the test will be executed.
   b. If necessary Use Issue# to reference the bug in 
       bugzilla this test is testing.
   c. Tests may be executed multiple times one after another.
      Use Run count to specify how many times to execute the
      test.
3. Navigate to the "Query" page and fill out the information.

   a. Set database path to the directory containing the
      FlashFiler tables that the query should run against.
      When the test is saved, the directory will be compressed
      and placed in the SQLTests.FF2 table.
   b. Specify the timeout, SQL and filter parameters as 
      necessary.
4. Navigate to the "Result Information" page and fill out the
   information.
   
   a. Specify the result type for the test.
      1. The dataset result type means that the result of the
         query will be compared against a FlashFiler table.
      2. The two error result types are used to make sure
         the correct exception is raised for an invalid query.
   b. For dataset results, specify the path to the table
      the query result should be compared against. The table
      will be compressed and placed in the SQLTests.FF2 table.
      For error results, specify the error code or error string
      as necessary.
5. The final page in the configure test dialog is the 
   "Test Results" page. This page is populated with the query
   results when the Test button is clicked. If the results
   of the query are correct, then you can use this page to save
   the results to disk. This is useful for creating result 
   datasets to be tested against.
   


 The SQL Test Runner
 ------------------------------------------------------------
 The SQL Test Runner is a dunit test that runs all the tests
 stored in the SQLTests.FF2 file. The Test Runner and Test
 Editor share the same SQLTests.FF2 file in VSS. Both
 applications expect the SQLTest.FF2 file to be located in 
 the application directory. Therefore, once a test is added
 it will be necessary to sync the copy in the editor and 
 runner directories.