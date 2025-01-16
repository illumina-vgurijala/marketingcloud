/*** @author Gopinath Reddy
*    @date   01-28-20202
*    @description    Class to get the Queue Owner Ids 
*    Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                    Description
*    Gopinath Reddy                 01-28-20202             Initial Version
*    KD                             8-Sept-2020             Added method to query group for Territory 
*    KD                             24-Sept-2020            DCP-39951 : Admin layout
*    Monika Parihar                 06-Dec-2020             DCP-43373
*    ------------------------------------------------------------------------------------                  
*/
public with sharing class GroupsSelector extends ilib_SObjectSelector {
    public static final String GROUP_TYPE_TERRITORY = 'Territory';
    public static final String GROUP_TYPE_TERRITORY_SUB = 'TerritoryAndSubordinates';
    /*
    * @description  describe the object
    *
    */
    public Schema.SObjectType getSObjectType()
    {
        return Group.sObjectType;
   }
   /*  
    * @description  set select fields
    */
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Group.id,
            Group.Name,
            Group.DeveloperName,
            Group.RelatedId,
            Group.Type
        };
     }

    /**
     *  @author Gopinath Reddy
     *  @description Fetch Order line items by Asset Line Item Ids
     *  @param setAssetLineItems set of asset line item ids
     *  @return order line item List
     **/
    public List<Group> getQueueIdsbyDevName(Set<String> setDevName) 
    {
        return (List<Group>) Database.query(
            newQueryFactory()
            .selectField('Id')
            .setCondition('DeveloperName IN : setDevName' ).toSOQL()
        );
    }
    /**
     *  @author KD
     *  @description Fetch group for Territory
     *  @param Set of Territory Id
     *  @return List of Group
     **/
    public List<Group> getIdByRelatedBy(Set<Id> setRelatedId) 
    {
        return (List<Group>) Database.query(
            newQueryFactory()
            .setCondition('RelatedId IN : setRelatedId').toSOQL()
        );
    }
    /**
     *  @author KD
     *  @description Fetch group
     *  @param Set of Group Id
     *  @return List of Group
     // DCP-39951
     **/
    public List<Group> getByGroupIds(Set<String> setGroupId) 
    {
        return (List<Group>) Database.query(
            newQueryFactory()
            .setCondition('Id IN : setGroupId').toSOQL()
        );
    }
	
	
    /**
     *  @author Deepak Kumar
     *  @description Fetch queue ID
     *  @param  String of DevName
     *  @return Group
     // DCP-39951
     **/
    public Group getQueueIdbyDevName(String setDevName , String groupType ) {
        
        return Database.query (
             newQueryFactory()
            .selectField('Id')
            .setCondition( 'Type = :groupType AND DeveloperName = :setDevName' ).toSOQL()
        );
    }
    
	 /**
     *  @author Monika Parihar
     *  @description Fetch queue ID
     *  @param  String of DevName and String of groupType
     *  @return Group
     // DCP-43373
    **/
    public List<Group> getQueueIdbyDeveloperName(List<String> setDevName , String groupType ) {
        return (List<Group>) Database.query(
             newQueryFactory()
            .selectField('Id')
            .setCondition( 'Type = :groupType AND DeveloperName IN :setDevName' ).toSOQL()
        );
    }   
}