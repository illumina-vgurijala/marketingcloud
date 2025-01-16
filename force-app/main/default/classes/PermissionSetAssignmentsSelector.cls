/**
*    @author Satya Swain
*    @date   16 Nov 2018  
*    @description Selector class for QuotationPreventRevertToDraft
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*            Satya Swain                  16 Nov 2018          Initial Version
*            Rohan Rathod                 28 Jun 2022           Added selector to fetch all permission for a user
*           Iram Malik                     14 Jul 2022         Codescan fixes
*    --------------------------------------------------------------------------------------------------------------------------------------------------
*                    
**/
public with sharing class PermissionSetAssignmentsSelector extends ilib_SObjectSelector {
    /*
    *   @author Satya Swain      
    *   @description  Describe the object
    */
    public Schema.SObjectType getSObjectType()
    {
        return PermissionSetAssignment.sObjectType;
    }
    /*
    *   @author Satya Swain      
    *   @description  Set Select fields
    *   @param NA
    *   @return List<Schema.SObjectField>
    *
    */
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            PermissionSetAssignment.Id,
            PermissionSetAssignment.AssigneeId
        };
    }
    /**
     * @Author: Sravan Panchangam
     * @Description: get the list of PermissionSetAssignment  based on the permssion set name
     * @param String strPermissionSetName
     * @return List<PermissionSetAssignment>
    **/
    public List<PermissionSetAssignment> selectPermissionSetAssigmentByName(String strPermissionSetName){
        String strCondition = '';
        String strQuery = '';
        String userId = Userinfo.getUserId();
        strCondition = 'AssigneeId = :userId AND PermissionSet.Name = :strPermissionSetName';
        strQuery = newQueryFactory().selectField('PermissionSet.Name').setCondition(strCondition).toSOQL();
        return (List<PermissionSetAssignment>) Database.query(strQuery);
    }

}