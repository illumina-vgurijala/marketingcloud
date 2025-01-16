/*** @author KD
*    @date   23-Jan-2020
*    @description    Class to get the Custom Metadata records for Material Group
*    Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                    Description
*    Jitesh Lakhwani             6-July-2022            Code Scan fixes of Comments
*    ------------------------------------------------------------------------------------                  
*/
public with sharing class MaterialGroupsSelector extends ilib_SObjectSelector{
    
    /**
     * @description  This method will return the SObjectType of the Material Group meta-data
     * @param : None
     * @return : Schema.SObjectType
    */
    public Schema.SObjectType getSObjectType()
    {
        return Material_Group__mdt.sObjectType;
    }    
    /**
    *  @author  KD
    *  @description Retrieve list of fields for Metadata type 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
                Material_Group__mdt.DeveloperName,
                Material_Group__mdt.MasterLabel,
                Material_Group__mdt.Description__c
                };
    }

    /**
     *  @description Retrieve list of all material group meta-data records
     *  @return List<Material_Group__mdt> : List of material Group meta-data 
     **/
    public List<Material_Group__mdt> selectAll(){
        return (List<Material_Group__mdt>) Database.query(
            newQueryFactory()
            .toSOQL()
        );
    }
    
}