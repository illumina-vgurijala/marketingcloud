/*@ author       : Akshay Mohan
* @ date         : 07-05-2018
* @ Description  : Test to check ScheduledBatchAccountTerritorySync
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Akshay Mohan          07-05-2018                 US-4252             Initial version
* KD                    4-Aug-2020                                      Added future verion of record creation
* 
*/
@isTest

public with sharing class TestDataObjectTerritory2Association {

    /*
    *  @AUTHOR:  Akshay   Mohan
    *  @DESCRIPTION:This method creates ObjectTerritory2Association
    *  @PARAM :  String TerritoryId,String Object Id
    *  @RETURN:  Account type object
    */
    
    public static ObjectTerritory2Association getObjectAssociation(String strTerritoryId,String strObjectId){
        return new ObjectTerritory2Association(AssociationCause = 'Territory2Manual', 
                                               ObjectId=strObjectId, 
                                               Territory2Id=strTerritoryId);
    }
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION:This method creates ObjectTerritory2Association in future
    *  @PARAM :  String TerritoryId,String Object Id
    *  @RETURN:  Account type object
    */
    @future
    public static void getObjectAssociationFuture(String strTerritoryId,String strObjectId){
        ObjectTerritory2Association objOTA =  new ObjectTerritory2Association(AssociationCause = 'Territory2Manual', 
                                               ObjectId=strObjectId, 
                                               Territory2Id=strTerritoryId);
        insert objOTA;
    }
    
}