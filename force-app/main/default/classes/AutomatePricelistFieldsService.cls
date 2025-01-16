/**
 * @author Roopal Verma 
 * @date   27-Nov-2018
 * @description    Class to handle population of sales area ids price list fields on Opportunity 
 * Modification Log:
*  ---------------------------------------------------------------------------------------------------------- 
*   Developer                Date                Description                                                 
*   Roopal Verma             27-Nov-2018         Original
*   Joshith K                28-Nov-2019         INC0235038 -update Sold to UC with Sales Org Override value
*   Joshith K                13-Mar-2020         INC0257010--update Sold to UC with  value Ship_To_Sales_Org__c
*   Anand Palla              26-Apr-2022         CodeScan Fix-Avoid Literals in If condition
*   Aman Tyagi               31-Mar-2022         CodeScan Fixes
*   Iram Malik               14-Jul-2021         Codescan Fixes
*   Adyasha Satapathy        05-Jan-2023         Codescan Fix for one line per each Declaration Rule and Remove Unused Variables
*  ----------------------------------------------------------------------------------------------------------          
*/
public class AutomatePricelistFieldsService {

    //Start CodeScan Fix [Avoid Literals in If condition]
    private static final Integer INTEGER_TWO = 2;
    //End CodeScan Fix

    public static Map<Id,Schema.RecordTypeInfo> idToRecordType = Opportunity.sobjectType.getDescribe().getRecordTypeInfosById();

