/*
 * @author	Sarath Pullanikkatt
 * @date	27-Nov-2018
 * @description	Selector class for Interface Detail (Interface_Detail__mdt) Custom Metadata Type.
*/
public class InterfaceDetailsSelector extends ilib_SObjectSelector {
    
    /*
     * @description	Constructor
    */
    public InterfaceDetailsSelector() {
        
        //Do not include Field Set fields, do not enforce CRUD, do not enforce FLS, and do not sort.
        super(false, false, false, false);
    }

    /*
     * @author	Sarath Pullanikkatt
     * @date	27-Nov-2018
     * @description
     * @param	None
     * @return	Schema.SObjectType of the Interface Detail (Interface_Detail__mdt)
    */
    public Schema.SObjectType getSObjectType() {

        return Interface_Detail__mdt.sObjectType;
    }
    
    /*
     * @author	Sarath Pullanikkatt
     * @date	27-Nov-2018
     * @description	Return this default set of fields for all selector methods.
     * @param	None
     * @return	List<Schema.SObjectField> of the Interface Detail (Interface_Detail__mdt)
    */
    public List<Schema.SObjectField> getSObjectFieldList() {
        
        return new List<Schema.SObjectField> {
            Interface_Detail__mdt.Id,
            Interface_Detail__mdt.DeveloperName,
            Interface_Detail__mdt.Direction__c,
            Interface_Detail__mdt.Object_Type__c,
            Interface_Detail__mdt.Interface_Name__c
        };
    }
    
    /*
     * @author	Sarath Pullanikkatt
     * @date	28-Nov-2018
     * @description	Select all Interface Detail custom metadata records.
     * @param	None
     * @return	List<Interface_Detail__mdt>
    */
    public List<Interface_Detail__mdt> selectAllInterfaceDetails() {
        
        return (List<Interface_Detail__mdt>) Database.query(
            newQueryFactory().addOrdering('Interface_Name__c', ilib_QueryFactory.SortOrder.ASCENDING).toSOQL()
        );
    }
}