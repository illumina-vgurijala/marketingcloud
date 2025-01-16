/**
 *    @author KD
 *    @date   5-Nov-2020
 *    @description : Interface class for partner sharing framework
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                  Description
  *    ------------------------------------------------------------------------------------ 
 *                    
 */
public interface ilib_ShareFactory {
    // get the specific SObject that holds sharing records
    /*
    * Description : Interface method to return object type
    */
    SObjectType getShareObjectType();

    // name the field on the Share table that refers to the parent record ID
    // will be ParentId for all custom objects but a more specific name for standard objects
    /*
    * Description : Interface method to return share object parent name
    */
    String getShareParentFieldName();
}