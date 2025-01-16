/*@ author       : KD
* @ date         : 28-July-2020
* @ Description  : Create User territory Association
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------

* 
*/
@isTest
public with sharing class TestDataUserTerritory2Association {

    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION:This method creates UserTerritory2Association
    *  @PARAM :  String TerritoryId,String User Id
    *  @RETURN:  
    */
    
    public static UserTerritory2Association getUserAssociation(String strTerritoryId,String strUserId){
        return new UserTerritory2Association( 
                                               UserId=strUserId, 
                                               Territory2Id=strTerritoryId);
    }
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION:This method creates UserTerritory2Association in future
    *  @PARAM :  String TerritoryId,String User Id
    *  @RETURN:  
    */
    public static UserTerritory2Association getUserAssociationwithRole(String strTerritoryId,String strUserId,String strRole){
        return new UserTerritory2Association(  
                                               UserId=strUserId, 
                                               Territory2Id=strTerritoryId,
                                               RoleInTerritory2 = strRole);
    }
}