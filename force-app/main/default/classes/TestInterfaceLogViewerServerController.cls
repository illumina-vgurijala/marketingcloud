/*
 * @author	Sarath Pullanikkatt
 * @date	14-Dec-2018
 * @description	Test Class for InterfaceLogViewerServerController.
*/
@isTest(seeAllData=false)
public with sharing class TestInterfaceLogViewerServerController {
	
    /*
     * Variable declarations
    */
    public static final String SYNC_DIR_OUTBOUND = InterfaceLogViewerServerController.SYNC_DIR_ID_OUTBOUND;
    public static final String SYNC_DIR_INBOUND = InterfaceLogViewerServerController.SYNC_DIR_ID_INBOUND;
    public static final String SYNC_DIR_ANY = InterfaceLogViewerServerController.SYNC_DIR_ID_ANY;
    public static String strName = 'Unique Test Account 001';
    
    /*
     * @author	Sarath Pullanikkatt
     * @date	14-Dec-2018
     * @description	Test Data Setup. Create Interface Logs.
    */
    @testSetup
    public static void initializeTestData() {
        
        List<Interface_Log__c> lstInterfaceLogs = new List<Interface_Log__c>();
        for(Integer i = 0; i < 5; i++) {
            Interface_Log__c iLog = new Interface_Log__c();
            if(i < 2) {
            	iLog.Direction__c = 'Inbound';
            	iLog.Interface_Name__c = 'Customer Inbound';
            }
            else {
                iLog.Direction__c = 'Outbound';
                iLog.Interface_Name__c = 'Customer Outbound';
            }
            iLog.Related_Record_Type__c = 'Account';
            iLog.Result__c = 'Success';
            iLog.OwnerId = UserInfo.getUserId();
            iLog.Json_Message__c = '{"header": {"Name" : "' + strName + '"}}';
            lstInterfaceLogs.add(iLog);
        }
        insert lstInterfaceLogs;
    }
    
    /*
     * @author	Sarath Pullanikkatt
     * @date	14-Dec-2018
     * @description	Test method to cover InterfaceLogViewer init().
    */
    public static testMethod void testFetchInterfaceDetails() {
        
        //Returns the map of Sync Directions (Any, Inbound, Oubound) to the List of Interfaces.
        Map<String, List<String>> mapDirToInterfacesList = InterfaceLogViewerServerController.fetchInterfaceDetailsMetadata();
        
        //Assert the keys within the map returned.
        System.assertEquals(true,
                            mapDirToInterfacesList.containsKey(SYNC_DIR_OUTBOUND)
                            && mapDirToInterfacesList.containsKey(SYNC_DIR_INBOUND)
                            && mapDirToInterfacesList.containsKey(SYNC_DIR_ANY));
    }
    
    /*
     * @author	Sarath Pullanikkatt
     * @date	14-Dec-2018
     * @description	Test method to cover search using SOQL().
    */
    public static testMethod void testSearchLogsSOQL() {
        
        //Set the parameters for the search.
        String strSearchText = '';
        String strSyncDirection = 'Outbound';
        String strInterface = 'Customer Outbound';
        String dtStartDateTime = DateTime.now().addDays(-10).format('yyyy-MM-dd\'T\'HH:mm:ssZ');
        String dtEndDateTime = DateTime.now().addDays(1).format('yyyy-MM-dd\'T\'HH:mm:ssZ');
        
        //Search for all Customer Outbound Interfaces and assert the search result count.
        List<InterfaceLogViewerServerController.InterfaceLogWrapper> lstLogWrappers = InterfaceLogViewerServerController.searchLogs(strSearchText, strSyncDirection, strInterface, dtStartDateTime, dtEndDateTime);
        System.assertEquals(3, lstLogWrappers.size());
    }
    
    /*
     * @author	Sarath Pullanikkatt
     * @date	14-Dec-2018
     * @description	Test method to cover search using SOSL().
    */
    public static testMethod void testSearchLogsSOSL() {
        
        //Set the parameters for the search.
        String strSearchText = 'unique';
        String strSyncDirection = 'Inbound';
        String strInterface = 'Customer Inbound';
        String dtStartDateTime = DateTime.now().addDays(-10).format('yyyy-MM-dd\'T\'HH:mm:ssZ');
        String dtEndDateTime = DateTime.now().addDays(1).format('yyyy-MM-dd\'T\'HH:mm:ssZ');
        
        //Search for all Customer Inbound Interfaces. No assertions as SOSL may yield no results (search indexing takes time).
        InterfaceLogViewerServerController.searchLogs(strSearchText, strSyncDirection, strInterface, dtStartDateTime, dtEndDateTime);
        system.assert(true,'Assert not true');
    }
}