    /*
    * @Author: Roopal Verma
    * @Description :
    * @param :Map<Id, List<Opportunity>> changedSoldToIdToOpp, Map<Id, List<Opportunity>> changedUCIdToOpp, Map<Id, List<Opportunity>> changedDisIdToOpp, Boolean isUpdate
    */ 
	public static Map<id,Opportunity> stampSalesAreaIdFields(Map<Id, List<Opportunity>> changedSoldToIdToOpp, Map<Id, List<Opportunity>> changedUCIdToOpp, Map<Id, List<Opportunity>> changedDisIdToOpp, Boolean isUpdate){

		Boolean booIndirectDeal;
        Set<String> setIndirectRecordTypeName = new Set<String>{Label.OpportunityRTIndirectStandard,Label.IndirectReOrder,Label.IndirectFieldServices};

		Set<Id> setToAccount = new Set<Id>();
		setToAccount.addAll(changedSoldToIdToOpp.keySet());
		setToAccount.addAll(changedUCIdToOpp.keySet());
		setToAccount.addAll(changedDisIdToOpp.keySet());

        Map<Id, Opportunity> idToOppReturned = new Map<Id, Opportunity>();

        System.debug('--ServicechangedSoldToIdToOpp--'+changedSoldToIdToOpp);
        System.debug('--ServicechangedUCIdToOpp--'+changedUCIdToOpp);
        System.debug('--ServicechangedDisIdToOpp--'+changedDisIdToOpp);

		List<Opportunity> lstOpportunity = new List<Opportunity>();
		for (List<Opportunity> opp : changedSoldToIdToOpp.values())
			lstOpportunity.addAll(opp);

		for (List<Opportunity> opp : changedUCIdToOpp.values())
			lstOpportunity.addAll(opp);

		for (List<Opportunity> opp : changedDisIdToOpp.values())
			lstOpportunity.addAll(opp);

		if(setToAccount.isEmpty())
            return null;
        // Map of Sold To,Ultimate Consignee and Distributor Account on Opportunity record
        Map<Id ,Account> idToAccount = new Map<Id ,Account>(new AccountsSelector().selectAccounts(setToAccount));
        System.debug('idToAccount: '+idToAccount);
        
        //Set to store the Country Code for the Sold To,Ultimate Consignee and Distributor Account
        Set<String> setCountryCode = new Set<String>();
        setCountryCode = UtilsCollection.getSetOfStrings(idToAccount.values(),'BillingCountryCode');
        System.debug('setCountryCode'+setCountryCode);

        if (setCountryCode.isEmpty())
            return null;

        //List storing the Sales Area Custom Metadata for the Country Codes on Opportunity
        List<Sales_Area__mdt> lstSalesArea = new SalesAreasSelector().selectSalesArea(setCountryCode);
        //Map to store country with Sales Area Meta Data Record
        Map<String,Sales_Area__mdt> mapCountryToSalesArea = new Map<String,Sales_Area__mdt>();
        if (!lstSalesArea.isEmpty()) {
            for (Sales_Area__mdt sal:lstSalesArea) {
                mapCountryToSalesArea.put(sal.Country_Code__c,sal);
            }
        }
        System.debug('mapCountryToSalesArea: '+mapCountryToSalesArea);

        //Update Sold To Sales Area and Ultimate Consignee Sales Area on Opportunity 
        for (Opportunity opp:lstOpportunity) {
            String strRecordTypeName = idToRecordType.get(opp.RecordTypeId).getDeveloperName();
            booIndirectDeal= setIndirectRecordTypeName.contains(strRecordTypeName);
            String strAccountBCC;
            String strUCBCC;
            String strDistributorBCC;
            if(idToAccount.containsKey(opp.AccountId)) {
                strAccountBCC = idToAccount.get(opp.AccountId).BillingCountryCode;
            }
            if(idToAccount.containsKey(opp.Ultimate_Consignee__c)) {
                strUCBCC = idToAccount.get(opp.Ultimate_Consignee__c).BillingCountryCode;
            }
            System.debug('strAccountBCC: '+strAccountBCC);
            System.debug('strUCBCC: '+strUCBCC);
            
            String strUCsalesOrg;
            String strUCDistributionChannel;
            String strUCDivision;
            Boolean booDStoUC = opp.Direct_Sale_to_Ultimate_Consignee__c;
            
            //Stamping UC Sales Area & Checking match in Sold To Account Sales Area
            if (setToAccount.contains(opp.Ultimate_Consignee__c) == true && (mapCountryToSalesArea.containsKey(strUCBCC))) {
                if(idToAccount.get(opp.Ultimate_Consignee__c).ERP_Customer_Id__c != null){
                    //INC0235038
                    //if(String.isNotBlank(opp.Sales_Org_Override__c) && !booIndirectDeal)
                    if(String.isNotBlank(opp.Sales_Org_Override__c))
                        strUCsalesOrg = opp.Sales_Org_Override__c;
                    else if(String.isNotBlank(opp.Ship_To_Sales_Org__c))
                        strUCsalesOrg = opp.Ship_To_Sales_Org__c;

                    else
                        strUCsalesOrg = mapCountryToSalesArea.get(strUCBCC).Sales_Organization__c;
                    System.debug('strUCsalesOrg: '+strUCsalesOrg);
                    if(booIndirectDeal && !booDStoUC)
                        strUCDistributionChannel = '02';
                    else
                        strUCDistributionChannel = mapCountryToSalesArea.get(strUCBCC).Distribution_Channel__c;
                    System.debug('strUCDistributionChannel: '+strUCDistributionChannel);
                    strUCDivision = mapCountryToSalesArea.get(strUCBCC).Division__c;
                    opp.Sales_Area_Ultimate_Consignee__c = idToAccount.get(opp.Ultimate_Consignee__c).ERP_Customer_Id__c + '_' + strUCsalesOrg + strUCDistributionChannel + strUCDivision;
                }
                else
                opp.Sales_Area_Ultimate_Consignee__c = null;
            }
            System.debug('UCSalesArea'+opp.Sales_Area_Ultimate_Consignee__c);

            String strDisSalesOrg;
            String strDisDistributionChannel;
            String strDisDivision;
            String strSoldToSA;
            //Stamping Distributor Sales Area
            if(booIndirectDeal){
                if(idToAccount.containsKey(opp.Distributor__c)) {
                    strDistributorBCC = idToAccount.get(opp.Distributor__c).BillingCountryCode;
                }
                System.debug('strDistributorBCC: '+strDistributorBCC);
                if(setToAccount.contains(Opp.Distributor__c) == true && (mapCountryToSalesArea.containsKey(strDistributorBCC))) {
                    if(idToAccount.get(opp.Distributor__c).ERP_Customer_Id__c != null){
                        if(String.isNotBlank(opp.Sales_Org_Override__c))
                            strDisSalesOrg = opp.Sales_Org_Override__c;
                        else if(String.isNotBlank(opp.Ship_To_Sales_Org__c))
                            strDisSalesOrg = opp.Ship_To_Sales_Org__c;

                        else
                            strDisSalesOrg = mapCountryToSalesArea.get(strDistributorBCC).Sales_Organization__c;
                        strDisDistributionChannel = mapCountryToSalesArea.get(strDistributorBCC).Distribution_Channel__c;
                        strDisDivision = mapCountryToSalesArea.get(strDistributorBCC).Division__c;
                        strDisDistributionChannel = '02';
                        opp.Sales_Area_Distributor__c = idToAccount.get(opp.Distributor__c).ERP_Customer_Id__c + '_' + strDisSalesOrg + strDisDistributionChannel + strDisDivision;
                    }else 
                    opp.Sales_Area_Distributor__c = null;
                }   
            }
            System.debug('DisSalesArea'+opp.Sales_Area_Distributor__c);

                String strSoldToERPId;
                if(setToAccount.contains(opp.AccountId) == true && idToAccount.containsKey(opp.AccountId))
                   strSoldToERPId = idToAccount.get(opp.AccountId).ERP_Customer_Id__c;
                else if(String.isNotBlank(opp.Sales_Area_Sold_To__c)){
                   List<String> lstSalesAreaSplit = opp.Sales_Area_Sold_To__c.split('_');
                   if(lstSalesAreaSplit.size()==INTEGER_TWO)
                   strSoldToERPId= lstSalesAreaSplit[0];
                }

                System.debug('strSoldToERPId' + strSoldToERPId);
                    
                //Stamping Sold To Sales Area
                
                    if((!booIndirectDeal || (booIndirectDeal && booDStoUC)) 
                            && String.isNotBlank(opp.Sales_Area_Ultimate_Consignee__c) && strSoldToERPId != null){
                        String strOppUC = AutomateBillToShipToService.getSalesAreaFromERP(opp.Sales_Area_Ultimate_Consignee__c);
                        //opp.Sales_Area_Sold_To__c = strSoldToERPId + '_' + strUCsalesOrg + strUCDistributionChannel + strUCDivision;
                        opp.Sales_Area_Sold_To__c = strSoldToERPId+ '_' + strOppUC;
                    }
                    else if (booIndirectDeal && !booDStoUC && String.isNotBlank(opp.Sales_Area_Distributor__c) && strSoldToERPId != null)
                        opp.Sales_Area_Sold_To__c = strSoldToERPId + '_' + strDisSalesOrg + strDisDistributionChannel + strDisDivision;
                    else 
                        opp.Sales_Area_Sold_To__c = null;
                    if(isUpdate && booIndirectDeal &&  
                       (changedSoldToIdToOpp.containskey(opp.AccountId) ||
                        changedUCIdToOpp.containsKey(opp.Ultimate_Consignee__c)
                        && !(changedDisIdToOpp.containsKey(opp.Distributor__c)))){
                        if (strSoldToERPId == null || ((!booIndirectDeal || (booIndirectDeal && booDStoUC)) && opp.Sales_Area_Ultimate_Consignee__c == null) || ((booIndirectDeal && !booDStoUC) && opp.Sales_Area_Distributor__c == null) ){
                           opp.Sales_Area_Sold_To__c = null; 
                           }else{
                            if(booDStoUC)
                                strSoldToSA = AutomateBillToShipToService.getSalesAreaFromERP(opp.Sales_Area_Ultimate_Consignee__c);
                            else
                                strSoldToSA = AutomateBillToShipToService.getSalesAreaFromERP(opp.Sales_Area_Distributor__c);
                        opp.Sales_Area_Sold_To__c = strSoldToERPId + '_' + strSoldToSA;
                        }
                    }
                    idToOppReturned.put(opp.id,opp);

        System.debug('SoldToSalesArea'+opp.Sales_Area_Sold_To__c);
        }
        return idToOppReturned;
	}

