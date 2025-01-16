/**
* @author Akshay Mohan
* @date   30-Aug-2018
* @description  Selector class for Account_Relationship__c
* Modification Log:
*  ------------------------------------------------------------------------------------
*   Developer                Date                Description
*   Akshay Mohan             30-Aug-2018         Original
*   Rahul Sharma             29-Nov-2018         selectByAccountIdRelationship - Added select field for incoterm1
*	Roopal Verma             04-Apr-2019         selectByAccERPAndASAERP, Added Mark_For_Deletion__c and IsInactive__c in all methods
*   Roopal Verma             11-11-2019          DCP-28541 Added Default_Partner__c
*  -----------------------------------------------------------------------------------
*/
public class AccountRelationshipsSelector extends ilib_SObjectSelector {

    /*
    *   @author Akshay Mohan
    *   @date   30-Aug-2018
    *   @description  Describe the object
    *
    */
    public Schema.SObjectType getSObjectType()
    {
      return Account_Relationship__c.sObjectType;
   }

    /*
    *   @author Akshay Mohan
    *   @date   30-Aug-2018
    *   @description  Set Select fields
    *
    */
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
          Account_Relationship__c.Id,
          Account_Relationship__c.Name,
          Account_Relationship__c.Relationship__c,
          Account_Relationship__c.Related_ERP_Customer_Id__c,
          Account_Relationship__c.ERP_Customer_Id__c,
          Account_Relationship__c.IsInactive__c,
          Account_Relationship__c.ERP_Account_Relationship_Id__c,
		  Account_Relationship__c.Default_Partner__c                                              //DCP-28541 Added Default
       };
    }

    /**
     *  @author Akshay Mohan
     *  @date   30-Aug-2018
     *  @description Fetch the Account Relationships for an Account Id & Relationship
     *  @param Set<String> setAccountIdWithERP
     *  @param lstRelationship of relationships
     *  @return Account_Relationship__c List with related CustomerMasterData
     *
    **/
    public List<Account_Relationship__c> selectByAccountIdRelationship(Set<String> setAccountERP,List<String> lstRelationship)
    {
        if (setAccountERP.isEmpty())
            return new List<Account_Relationship__c>();

        ilib_QueryFactory query = newQueryFactory();

        query.setCondition(' Relationship__c IN :lstRelationship AND Account_Sales_Area__r.IsInactive__c = false '
                            +' AND Account_Sales_Area__r.Customer_Master_Data__r.Mark_For_Deletion__c = false'
                            +' AND Account_Sales_Area__r.Account__r.Account_Group__c != \'Legacy\' '
                            +' AND Account_Sales_Area__r.Customer_Master_Data__r.Account_Group__c != \'Legacy\' '
                            +' AND IsInactive__c = false AND ERP_Customer_Id__c IN :setAccountERP');

        //get relationship fields from Customer_Master_Data__c
        CustomerMasterDataSelector selectorCMD = new CustomerMasterDataSelector();
        selectorCMD.configureQueryFactoryFields(query,'Account_Sales_Area__r.Customer_Master_Data__r');

        //select sales area name
        String strQuery = query.selectField('Account_Sales_Area__r.Name')
                                .selectField('Account_Sales_Area__r.ERP_Account_Sales_Area_Id__c')
                                .selectField('Account_Sales_Area__r.Term_Of_Payment__c')
                                .selectField('Account_Sales_Area__r.Account__r.Id')
                                .selectField('Account_Sales_Area__r.Account__r.ERP_Customer_Id__c')
                                .selectField('Account_Sales_Area__r.Inco_Term_1__c')
            					.selectField('Account_Sales_Area__r.Customer_Master_Data__r.Mark_For_Deletion__c')
            					.selectField('Account_Sales_Area__r.Account__r.Account_Group__c')
            					.selectField('Account_Sales_Area__r.Customer_Master_Data__r.Account_Group__c')
                                .toSOQL();
        return (List<Account_Relationship__c>) Database.query( strQuery );
    }

    /**
     *  @author Akshay Mohan
     *  @date   26-Sep-2018
     *  @description Fetch the Account Relationships for an Account ERP, Account Sales Area & Relationship
     *  @param Set<String> setAccountERP
     *  @param Set<String> setASAERP
     *  @param lstRelationship of relationships
     *  @return Account_Relationship__c List with related CustomerMasterData
     *
    **/
    public List<Account_Relationship__c> selectByAccountERPSARelationship(Set<String> setAccountERP, Set<String> setASAERP, List<String> lstRelationship)
    {
        if (setAccountERP.isEmpty())
            return new List<Account_Relationship__c>();

        ilib_QueryFactory query = newQueryFactory();

        query.setCondition(' Relationship__c IN :lstRelationship AND Account_Sales_Area__r.IsInactive__c = false '
                            +' AND IsInactive__c = false AND ERP_Customer_Id__c IN :setAccountERP '
                            +' AND Account_Sales_Area__r.Customer_Master_Data__r.Mark_For_Deletion__c = false'
                           	+' AND Account_Sales_Area__r.Account__r.Account_Group__c != \'Legacy\''
                            +' AND Account_Sales_Area__r.Customer_Master_Data__r.Account_Group__c != \'Legacy\' '
                            +' AND Account_Sales_Area__r.ERP_Account_Sales_Area_Id__c IN :setASAERP ');

        //get relationship fields from Customer_Master_Data__c
        CustomerMasterDataSelector selectorCMD = new CustomerMasterDataSelector();
        selectorCMD.configureQueryFactoryFields(query,'Account_Sales_Area__r.Customer_Master_Data__r');

        //select sales area name
        String strQuery = query.selectField('Account_Sales_Area__r.Name')
                                .selectField('Account_Sales_Area__r.ERP_Account_Sales_Area_Id__c')
                                .selectField('Account_Sales_Area__r.Account__r.Id')
                                .selectField('Account_Sales_Area__r.Term_Of_Payment__c')
                                .selectField('Account_Sales_Area__r.Account__r.ERP_Customer_Id__c')
            					.selectField('Account_Sales_Area__r.Customer_Master_Data__r.Mark_For_Deletion__c')
            					.selectField('Account_Sales_Area__r.Account__r.Account_Group__c')
            					.selectField('Account_Sales_Area__r.Customer_Master_Data__r.Account_Group__c')
                                .toSOQL();
        return (List<Account_Relationship__c>) Database.query( strQuery );
    }

    /**
     *  @author Akshay Mohan
     *  @date   30-Aug-2018

     *  @param Set<String> setASAERP
     *  @param String strRelationship
     *  @return Account_Relationship__c List with related CustomerMasterData
     *
    **/
    public List<Account_Relationship__c> selectByASAERPWithRelationship(Set<String> setASAERP, String strRelationship)
    {
        if (setASAERP == null)
            return new List<Account_Relationship__c>();

        // INC0214022 : sometimes a set with only null was passed in
        setASAERP.remove(null);

        if (setASAERP.isEmpty())
            return new List<Account_Relationship__c>();

        // INC0214022 : use IN clase instead of != to eliminate non-selective query
        Set<String> setNotLegacyAccountGroups = Accounts.ACCOUNT_GROUP_VALUES;
        setNotLegacyAccountGroups.remove(Accounts.ACCOUNTGROUP_LEGACY);
        Set<String> setNotLegacyCmdGroups = CustomerMasterDatas.ACCOUNT_GROUP_VALUES;
        setNotLegacyCmdGroups.remove(Accounts.ACCOUNTGROUP_LEGACY);

        ilib_QueryFactory query = newQueryFactory();

        query.setCondition(' Relationship__c = :strRelationship'
                            + ' AND Account_Sales_Area__r.IsInactive__c = false '
                            + ' AND Account_Sales_Area__r.Customer_Master_Data__r.Mark_For_Deletion__c = false'
                           	+ ' AND Account_Sales_Area__r.Account__r.Account_Group__c != \'Legacy\''
                            + ' AND Account_Sales_Area__r.Customer_Master_Data__r.Account_Group__c != \'Legacy\' '
                            + ' AND IsInactive__c = false'
                            + ' AND Account_Sales_Area__r.ERP_Account_Sales_Area_Id__c IN :setASAERP');

        // replacing the != to these broke TestAutomateBillToShipToService, not sure why
        // turns out the problem was the set with null in it
        // I had left these in because it seems better but now removing because of the test issue
        //                  + ' AND Account_Sales_Area__r.Account__r.Account_Group__c IN :setNotLegacyAccountGroups'
        //                  + ' AND Account_Sales_Area__r.Customer_Master_Data__r.Account_Group__c IN :setNotLegacyCmdGroups'

        //get relationship fields from Customer_Master_Data__c
        CustomerMasterDataSelector selectorCMD = new CustomerMasterDataSelector();
        selectorCMD.configureQueryFactoryFields(query,'Account_Sales_Area__r.Customer_Master_Data__r');

        //select sales area name
        String strQuery = query.selectField('Account_Sales_Area__r.Term_Of_Payment__c')
                                .selectField('Account_Sales_Area__r.Customer_Master_Data__c')
                                .selectField('Account_Sales_Area__r.ERP_Account_Sales_Area_Id__c')
            					.selectField('Account_Sales_Area__r.Customer_Master_Data__r.Mark_For_Deletion__c')
            					.selectField('Account_Sales_Area__r.Account__r.Account_Group__c')
            					.selectField('Account_Sales_Area__r.Customer_Master_Data__r.Account_Group__c')
                                .toSOQL();
        System.debug('setASAERP: ' + setASAERP);
        return (List<Account_Relationship__c>) Database.query( strQuery );
    }

    /**
     *  @author Akshay Mohan
     *  @date   26-Sep-2018
     *  @description Fetch the Account Relationships for a CMD ERP Id
     *  @param Set<String> setCMDERP
     *  @param String strASA
     *  @return Account_Relationship__c List with related CustomerMasterData
     *
    **/
    public List<Account_Relationship__c> selectByCMDERPWithASA(Set<String> setCMDERP,String strASA)
    {
        if(setCMDERP.isEmpty())
            return new List<Account_Relationship__c>();

        strASA='%_'+strASA;
        ilib_QueryFactory query = newQueryFactory();
        query.setCondition('Account_Sales_Area__r.ERP_Account_Sales_Area_Id__c LIKE :strASA '
                            +' AND Account_Sales_Area__r.Customer_Master_Data__r.Mark_For_Deletion__c = false'
                            +' AND Account_Sales_Area__r.Account__r.Account_Group__c != \'Legacy\''
                            +' AND Account_Sales_Area__r.Customer_Master_Data__r.Account_Group__c != \'Legacy\' '
                            +' AND IsInactive__c = false AND Account_Sales_Area__r.IsInactive__c = false '
                            +' AND ERP_Customer_Id__c IN :setCMDERP ');

        //select sales area name
        String strQuery = query.selectField('Account_Sales_Area__r.Term_Of_Payment__c')
                                .selectField('Account_Sales_Area__r.ERP_Account_Sales_Area_Id__c')
             					.selectField('Account_Sales_Area__r.Customer_Master_Data__r.Mark_For_Deletion__c')
            					.selectField('Account_Sales_Area__r.Account__r.Account_Group__c')
            					.selectField('Account_Sales_Area__r.Customer_Master_Data__r.Account_Group__c')
                                .toSOQL();
        return (List<Account_Relationship__c>) Database.query( strQuery );
    }

    /*
    * @author Roopal Verma
    * @date   03-28-2019
    * @description Fetch Account Relationships based on Account ERP Id and ASA ERP Id
    *
    */
    public List<Account_Relationship__c> selectByAccERPAndASAERP(set<String> accERPId)
    {
        return (List<Account_Relationship__c>) Database.query(
        newQueryFactory().selectField('Account_Sales_Area__r.ERP_Account_Sales_Area_Id__c')
            			 .selectField('Account_Sales_Area__r.Customer_Master_Data__r.Mark_For_Deletion__c')
            			 .selectField('Account_Sales_Area__r.Account__c')
            			 .selectField('Account_Sales_Area__r.Account__r.Account_Group__c')
            			 .selectField('Account_Sales_Area__r.Customer_Master_Data__r.Account_Group__c')
            			 .setCondition('ERP_Customer_Id__c IN :accERPId'
                         +' AND Account_Sales_Area__r.Account__r.Account_Group__c != \'Legacy\''
                         +' AND Account_Sales_Area__r.Customer_Master_Data__r.Account_Group__c != \'Legacy\' '
                   		 +' AND IsInactive__c = false'
            			 +' AND Account_Sales_Area__r.Customer_Master_Data__r.Mark_For_Deletion__c = false')
            			 .toSOQL());
    }

}