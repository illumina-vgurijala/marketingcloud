/**
*    @author Sampath Goud
*    @date   12th April 2019
*    @description    Class to share the records synchornously or future. These methods are called from 
*                    TAPS_Orchestrator class
*    Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer               Date                Description
*    Sampath Goud            2019-04-12          Initial Version
*    Todd Newman             2020-07-09          add without sharing and refactor
*    ------------------------------------------------------------------------------------                  
*/
public without sharing class TAPS_SharingUsingFuture {

    /*
    *  @author  Sampath Goud
    *  @description Call the record sharing logic using future method
    *  @return N/A
    */
    @future
    public static void recFutureSharing(Set<Id> recordIds, String strObjectType)
    {
        recSyncSharing(recordIds, strObjectType);
    }

    /*
    *  @author  Sampath Goud
    *  @description Call the record sharing logic synchronously
    *  @return N/A
    */
    public static void recSyncSharing(Set<Id> recordIds, String strObjectType)
    {
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(strObjectType);
        TAPS_ComposedBase handler = TAPS_ObjectSupport.sharingFactory(objType);

        TAPS_BatchUpdate shareUpdater = new TAPS_BatchUpdate(recordIds, handler);
        shareUpdater.execute(null, new List<Id>(recordIds));
    }

}