    /*
    * @Author: Roopal Verma
    * @Description :
    * @param :Map<Id, List<Opportunity>> changedSoldToIdToOpp, Map<Id, List<Opportunity>> changedUCIdToOpp, Map<Id, List<Opportunity>> changedDisIdToOpp, Set<Id> setAccReq, Boolean isUpdate
    */
	public static Map<Id, Opportunity> stampPricelistFields(Map<Id, List<Opportunity>> changedSoldToIdToOpp, Map<Id, List<Opportunity>> changedUCIdToOpp, Map<Id, List<Opportunity>> changedDisIdToOpp, Set<Id> setAccReq, Boolean isUpdate){

		Boolean booIndirectDeal;
        Set<String> setIndirectRecordTypeName = new Set<String>{Label.OpportunityRTIndirectStandard,Label.IndirectReOrder,Label.IndirectFieldServices};

		Set<Id> setToAccount = new Set<Id>();
		setToAccount.addAll(changedSoldToIdToOpp.keySet());
		setToAccount.addAll(changedUCIdToOpp.keySet());
		setToAccount.addAll(changedDisIdToOpp.keySet());

        System.debug('--PLchangedSoldToIdToOpp--'+changedSoldToIdToOpp);
        System.debug('--PLchangedUCIdToOpp--'+changedUCIdToOpp);
        System.debug('--PLchangedDisIdToOpp--'+changedDisIdToOpp);

        System.debug('--setToAccount--'+setToAccount);
        Set<Id> setAccReqASA = new Set<Id>();
        setAccReqASA.addAll(setAccReq);
		setAccReqASA.addAll(changedDisIdToOpp.keySet());
        System.debug('--setAccReqASA--'+setToAccount);

        Map<Id, Opportunity> idToOpp = new Map<Id,Opportunity>();

		List<Opportunity> lstOpportunity = new List<Opportunity>();
		for (List<Opportunity> opp : changedSoldToIdToOpp.values()){
			lstOpportunity.addAll(opp);
            idToOpp.putAll(lstOpportunity);
        }

		for (List<Opportunity> opp : changedUCIdToOpp.values()){
			lstOpportunity.addAll(opp);
            idToOpp.putAll(lstOpportunity);
        }

		for (List<Opportunity> opp : changedDisIdToOpp.values()){
			lstOpportunity.addAll(opp);
            idToOpp.putAll(lstOpportunity);
        }

		if(setToAccount.isEmpty())
            return null;

        Map<Id, Opportunity> idToOppReturned = new Map<Id, Opportunity>();
        System.debug('idToOpp'+idToOpp);

        List<Account_Sales_Area__c> lstAccountSalesArea = new List<Account_Sales_Area__c>();
        //Map of Account ID and related account sales area to store Sold To and Distributor Account Sales Area 
        Map<Id,List<Account_Sales_Area__c>> idToAccDisASA = new Map<Id,List<Account_Sales_Area__c>>();

        if (!setAccReqASA.isEmpty())
            lstAccountSalesArea = new AccountSalesAreaSelector().selectAccountSaleaArea(setAccReqASA);
        System.debug('lstAccountSalesArea: ' +lstAccountSalesArea);
        if (!lstAccountSalesArea.isEmpty()) {
            for (Account_Sales_Area__c asa :lstAccountSalesArea) {
                if (idToAccDisASA.containsKey(asa.Account__c)) {
                    idToAccDisASA.get(asa.Account__c).add(asa);
                } else {
                    idToAccDisASA.put(asa.Account__c,new List<Account_Sales_Area__c>{asa});
                }
            }
        }
        System.debug('idToAccDisASA: ' +idToAccDisASA);

        String strUCsalesOrg;
        String strUCDistributionChannel;
        String strUCDivision;

        Map<Id,Account_Sales_Area__c> idToAccSalesArea = new Map<Id,Account_Sales_Area__c>();

        //for (Opportunity opp:idToOpp.values()){
        for (Opportunity opp:lstOpportunity){

            String strRecordTypeName = idToRecordType.get(opp.RecordTypeId).getDeveloperName();
            booIndirectDeal= setIndirectRecordTypeName.contains(strRecordTypeName);

            if((String.isNotBlank(opp.Ultimate_Consignee__c) && String.isNotBlank(opp.Sales_Area_Ultimate_Consignee__c))){
            String ucSAERP = AutomateBillToShipToService.getSalesAreaFromERP(opp.Sales_Area_Ultimate_Consignee__c);

            strUCsalesOrg = ucSAERP.substring(0, 4);
            strUCDistributionChannel = ucSAERP.substring(4, 6);
            strUCDivision = ucSAERP.substring(6, 8);

            System.debug('--strUCsalesOrg--'+strUCsalesOrg);
            System.debug('--strUCDistributionChannel--'+strUCDistributionChannel);
            System.debug('--strUCDivision--'+strUCDivision);

        	
        		if(!booIndirectDeal) {
                    if (idToAccDisASA.containsKey(opp.AccountId)) {
                        for (Account_Sales_Area__c asa : idToAccDisASA.get(Opp.AccountId)) {
                            if (strUCsalesOrg == asa.Sales_Organization__c && strUCDistributionChannel == asa.Distribution_Channel__c && strUCDivision == asa.Division__c){
                                idToAccSalesArea.put(opp.AccountId,asa);
                                break; //Match found hence exit loop
                            }
                        }
                    }
                }     
           }


        	String strDisSalesOrg;
            String strDisDistributionChannel;
            String strDisDivision;
            String strIndirectDC;

            if(String.isNotBlank(opp.Distributor__c) && String.isNotBlank(opp.Sales_Area_Distributor__c) && booIndirectDeal){


            String disSAERP = AutomateBillToShipToService.getSalesAreaFromERP(opp.Sales_Area_Distributor__c);

            strDisSalesOrg = disSAERP.substring(0, 4);
            strDisDistributionChannel = disSAERP.substring(4, 6);
            strDisDivision = disSAERP.substring(6, 8);

            Boolean booDStoUC = opp.Direct_Sale_to_Ultimate_Consignee__c;
             if(booDStoUC)
                strIndirectDC = '01';
            else
                strIndirectDC = '02';

        	if(idToAccDisASA.containsKey(opp.Distributor__c)) {
                for(Account_Sales_Area__c asa : idToAccDisASA.get(Opp.Distributor__c)) {
                    if(strDisSalesOrg == asa.Sales_Organization__c && strDisDistributionChannel == asa.Distribution_Channel__c && strDisDivision == asa.Division__c) {
                        idToAccSalesArea.put(opp.Distributor__c,asa);
                            break; //Match found hence exit loop
                        }
                    }    
                } 
            }
           
            System.debug('--idToAccSalesArea--'+idToAccSalesArea);
            if(!idToAccSalesArea.isEmpty()){
                if(!booIndirectDeal){
                    if(idToAccSalesArea.containsKey(opp.AccountId)){
                        setPriceListFields(opp,idToAccSalesArea,opp.AccountId);
                        idToOppReturned.put(opp.id, opp);
                    }
                }else{
                    if(idToAccSalesArea.containsKey(opp.Distributor__c)){
                        setPriceListFields(opp,idToAccSalesArea,opp.Distributor__c);
                        opp.Sold_to_Distribution_Channel__c = strIndirectDC;
                        idToOppReturned.put(opp.id, opp);
                    }
                }
            } else {
                if(!(isUpdate && booIndirectDeal &&
                       (changedSoldToIdToOpp.containsKey(opp.AccountId)||
                        changedUCIdToOpp.containsKey(opp.Ultimate_Consignee__c))
                        && !(changedDisIdToOpp.containsKey(opp.Distributor__c)))){
                    setPriceListFields(opp,null,null);
                    idToOppReturned.put(opp.id, opp); 
                }
            }
        }
        return idToOppReturned;
    }

