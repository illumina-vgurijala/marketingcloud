/**
* @author Digvijay Singh 
* @date   25-Aug-2020
* @description    Class to Fetch Product Price from SAP 
* Modification Log:
*  ---------------------------------------------------------------------------------------------------------- 
*   Developer                Date                Description                                                 
*   Digvijay                25-Aug-2020           Original
*  ----------------------------------------------------------------------------------------------------------          
*/


public with sharing class GetPricingDetails {
   
    /*
*  @AUTHOR:  Digvijay Singh 
*  @DESCRIPTION: Method to fetch Pricing related data.
*  @PARAM :  List<Id>
*  @RETURN:  List<AccountInfoWrapper>
*/ 
    public static  List<AccountInfoWrapper>  getAccountAndPricingDetails(List<Id> listWDIds){
        
        Map<Id,List<SVMXC__Service_Order_Line__c>> mapWOToWDID=new Map<Id,List<SVMXC__Service_Order_Line__c>>();
        List<SVMXC__Service_Order__c> lstworkOrder=new List<SVMXC__Service_Order__c>();
        Map<String,Id> distERPId=new  Map<String,Id>();
        List<AccountInfoWrapper> listaccountInfoWrapper=new List<AccountInfoWrapper>();
        
        //create a Map mapping work details for each work Order
        for(SVMXC__Service_Order_Line__c wdobj:new WorkDetailsSelector().selectWorkDetailsByWorkDetailId(new set<Id>(listWDIds))){
            if(!mapWOToWDID.containsKey(wdobj.SVMXC__Service_Order__c)){
                mapWOToWDID.put(wdobj.SVMXC__Service_Order__c,new List<SVMXC__Service_Order_Line__c>());
            }
            mapWOToWDID.get(wdobj.SVMXC__Service_Order__c).add(wdobj);
        }
        
        //fetch the List of Work Order
        for(SVMXC__Service_Order__c obj:new WorkOrdersSelector().selectWorkOrders(mapWOToWDID.keySet())){
            lstworkOrder.add(obj);
            distERPId.put(obj.Distributor_Account__c,null);
        }
        
        //fetch the distributor account Id using the distributor ERP Id from work order
        for(Account accobj:new  AccountsSelector().selectAccountsForERPCustomerIds(distERPId.keySet())){
            distERPId.put(accobj.ERP_Customer_Id__c,accobj.id);
        }
        
        //Set the Data needed to find out the Sales Org, DistChannel , Division etc in AccountInfoWrapper object
        for(SVMXC__Service_Order__c wobj:lstworkOrder){
            AccountInfoWrapper wrapobj;
            if(wobj.Partner_Work_Order__c){
                wrapobj=new AccountInfoWrapper(distERPId.get(wobj.Distributor_Account__c),wobj.SVMXC__Company__c,distERPId.get(wobj.Distributor_Account__c),wobj.Partner_Work_Order__c,wobj.Id);
            }else{
                Id soldtoId;
                if(wobj.Sold_To_Account__c==null)
                    soldtoId =wobj.SVMXC__Company__c;
                else
                    soldtoId=wobj.Sold_To_Account__c;
                wrapobj=new AccountInfoWrapper(soldtoId,wobj.SVMXC__Company__c,distERPId.get(wobj.Distributor_Account__c),wobj.Partner_Work_Order__c,wobj.Id);
            }
            wrapobj.lstrelatedrecords=mapWOToWDID.get(wobj.Id);
            listaccountInfoWrapper.add(wrapobj);
            
        }
        //call the pricing method passing the required info in a list of wrapper
        listaccountInfoWrapper=getPricingInfo(listaccountInfoWrapper);
        System.debug('listaccountInfoWrapper....'+listaccountInfoWrapper);
        return listaccountInfoWrapper;
    }
    
 /*
*  @AUTHOR:  Digvijay Singh 
*  @DESCRIPTION: Wrapper class to store Pricing Info.
*/  
    public class AccountInfoWrapper{
        public Id soldtoAccountId;
        public String  soldtoAccountERPId;
        public Id ultimateconsigneeId;
        public String ultimateconsigneeERPId;
        public Id distributorId;
        public String distributorERPId;
        public String salesAreaCodeSoldTo;
        public String salesAreaCodeultimateconsignee;
        public String salesAreaCodedistributor;
        public String currencyCode;
        public Boolean indirectDeal;
        public String key;
        public List<Sobject> lstrelatedrecords ;

/*
*  @AUTHOR:  Digvijay Singh 
*  @DESCRIPTION: constructor to populate fields on AccountInfoWrapper object
*/ 
        public AccountInfoWrapper(Id soldtoAccountId,Id ultimateconsigneeId,Id distributorId,Boolean indirectDeal,String key){
            this.soldtoAccountId=soldtoAccountId;
            this.ultimateconsigneeId=ultimateconsigneeId;
            this.distributorId=distributorId;
            this.indirectDeal=indirectDeal;
            this.key=key;
        }
    }
    
    /*
*  @AUTHOR:  Digvijay Singh 
*  @DESCRIPTION: method to get the Sales area and Pricing info.
*/ 
    public static List<AccountInfoWrapper> getPricingInfo(List<AccountInfoWrapper> lstaccountWrapper){
        //populate SalesAreaId on the Wrapper
        List<AccountInfoWrapper> lstofaccountWrapper=new List<AccountInfoWrapper>();
        lstofaccountWrapper=getSalesAreaInfo(lstaccountWrapper);
        //populate the Curreny and PriceList on the  Wrapper
        lstofaccountWrapper=getPriceListInfo(lstofaccountWrapper);
        return lstofaccountWrapper;      
    }
    
    /*
*  @AUTHOR:  Digvijay Singh 
*  @DESCRIPTION: Method to find out the Sales Area Info
*  @PARAM : List<AccountInfoWrapper>
*  @RETURN:  List<AccountInfoWrapper>
*/
    public static List<AccountInfoWrapper> getSalesAreaInfo(List<AccountInfoWrapper> lstaccountWrapper){
        Set<Id> setToAccount = new Set<Id>();
        for(AccountInfoWrapper wrapObj:lstaccountWrapper){
            setToAccount.add(wrapObj.soldtoAccountId);
            setToAccount.add(wrapObj.ultimateconsigneeId);
            setToAccount.add(wrapObj.distributorId);    
        }
        //Map of Sold To,Ultimate Consignee and Distributor Account on Opportunity record
        Map<Id ,Account> idToAccount = new Map<Id ,Account>(new AccountsSelector().selectAccounts(setToAccount));
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
        
        //Update Sold To Sales Area and Ultimate Consignee Sales Area  
        for (AccountInfoWrapper wrapObj:lstaccountWrapper) {
            Boolean booIndirectDeal=wrapObj.indirectDeal;
            String strAccountBCC;
            String strUCBCC;
            String strDistributorBCC;
            if(idToAccount.containsKey(wrapObj.soldtoAccountId)) {
                strAccountBCC = idToAccount.get(wrapObj.soldtoAccountId).BillingCountryCode;
            }
            if(idToAccount.containsKey(wrapObj.ultimateconsigneeId)) {
                strUCBCC = idToAccount.get(wrapObj.ultimateconsigneeId).BillingCountryCode;
            }
            System.debug('strAccountBCC: '+strAccountBCC);
            System.debug('strUCBCC: '+strUCBCC);
            //Stamping UC Sales Area & Checking match in Sold To Account Sales Area
            if (setToAccount.contains(wrapObj.ultimateconsigneeId) == true && (mapCountryToSalesArea.containsKey(strUCBCC))) {
                wrapObj=getSalesAreaUC(idToAccount,wrapObj,mapCountryToSalesArea,booIndirectDeal,strUCBCC);
            }
            
            String strDisSalesOrg;
            String strDisDistributionChannel;
            String strDisDivision;
           // String strDisRTPDivision;
            //Stamping Distributor Sales Area
            if(booIndirectDeal){
                if(idToAccount.containsKey(wrapObj.distributorId)) {
                    strDistributorBCC = idToAccount.get(wrapObj.distributorId).BillingCountryCode;
                }
                System.debug('strDistributorBCC: '+strDistributorBCC);
                if(setToAccount.contains(wrapObj.distributorId) == true && (mapCountryToSalesArea.containsKey(strDistributorBCC))) {
                    if(idToAccount.get(wrapObj.distributorId).ERP_Customer_Id__c != null){
                        wrapObj.distributorERPId=idToAccount.get(wrapObj.distributorId).ERP_Customer_Id__c;
                        strDisSalesOrg = mapCountryToSalesArea.get(strDistributorBCC).Sales_Organization__c;
                        strDisDistributionChannel = mapCountryToSalesArea.get(strDistributorBCC).Distribution_Channel__c;
                        strDisDivision = mapCountryToSalesArea.get(strDistributorBCC).Division__c;
                        strDisDistributionChannel = '02';
                      //  strDisRTPDivision = '02';
                        wrapObj.salesAreaCodedistributor = idToAccount.get(wrapObj.distributorId).ERP_Customer_Id__c + '_' + strDisSalesOrg + strDisDistributionChannel + strDisDivision;
                    }else 
                        wrapObj.salesAreaCodedistributor = null;
                }   
            }
            System.debug('DisSalesArea'+wrapObj.salesAreaCodedistributor);
            
            String strSoldToERPId;
            if(setToAccount.contains(wrapObj.soldtoAccountId) == true && idToAccount.containsKey(wrapObj.soldtoAccountId))
                strSoldToERPId = idToAccount.get(wrapObj.soldtoAccountId).ERP_Customer_Id__c;
            
            wrapObj.soldtoAccountERPId=strSoldToERPId;
            System.debug('strSoldToERPId' + strSoldToERPId);
            
            //Stamping Sold To Sales Area
            if(!booIndirectDeal && String.isNotBlank(wrapObj.salesAreaCodeultimateconsignee) && strSoldToERPId != null){
                String strOppUC = AutomateBillToShipToService.getSalesAreaFromERP(wrapObj.salesAreaCodeultimateconsignee);
                //opp.Sales_Area_Sold_To__c = strSoldToERPId + '_' + strUCsalesOrg + strUCDistributionChannel + strUCDivision;
                wrapObj.salesAreaCodeSoldTo = strSoldToERPId+ '_' + strOppUC;
            }
            else if (booIndirectDeal && String.isNotBlank(wrapObj.salesAreaCodedistributor) && strSoldToERPId != null)
                wrapObj.salesAreaCodeSoldTo = strSoldToERPId + '_' + strDisSalesOrg + strDisDistributionChannel + strDisDivision;
            else 
                wrapObj.salesAreaCodeSoldTo = null;
            System.debug('SoldToSalesArea'+wrapObj.salesAreaCodeSoldTo);
        }
        return lstaccountWrapper;
    }
    
    /*
*  @AUTHOR:  Digvijay Singh 
*  @DESCRIPTION: Method to find out the Currency and Price List data
*  @PARAM : List<AccountInfoWrapper>
*  @RETURN:  List<AccountInfoWrapper>
*/   
    public static List<AccountInfoWrapper> getPriceListInfo(List<AccountInfoWrapper> lstaccountWrapper){
        Set<Id> setToAccount = new Set<Id>();
        Set<Id> setAccReqASA = new Set<Id>();
        Boolean booIndirectDeal;

       
        
        for(AccountInfoWrapper wrapObj:lstaccountWrapper){
            setToAccount.add(wrapObj.soldtoAccountId);
            setToAccount.add(wrapObj.ultimateconsigneeId);
            setToAccount.add(wrapObj.distributorId);
            setAccReqASA.add(wrapObj.soldtoAccountId);
            setAccReqASA.add(wrapObj.distributorId);
        }
        
        if(setToAccount.isEmpty())
            return lstaccountWrapper;
        
        List<Account_Sales_Area__c> lstAccountSalesArea = new List<Account_Sales_Area__c>();
        //Map of Account ID and related account sales area to store Sold To and Distributor Account Sales Area 
        Map<Id,List<Account_Sales_Area__c>> idToAccDisASA = new Map<Id,List<Account_Sales_Area__c>>();
        //Fetch the Account Sales records for the Sold to and the Distributor 
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
        
        String strUCsalesOrg;
        String strUCDistributionChannel;
        String strUCDivision;
        Map<Id,Account_Sales_Area__c> idToAccSalesArea = new Map<Id,Account_Sales_Area__c>();
        
        for(AccountInfoWrapper wrapObj:lstaccountWrapper){
            booIndirectDeal=wrapObj.indirectDeal;
            //In case of Direct deal , the Ultimate consignee's Sales Area code will be used to get the correct Account to Sales area record for Sold to account.
            if((String.isNotBlank(wrapObj.ultimateconsigneeId) && String.isNotBlank(wrapObj.salesAreaCodeultimateconsignee))){
                String ucSAERP = AutomateBillToShipToService.getSalesAreaFromERP(wrapObj.salesAreaCodeultimateconsignee);
                strUCsalesOrg = ucSAERP.substring(0, 4);
                strUCDistributionChannel = ucSAERP.substring(4, 6);
                strUCDivision = ucSAERP.substring(6, 8);
                System.debug('--strUCsalesOrg--'+strUCsalesOrg);
                System.debug('--strUCDistributionChannel--'+strUCDistributionChannel);
                System.debug('--strUCDivision--'+strUCDivision);
                System.debug('idToAccDisASA...'+idToAccDisASA);
                if (!booIndirectDeal && idToAccDisASA.containsKey(wrapObj.soldtoAccountId)) {
                    for (Account_Sales_Area__c asa : idToAccDisASA.get(wrapObj.soldtoAccountId)) {
                        if (strUCsalesOrg == asa.Sales_Organization__c && strUCDistributionChannel == asa.Distribution_Channel__c && strUCDivision == asa.Division__c){
                            idToAccSalesArea.put(wrapObj.soldtoAccountId,asa);
                            break; //Match found hence exit loop
                        }
                    }
                }
                
            }
            
            
            //In case of Indirect deal , the Distributor's Sales Area code will be used to get the correct Account to Sales area record for Sold to account.
            String strDisSalesOrg;
            String strDisDistributionChannel;
            String strDisDivision;
            //String strIndirectDC;
            if(String.isNotBlank(wrapObj.distributorId) && String.isNotBlank(wrapObj.salesAreaCodedistributor) && booIndirectDeal){
                String disSAERP = AutomateBillToShipToService.getSalesAreaFromERP(wrapObj.salesAreaCodedistributor);
                strDisSalesOrg = disSAERP.substring(0, 4);
                strDisDistributionChannel = disSAERP.substring(4, 6);
                strDisDivision = disSAERP.substring(6, 8);
               // strIndirectDC = '02';
                if(idToAccDisASA.containsKey(wrapObj.distributorId)) {
                    for(Account_Sales_Area__c asa : idToAccDisASA.get(wrapObj.distributorId)) {
                        if(strDisSalesOrg == asa.Sales_Organization__c && strDisDistributionChannel == asa.Distribution_Channel__c && strDisDivision == asa.Division__c) {
                            idToAccSalesArea.put(wrapObj.distributorId,asa);
                            break; //Match found hence exit loop
                        }
                    }    
                } 
            }
            
            //after indentifying the ASA record for Sold to and distributor , get the currency info(use Sold to's ASA for direct deal and and distributor's ASA for indirect deal)  
            System.debug('--idToAccSalesArea--'+idToAccSalesArea);
            if(!idToAccSalesArea.isEmpty()){
                if(!booIndirectDeal){
                    if(idToAccSalesArea.containsKey(wrapObj.soldtoAccountId)){
                        wrapObj.currencyCode=idToAccSalesArea.get(wrapObj.soldtoAccountId).CurrencyIsoCode;
                    }
                }else{
                    if(idToAccSalesArea.containsKey(wrapObj.distributorId)){
                        wrapObj.currencyCode=idToAccSalesArea.get(wrapObj.distributorId).CurrencyIsoCode;
                    }
                }
            } 
        }
        return lstaccountWrapper;      
    }
    
      /*
*  @AUTHOR:  Digvijay Singh 
*  @DESCRIPTION: Method to find out Sales Area
*  @PARAM : Map<Id ,Account>,AccountInfoWrapper,Map<String,Sales_Area__mdt>,Boolean,String
*  @RETURN:  AccountInfoWrapper
*/ 
   public static AccountInfoWrapper  getSalesAreaUC(Map<Id ,Account> idToAccount , AccountInfoWrapper wrapObj,Map<String,Sales_Area__mdt> mapCountryToSalesArea,Boolean booIndirectDeal,String strUCBCC ){
      String strUCsalesOrg;
      String strUCDistributionChannel;
      String strUCDivision;
      if(idToAccount.get(wrapObj.ultimateconsigneeId).ERP_Customer_Id__c != null){
          wrapObj.ultimateconsigneeERPId=idToAccount.get(wrapObj.ultimateconsigneeId).ERP_Customer_Id__c;
          strUCsalesOrg = mapCountryToSalesArea.get(strUCBCC).Sales_Organization__c;
          System.debug('strUCsalesOrg: '+strUCsalesOrg);
          if(booIndirectDeal)
              strUCDistributionChannel = '02';
          else
              strUCDistributionChannel = mapCountryToSalesArea.get(strUCBCC).Distribution_Channel__c;
          
          System.debug('strUCDistributionChannel: '+strUCDistributionChannel);
          strUCDivision = mapCountryToSalesArea.get(strUCBCC).Division__c;
          wrapObj.salesAreaCodeultimateconsignee = idToAccount.get(wrapObj.ultimateconsigneeId).ERP_Customer_Id__c + '_' + strUCsalesOrg + strUCDistributionChannel + strUCDivision;
      }else
          wrapObj.salesAreaCodeultimateconsignee = null;
      
      return wrapObj;
  }   
}