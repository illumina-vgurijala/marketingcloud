/**
 *    @author Satya Swain
 *    @date   04-March-2020
 *    @description    AgreementAccountRelationships domain class
 *    @Test Class for above 90% coverage.
 *    -TestChannelPartnerQuotaAutomation
 *    -TestTAPS_ApttusRelatedAgreement
 *    -TestTAPS_ApttusDocumentVersion
 *    -TestOpenOfferAgreements
 *    @Test Class for atleast 75% coverage.
 *    -TestTAPS_ApttusRelatedAgreement
      -TestChannelPartnerQuotaAutomation
      -TestTAPS_ApttusDocumentVersion
 *    Modification Log:
 *   ---------------------------------------------------------------------------------------------------------------------------
 *    Developer                   Date                  Description
 *    Satya                   04-March-2020           Initial Version
 *    Rishab                  18-Feb-2021             DCP-43224 Update account on Agreement      
 *    Bharath Varma           25-Mar-2022             TASK0718153 - Added resharing of relatedAgreement when a AgreementAccountRelationship gets inserted or updated
 *    Saddam                  29-Sep-22               DCp-56505 - Created new method populateAccountAddress , To Populate Account Adress field From Account on before insert and update.
 *   ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class AgreementAccountRelationships extends ilib_SObjectDomain {

    private static final String LOG_TITLE = 'AgreementAccountRelationships';

    /*Constructor method */
    public AgreementAccountRelationships(List<Agreement_Account_Relationship__c> sObjectList) {
        super(sObjectList);
    }
    /**
     * Boilerplate which is required for base class instantiation logic
     **/
    public class Constructor implements ilib_SObjectDomain.IConstructable {
        /*Param - sobjectList  */
        public ilib_SObjectDomain construct(List<SObject> sObjectList) {
            return new AgreementAccountRelationships(sObjectList);
        }
    }
    /*Trigger Before Insert method - runs before record is saved in database (in insert scenario) */
    public override void onBeforeInsert()
    {
        List<Agreement_Account_Relationship__c> lstAgreementAccountRelationship = (List<Agreement_Account_Relationship__c>)records;

        setDefaultSalesOrgAndCurrency(lstAgreementAccountRelationship);
        populateCompanyCodeDetails(lstAgreementAccountRelationship);
    }

    /*Trigger Before Update method - runs before record is saved in database (in update scenario) */
    public override void onBeforeUpdate(Map<Id, sObject> existingRecords)
    {
        List<Agreement_Account_Relationship__c> lstAgreementAccountRelationship = (List<Agreement_Account_Relationship__c>) records;

        setDefaultSalesOrgAndCurrency(lstAgreementAccountRelationship);
        populateCompanyCodeDetails(lstAgreementAccountRelationship);
    }

    /*Trigger After Insert method - runs after record is saved in database */
    public override void onAfterInsert()
    {
        Set<Id> agreementIds = UtilsCollection.getSetOfIds(records, 'Agreement__c');
        TAPS_OrchestratorInterface tapsOrchestrator = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
        tapsOrchestrator.recalculateRecordChanges(agreementIds, Apttus__APTS_Agreement__c.SObjectType);//DCP-44091
        tapsOrchestrator.recalculateRecordChanges(agreementIds, Apttus__DocumentVersion__c.SObjectType);//DCP-44091
        // TASK0718153 - Added resharing when a AgreementAccountRelationship gets inserted
		tapsOrchestrator.recalculateRecordChanges(agreementIds, Apttus__APTS_Related_Agreement__c.SObjectType);//DCP-44091
    }

    /* Description - DCP-43224 Update account on Agreement  */
    public override void onAfterUpdate(Map<Id, sObject> existingRecords)
    {
        // // determine which agreements have a sharing impact
        // // manually calculate since
        // // there currently is not a utility method for changes in junction objects
         Set<Id> affectedAgreementIds = new Set<Id>();
         for (Agreement_Account_Relationship__c rec : (List<Agreement_Account_Relationship__c>)records)
         {
             Agreement_Account_Relationship__c oldRec = (Agreement_Account_Relationship__c)existingRecords.get(rec.Id);
        
             if (rec.Account__c != oldRec.Account__c)
            {
                affectedAgreementIds.add(rec.Agreement__c);
            }

            //if (rec.Agreement__c != oldRec.Agreement__c)
            //{
            //    affectedAgreementIds.add(rec.Agreement__c);
            //    affectedAgreementIds.add(oldRec.Agreement__c);
            // }
         }

         if (!affectedAgreementIds.isEmpty())
         {  
            TAPS_OrchestratorInterface tapsOrchestratorInst= (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
            tapsOrchestratorInst.recalculateRecordChanges(affectedAgreementIds, Apttus__APTS_Agreement__c.SObjectType);//DCP-44091
			tapsOrchestratorInst.recalculateRecordChanges(affectedAgreementIds, Apttus__DocumentVersion__c.SObjectType);//DCP-44091
            // TASK0718153 - Added resharing when a AgreementAccountRelationship gets updated
            tapsOrchestratorInst.recalculateRecordChanges(affectedAgreementIds, Apttus__APTS_Related_Agreement__c.SObjectType);//DCP-44091

         }
    }

    /**
    *  @author Satya Swain
    *  @description Populate Default Sales Org and Currency on Agreement Account Relationship record for DCP-34983
    *  @param List<Agreement_Account_Relationship__c> lstAgreementAccountRelationship
    **/
    private void setDefaultSalesOrgAndCurrency(List<Agreement_Account_Relationship__c> lstAgreementAccountRelationship)
    {
        Set<Id> setAccountIds = new Set<Id>();
        for(Agreement_Account_Relationship__c objAAR : lstAgreementAccountRelationship){
            setAccountIds.add(objAAR.Account__c);
        }
        if(setAccountIds.isEmpty()) { return; }

        List<Account> lstAccount = new AccountsSelector().selectAccounts(setAccountIds);
        Map<Id, Account> mapIdToAccount = new Map<Id, Account>();
        Map<String,String> mapAccountWithCountryCode = new Map<String,String>();
        for(Account objAcc : lstAccount)
        {
            if(!mapIdToAccount.containsKey(objAcc.Id)){
                mapIdToAccount.put(objAcc.Id,objAcc);  
            }
            if(!mapAccountWithCountryCode.containsKey(objAcc.Id)){
                mapAccountWithCountryCode.put(objAcc.Id,objAcc.BillingCountryCode);
            }
        }
        //Map<String,String> mapAccountWithCountryCode = UtilsObject.getMapOfStringToString(lstAccount,'Id','BillingCountryCode');
        Set<String> setCountryCodes = new Set<String>(mapAccountWithCountryCode.values());
        Map<String,String> mapSalesArea = UtilsObject.getMapOfStringToString(new SalesAreasSelector().selectSalesArea(setCountryCodes),'Country_Code__c','Sales_Organization__c');
        for(Agreement_Account_Relationship__c objAAR : lstAgreementAccountRelationship)
        {
            if(objAAR.Account_Default_Sales_Org__c == NULL)
            {
                objAAR.Account_Default_Sales_Org__c = mapSalesArea.get(mapAccountWithCountryCode.get(objAAR.Account__c));
            }
            if(mapIdToAccount.containsKey(objAAR.Account__c)){
                objAAR.CurrencyIsoCode = mapIdToAccount.get(objAAR.Account__c).CurrencyIsoCode;
                populateAccountAddress(mapIdToAccount,objAAR); //56505
            }
        }
    }
    /**
    *  @author Saddam
    *  @description To Populate Account Adress field From Account on before insert and update.
    *  @param Map<Id,Account>, Agreement_Account_Relationship__c
    *       
    **/
    public static void populateAccountAddress(Map<Id,Account> mapIdToAccount,Agreement_Account_Relationship__c objAAR) {
        
        ilib_LogEvent.push(LOG_TITLE+'populateAccountAddress()');
        
        Account objAccount =  mapIdToAccount.get(objAAR.Account__c);
        String strAddress = '';
        strAddress += String.IsNotBlank(objAccount.BillingStreet) && String.IsNotBlank(objAccount.BillingCity) ? objAccount.BillingStreet+' '+objAccount.BillingCity+'\n' : '';
        strAddress += String.IsNotBlank(objAccount.BillingStreet) && String.IsBlank(objAccount.BillingCity) ? objAccount.BillingStreet+'\n' : '';
        strAddress += String.IsBlank(objAccount.BillingStreet) && String.IsNotBlank(objAccount.BillingCity) ? objAccount.BillingCity+'\n' : '';
        strAddress += String.IsNotBlank(objAccount.BillingState) ? objAccount.BillingState + '\n' : '';
        strAddress += String.IsNotBlank(objAccount.BillingPostalCode) ? objAccount.BillingPostalCode + '\n' : '';
        strAddress += String.IsNotBlank(objAccount.BillingCountry) ? objAccount.BillingCountry:'';

        objAAR.Account_Address__c = strAddress;

        ilib_LogEvent.pop();
    }
    /**
    *  @author Satya Swain
    *  @description Populate Company Name and Company Address on Agreement Account Relationship record for DCP-34983
    *  @param List<Agreement_Account_Relationship__c> lstAgreementAccountRelationship
	*  DCP-37110 - Removed Footer_Full_Street__c,Footer_City__c from logic as these two field containing same address which we have in Address Line(to overcome on duplicate text in address).
    **/
    private void populateCompanyCodeDetails(List<Agreement_Account_Relationship__c> lstAgreementAccountRelationship)
    {
        if(lstAgreementAccountRelationship.isEmpty()) { return; }
        Set<String> setCompanyCode = new Set<String>();
        Map<String,Company_Code_Address__mdt> mapCmpnyCde2CmpnyCdeAdd = new Map<String,Company_Code_Address__mdt>();
        String strCompanyAddress = '';
        for(Agreement_Account_Relationship__c objAAR : lstAgreementAccountRelationship)
        {
            if(String.isNotBlank(objAAR.Account_Default_Sales_Org__c))
            {
                setCompanyCode.add(objAAR.Account_Default_Sales_Org__c);
            }
        }
        if(!setCompanyCode.isEmpty())
        {
            for(Company_Code_Address__mdt ccAdd : new CompanyCodeAddressesSelector().selectCompanyCodeAddress(setCompanyCode))
            {
                mapCmpnyCde2CmpnyCdeAdd.put(ccAdd.Company_Code__c,ccAdd);
            }
        }
        for(Agreement_Account_Relationship__c objAAR : lstAgreementAccountRelationship)
        {
            strCompanyAddress = '';
            if(String.isNotBlank(objAAR.Account_Default_Sales_Org__c) && mapCmpnyCde2CmpnyCdeAdd.containsKey(objAAR.Account_Default_Sales_Org__c))
            {
                objAAR.Company_Name__c = String.isNotBlank(mapCmpnyCde2CmpnyCdeAdd.get(objAAR.Account_Default_Sales_Org__c).Company_Name__c)?
                mapCmpnyCde2CmpnyCdeAdd.get(objAAR.Account_Default_Sales_Org__c).Company_Name__c : '';

                strCompanyAddress = String.isNotBlank(mapCmpnyCde2CmpnyCdeAdd.get(objAAR.Account_Default_Sales_Org__c).Address_Line_1__c )? 
                mapCmpnyCde2CmpnyCdeAdd.get(objAAR.Account_Default_Sales_Org__c).Address_Line_1__c + '\n' : '';

                strCompanyAddress += String.isNotBlank(mapCmpnyCde2CmpnyCdeAdd.get(objAAR.Account_Default_Sales_Org__c).Address_Line_2__c )? 
                mapCmpnyCde2CmpnyCdeAdd.get(objAAR.Account_Default_Sales_Org__c).Address_Line_2__c + '\n' : '';
                
                strCompanyAddress += String.isNotBlank(mapCmpnyCde2CmpnyCdeAdd.get(objAAR.Account_Default_Sales_Org__c).Address_Line_3__c )? 
                mapCmpnyCde2CmpnyCdeAdd.get(objAAR.Account_Default_Sales_Org__c).Address_Line_3__c + '\n' : '';
                
                strCompanyAddress += String.isNotBlank(mapCmpnyCde2CmpnyCdeAdd.get(objAAR.Account_Default_Sales_Org__c).Address_Line_4__c )? 
                mapCmpnyCde2CmpnyCdeAdd.get(objAAR.Account_Default_Sales_Org__c).Address_Line_4__c + '\n' : '';
                
                strCompanyAddress += String.isNotBlank(mapCmpnyCde2CmpnyCdeAdd.get(objAAR.Account_Default_Sales_Org__c).Address_Line_5__c )? 
                mapCmpnyCde2CmpnyCdeAdd.get(objAAR.Account_Default_Sales_Org__c).Address_Line_5__c + '\n' : '';
                
                strCompanyAddress += String.isNotBlank(mapCmpnyCde2CmpnyCdeAdd.get(objAAR.Account_Default_Sales_Org__c).Address_Line_6__c )? 
                mapCmpnyCde2CmpnyCdeAdd.get(objAAR.Account_Default_Sales_Org__c).Address_Line_6__c + '\n' : '';
                

                objAAR.Company_Address__c = String.isNotBlank(strCompanyAddress)? strCompanyAddress : '';
            }
            else
            {
                objAAR.Company_Name__c = '';
                objAAR.Company_Address__c = '';
            }
        }
    }

}