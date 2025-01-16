@isTest
private class ilib_SingleRunManagerTest {

    @isTest
    private static void runsOnlyOnce()
    {
        String myLogic = 'My Logic Block';

        ilib_SingleRunManager onlyOnce = new ilib_SingleRunManager();

        // first run
        if (onlyOnce.notRunYet(myLogic))
        {
            onlyOnce.setHasRun(myLogic);
            System.assert(true);
        }
        else
        {
            System.assert(false);
        }

        Test.startTest();
        // second run
        if (onlyOnce.notRunYet(myLogic))
        {
            onlyOnce.setHasRun(myLogic);
            System.assert(false);
        }
        else
        {
            System.assert(true);
        }
        Test.stopTest();
    }

    @isTest
    private static void resetable()
    {
        String myLogic = 'My Logic Block';

        ilib_SingleRunManager onlyOnce = new ilib_SingleRunManager();

        // first run
        if (onlyOnce.notRunYet(myLogic))
        {
            onlyOnce.setHasRun(myLogic);
            System.assert(true);
        }
        else
        {
            System.assert(false);
        }

        // second run
        if (onlyOnce.notRunYet(myLogic))
        {
            onlyOnce.setHasRun(myLogic);
            System.assert(false);
        }
        else
        {
            System.assert(true);
        }

        // reset for third run
        onlyOnce.resetHasRun(myLogic);

        Test.startTest();
        // third run
        if (onlyOnce.notRunYet(myLogic))
        {
            onlyOnce.setHasRun(myLogic);
            System.assert(true);
        }
        else
        {
            System.assert(false);
        }
        Test.stopTest();
    }

}
