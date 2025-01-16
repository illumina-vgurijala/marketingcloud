/*
 * Class to keep track of code that should only run once per transaction
 * Instance is declared in ilib_SObjectDomain
 * so these methods are available in all domain contexts
 * 
 * This class does not manage the logicLabel values passed in, it's up
 * to the client to make sure those are unique
 * 
 * usage:
 * ilib_SingleRunManager onlyOnce = new ilib_SingleRunManager();
 * 
 * if (onlyOnce.notRunYet('My Singleton Logic')) {
 *     // logic that should run only once
 * 
 *     onlyOnce.setHasRun('My Singleton Logic');
 * }
 * 
 */
public with sharing class ilib_SingleRunManager {

    /* Query whether a certain bit of logic has yet to run */
    public Boolean notRunYet(String logicLabel)
    {
        return !(runTracking().containsKey(logicLabel));
    }

    /* Track that a certain bit of logic has now run once */
    public void setHasRun(String logicLabel)
    {
        runTracking().put(logicLabel, true);
    }

    /* Not normally used. But in case the client needs code to run a second time because some state was reset */
    public void resetHasRun(String logicLabel)
    {
        runTracking().remove(logicLabel);
    }

    private Map<String, Boolean> m_runTracking;
    /* many domains won't use this feature so lazy init the map creation */
    private Map<String, Boolean> runTracking()
    {
        if (m_runTracking == null) m_runTracking = new Map<String, Boolean>();

        return m_runTracking;
    }

}