    /**
     *  @author Rahul Sharma 
     *  @description Set values on Opportunity based on Account Sales Area record
     *  @param Map<Id,Account_Sales_Area__c> idToASA
     *  @param Opportunity objOpp
     *  @param Id accId
     *  @param String strIndirectDC
     *  @return void
     **/
    public static void setOpportunityValue(Map<Id,Account_Sales_Area__c> idToASA,
                                    Opportunity objOpp,Id accId,Map<String,String> strToValue){
        for(String str: strToValue.keySet()){
            if(idToASA!=null && !idToASA.isEmpty()){
                Object oValue = idToASA.get(accId).get(strToValue.get(str));
                objOpp.put(str,oValue);
            }
            else{
                objOpp.put(str,null);
            }   
        }
    }

    /*
    * @Author: Roopal Verma
    * @Description : static method for setting up the price list fields
    * @param : Opportunity objOpp,Map<Id,Account_Sales_Area__c> idToAccSalesArea,Id idAccount
    * @return: coid
    */
    public static void setPriceListFields(Opportunity objOpp,Map<Id,Account_Sales_Area__c> idToAccSalesArea,Id idAccount){ 
        if(idAccount!=null){
             Map<String,String> oppFieldToASAField =  new Map<String,String>{
                        'Price_List_Type__c' => 'Price_List_Type__c',
                        'Price_List__c' => 'Price_List__c',
                        'CurrencyIsoCode' => 'CurrencyIsoCode',
                        'Contract_Number__c' => 'Contract_Number__c',
                        'Company_Code__c' => 'Company_Code__c',
                        'Sold_to_Sales_Organization__c' => 'Sales_Organization__c',
                        'Sold_to_Distribution_Channel__c' => 'Distribution_Channel__c',
                        'Sold_to_Division__c' => 'Division__c'};
            for(String strOppField:oppFieldToASAField.keySet())
                objOpp.put(strOppField,idToAccSalesArea.get(idAccount).get(oppFieldToASAField.get(strOppField)));
        }else{
            Set<String> setNullFields = new Set<String>{'Price_List_Type__c','Price_List__c','Contract_Number__c',
                                            'Company_Code__c','Sold_to_Sales_Organization__c',
                                            'Sold_to_Distribution_Channel__c','Sold_to_Division__c'};
            for(String strOppField:setNullFields)
                objOpp.put(strOppField,null);
        }
        
    }

}