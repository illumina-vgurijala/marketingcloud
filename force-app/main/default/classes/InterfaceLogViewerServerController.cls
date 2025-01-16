/*
 * @author	Sarath Pullanikkatt
 * @date	08-Nov-2018
 * @description	Server controller for InterfaceLogViewer.cmp. Handles rendering of interface log viewer.
*/
public with sharing class InterfaceLogViewerServerController {
    
    /*
     * Variable declarations
    */
    public static final String SYNC_DIR_ID_OUTBOUND = 'Outbound';
    public static final String SYNC_DIR_ID_INBOUND = 'Inbound';
    public static final String SYNC_DIR_ID_ANY = 'Any';
    public static final Integer SEARCH_QUERY_LIMIT = 300;

    /*
     * @description	Constructor
    */
	public InterfaceLogViewerServerController() {
        
    }
    
    /*
     * @author	Sarath Pullanikkatt
     * @date	15-Nov-2018
     * @description	Search Interface Logs based on the parameters passed.
     * @param	Search Term, Sync Direction, Interface, Start Date/Time, End Date/Time.
     * @return	List of Interface Logs matching the search criteria
    */
    @AuraEnabled
    public static List<InterfaceLogWrapper> searchLogs(String strSearchText, String strSyncDirection, String strInterface, String dtStartDateTime, String dtEndDateTime) {
        
        System.debug('strSearchText: ' + strSearchText + ' # strSyncDirection: ' + strSyncDirection + ' # strInterface: ' + strInterface + ' # dtStartDateTime: ' + dtStartDateTime + ' # dtEndDateTime: ' + dtEndDateTime);
        
        List<InterfaceLogWrapper> lstInterfaceLogs = new List<InterfaceLogWrapper>();
        
        if(String.isBlank(strSearchText)) {
            String strSOQLQuery = buildSOQLQuery(strSyncDirection, strInterface, dtStartDateTime, dtEndDateTime);
        	for(Interface_Log__c log : (List<Interface_Log__c>) Database.query(strSOQLQuery))
                lstInterfaceLogs.add(new InterfaceLogWrapper(log));
        }
        else {
            String strSOSLQuery = buildSOSLQuery(strSearchText, strSyncDirection, strInterface, dtStartDateTime, dtEndDateTime);
            List<List<SObject>> lstLstSObjects = Search.query(strSOSLQuery);
            for(Interface_Log__c log : (List<Interface_Log__c>)lstLstSObjects.get(0))
                lstInterfaceLogs.add(new InterfaceLogWrapper(log));
        }
        
        return lstInterfaceLogs;
    }
    
    /*
     * @author	Sarath Pullanikkatt
     * @date	30-Nov-2018
     * @description	Build the SOSL query string based on the parameters passed.
     * @param	Search Term, Sync Direction, Interface, Start Date/Time, End Date/Time.
     * @return	SOSL query string
    */
    private static String buildSOSLQuery(String strSearchText, String strSyncDirection, String strInterface, String dtStartDateTime, String dtEndDateTime) {
        
        String strQuery = 'FIND {*' + String.escapeSingleQuotes(strSearchText) + '*} ' + 
        					'RETURNING Interface_Log__c ( ' +
            				'Id, Name, Direction__c, CreatedDate, Json_Message__c, Interface_Name__c, Related_Record__c, Related_Record_Type__c, Result__c, Result_Details__c, CreatedBy.Name ';
        if(!String.isEmpty(strInterface) || dtStartDateTime <> NULL || dtEndDateTime <> NULL) {
            strQuery += 'WHERE ';
            if(!String.isEmpty(strInterface))
                strQuery += 'Interface_Name__c = \'' + strInterface + '\' AND ';
            if(!String.isEmpty(strSyncDirection))
                strQuery += 'Direction__c = \'' + strSyncDirection + '\' AND ';
            if(dtStartDateTime <> NULL)
                strQuery += 'CreatedDate > ' + dtStartDateTime + ' AND ';
            if(dtEndDateTime <> NULL)
                strQuery += 'CreatedDate < ' + dtEndDateTime + ' AND ';
            strQuery = strQuery.removeEndIgnoreCase(' AND ') + ' ';
        }
        strQuery += 'ORDER BY CreatedDate DESC ' +
					'LIMIT ' + SEARCH_QUERY_LIMIT + ' )';
        System.debug('SOSL Query: ' + strQuery);
        return strQuery;
    }
    
    /*
     * @author	Sarath Pullanikkatt
     * @date	10-Dec-2018
     * @description	Build the SOQL query string based on the parameters passed.
     * @param	Sync Direction, Interface, Start Date/Time, End Date/Time.
     * @return	SOQL query string
    */
    private static String buildSOQLQuery(String strSyncDirection, String strInterface, String dtStartDateTime, String dtEndDateTime) {
        
        String strQuery = 'SELECT Id, Name, Direction__c, CreatedDate, Json_Message__c, Interface_Name__c, Related_Record__c, Related_Record_Type__c, Result__c, Result_Details__c, CreatedBy.Name ' +
            			  'FROM Interface_Log__c ';
        if(!String.isEmpty(strInterface) || dtStartDateTime <> NULL || dtEndDateTime <> NULL) {
            strQuery += 'WHERE ';
            if(!String.isEmpty(strInterface))
                strQuery += 'Interface_Name__c = \'' + strInterface + '\' AND ';
            if(!String.isEmpty(strSyncDirection))
                strQuery += 'Direction__c = \'' + strSyncDirection + '\' AND ';
            if(dtStartDateTime <> NULL)
                strQuery += 'CreatedDate > ' + dtStartDateTime + ' AND ';
            if(dtEndDateTime <> NULL)
                strQuery += 'CreatedDate < ' + dtEndDateTime + ' AND ';
            strQuery = strQuery.removeEndIgnoreCase(' AND ') + ' ';
        }
        strQuery += 'ORDER BY CreatedDate DESC ' +
					'LIMIT ' + SEARCH_QUERY_LIMIT;
        System.debug('SOQL Query: ' + strQuery);
        return strQuery;
    }
    
    /*
     * @author	Sarath Pullanikkatt
     * @date	28-Nov-2018
     * @description	Retrieve Interface Details custom metadata and set the UI drop-down values.
     * @param	None
     * @return	Map of Sync Directions to the List of Interface Details.
    */
    @AuraEnabled
    public static Map<String, List<String>> fetchInterfaceDetailsMetadata() {
        
        Map<String, List<String>> mapDirToInterfacesList = new Map<String, List<String>>();
        
        //Iterate through the list of all Interface Details custom metadata.
        for(Interface_Detail__mdt mdInterfaceDetail : new InterfaceDetailsSelector().selectAllInterfaceDetails()) {
            if(mdInterfaceDetail.Interface_Name__c != NULL) {
                
                //Add Interface Name to the mapDirToInterfacesList with key 'Any'.
                if(!mapDirToInterfacesList.containsKey(SYNC_DIR_ID_ANY))
                    mapDirToInterfacesList.put(SYNC_DIR_ID_ANY, new List<String>());
                mapDirToInterfacesList.get(SYNC_DIR_ID_ANY).add(mdInterfaceDetail.Interface_Name__c);
                    
                //If the Interface Name contains the keyword 'Outbound', add it to the mapDirToInterfacesList with key 'Outbound'.
                if(mdInterfaceDetail.Interface_Name__c.contains(SYNC_DIR_ID_OUTBOUND)) {
                	if(!mapDirToInterfacesList.containsKey(SYNC_DIR_ID_OUTBOUND))
                    	mapDirToInterfacesList.put(SYNC_DIR_ID_OUTBOUND, new List<String>());
                	mapDirToInterfacesList.get(SYNC_DIR_ID_OUTBOUND).add(mdInterfaceDetail.Interface_Name__c);
            	}
                
                //If the Interface Name contains the keyword 'Inbound', add it to the mapDirToInterfacesList with key 'Inbound'.
            	if(mdInterfaceDetail.Interface_Name__c.contains(SYNC_DIR_ID_INBOUND)) {
                	if(!mapDirToInterfacesList.containsKey(SYNC_DIR_ID_INBOUND))
                    	mapDirToInterfacesList.put(SYNC_DIR_ID_INBOUND, new List<String>());
                	mapDirToInterfacesList.get(SYNC_DIR_ID_INBOUND).add(mdInterfaceDetail.Interface_Name__c);
            	}
        	}
        }
        
        return mapDirToInterfacesList;
    }
    
    /*
     * @author	Sarath Pullanikkatt
     * @date	19-Nov-2018
     * @description	Wrapper class to capture Interface Logs in the way that Lightning component needs.
    */
    public class InterfaceLogWrapper {
        
        /*
         * Variable declarations
        */
        @AuraEnabled public Id idLog {get; set;}
        @AuraEnabled public String strName {get; set;}
        @AuraEnabled public String strURL {get; set;}
        @AuraEnabled public String strDirection {get; set;}
        @AuraEnabled public String strInterfaceName {get; set;}
        @AuraEnabled public String strResult {get; set;}
        @AuraEnabled public String strCreatedBy {get; set;}
        @AuraEnabled public String dtLogTimeStamp {get; set;}
        @AuraEnabled public String strJSONMessage {get; set;}
        @AuraEnabled public String strRelatedURL {get; set;}
        
        /*
         * @description	Constructor
        */
        public InterfaceLogWrapper(Interface_Log__c log) {
            
            this.idLog = log.Id;
            this.strName = log.Name;
            this.strURL = '/lightning/r/Interface_Log__c/' + this.idLog + '/view';
            this.strDirection = log.Direction__c;
            this.strInterfaceName = log.Interface_Name__c;
            this.strResult = log.Result__c;
            this.dtLogTimeStamp = String.valueOf(log.CreatedDate);
            
            if(log.CreatedBy.Name != NULL)
                this.strCreatedBy = log.CreatedBy.Name;
            if(log.Json_Message__c != NULL)
                this.strJSONMessage = log.Json_Message__c;
            if(log.Related_Record__c != NULL && log.Related_Record_Type__c != NULL)
                this.strRelatedURL = '/lightning/r/' + log.Related_Record_Type__c + '/' + log.Related_Record__c + '/view';
        }
    }
}