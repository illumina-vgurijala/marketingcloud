 /**
 * @author Todd newman 
 * @date  12-dec-2018 
 * @description : Consortium Object Type class
 * Modification Log:
 *       ------------------------           
 * Jitesh Lakhwani               6-July-2022            Code Scan fixes of Comments
 * 
 */

public without sharing class TAPS_Consortium extends TAPS_ComposedBase implements TAPS_IObjectsJunction {

    /**
    *@description : this will return the Consortium sObjectType. 
    *@return SObjectType 
    */
    public override SObjectType getObjectType()
    {
        return Consortium__c.sObjectType;
    }

    /**
    *@description : this will return the junction object table API name. 
    *@return String 
    */
    public override String getJunctionTableName()
    {
        return 'Consortium_Account__c';
    }

    /**
    *@description : this will return the junction object field 'consortia' API name. 
    *@return String 
    */
    public override String getKeyFieldName()
    {
        return 'Consortia__c';
    }

    /**
    *@description : this will return the junction object field 'Account' API name. 
    *@return String 
    */    
    public override String getValueFieldName()
    {
        return 'Account__c';
    }

    /**
    *@description : this will return the consortium share object's SObjectType
    *@return SObjectType 
    */      
    public override SObjectType getShareObjectType()
    {
        return Consortium__Share.sObjectType;
    }

    /**
    *@description : this will return the consortium share object parent field name  
    *@param  : None
    *@return : String : consortium share parent id field name : ParentId
    */
    public override String getShareParentFieldName()
    {
        return 'ParentId';
    }

    /**
    *@description : this will create the consortium share object record and will return it  
    *@param  : Id recordId, Id userId
    *@return : SObject 
    */
    public override SObject createSharingRecord(Id recordId, Id userId)
    {
        return new Consortium__Share(
                UserOrGroupId = userId,
                ParentId = recordId,
                AccessLevel = 'Read',
                RowCause = Schema.Consortium__Share.RowCause.Manual
        );
    }

    /**
    * @description filter by role in territory to only include certain sales roles
    * @params Set<Id> territoryIds, Map<Id, Set<Id>> recordIdToAccountIds
    * @return Set<Id> 
    **/ 
    public override Set<Id> filterTerritories(Set<Id> territoryIds, Map<Id, Set<Id>> recordIdToAccountIds)
    {
        return keepIndirectTerritories(territoryIds);
    }

}