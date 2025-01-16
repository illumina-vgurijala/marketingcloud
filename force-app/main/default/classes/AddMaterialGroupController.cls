/**
*    @author        Tapas Chakraborty
*    @date          Sep-12-2020
*    @description   DCP-40571 add material groups to  Standing Quote Opportunities(used in manageMaterialGroupsLwc)
*    Modification Log:
*    -------------------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Tapas Chakraborty              17 Aug 2020         Initial Version: DCP-40571 add material groups to  Standing Quote Opportunities
*             Aman Tyagi                     31 Mar 2022         Codescan Fixes
*------------------------------------------------------------- ------------------------------------------------------------------------------------------------------
*/
public with sharing class AddMaterialGroupController {
    public static final String RETURN_MSG_SUCCESS = 'Success';
    public static final String STRING_YES = 'Yes';
    public static final String STRING_MG1 = 'Material Group 1';
    public static final String STRING_MG = 'Material Group';
    public static final String STRING_MG_API_NAME = 'Material_Group__c';
    

    /**
     * @author Tapas Chakraborty
     * @date   09 Sep 2020
     * @description    DCP-40571 fetch all material groups from opty's agreement to show in a table
     * before update trigger method
     **/   
    @AuraEnabled(cacheable=true)
    public static  String getMaterialGroups(Id agreementId, Id opportunityId){
        
        List<WrapperClass> lstWrapisChecked = new List<WrapperClass>();
        List<WrapperClass> lstWrap = new List<WrapperClass>();
        List<String> lstMG1s = new List<String>();
        List<Standing_Quote_Opportunity_Product__c> lstSQOptyProds = new StandingQuoteOpportunityProductsSelector().selectSQProductsByOpportunityIds(new Set<Id>{opportunityId});
        Map<String, List<Standing_Quote_Opportunity_Product__c>> materialGrpToSQProds =
            (Map<String, List<Standing_Quote_Opportunity_Product__c>>)UtilsCollection.getMapOfStringToSObjects(lstSQOptyProds, STRING_MG_API_NAME);
        
        for(Apttus__AgreementLineItem__c objAgmtLI : new ApttusAgreementLineItemSelectors().selectByAgreementId(new Set<Id>{agreementId})){
            if(objAgmtLI.Discontinued__c == STRING_YES)
                continue;
            WrapperClass objWrap = new WrapperClass();
            if(objAgmtLI.Line_Type__c == STRING_MG1 && !lstMG1s.contains(objAgmtLI.Material_Group_1__c)){
                List<Standing_Quote_Opportunity_Product__c> lstSQProds = materialGrpToSQProds.get(objAgmtLI.Material_Group_1__c);
                lstMG1s.add(objAgmtLI.Material_Group_1__c);
                objWrap.MaterialGroup = objAgmtLI.Material_Group_1__c;
                objWrap.MaterialGroup_Description = objAgmtLI.Material_Group_1_Description__c;
                if(lstSQProds != null){
                    objWrap.isChecked = true;
                    objWrap.ForecastAmount = lstSQProds[0].Forecast_Amount__c;
                    lstWrapisChecked.add(objWrap);
                }
                else{
                	lstWrap.add(objWrap);
                }
            }      
        }
         lstWrapisChecked.addAll(lstWrap);
        System.debug('lstWrapisChecked is '+lstWrapisChecked);
        System.debug('lstWrap is '+lstWrap);
        return JSON.serialize(lstWrapisChecked);
    }
    
    /**
     * @author Tapas Chakraborty
     * @date   09 Sep 2020
     * @description    DCP-40571 insert all selected material groups by user in standing quote opp product records
     * before update trigger method
     **/   
    @AuraEnabled
    public static String insertMaterialGroupsOnOpp(List<WrapperClass> selectedGroups, Id opportunityId){
        System.debug('The selectedGroups '+selectedGroups);
        
        List<Standing_Quote_Opportunity_Product__c> lstSQOptyProds = new StandingQuoteOpportunityProductsSelector().selectSQProductsByOpportunityIds(new Set<Id>{opportunityId});
        List<Standing_Quote_Opportunity_Product__c> lstSQProdsToUpsert = new List<Standing_Quote_Opportunity_Product__c>();
        List<Standing_Quote_Opportunity_Product__c> lstSQProdsToDelete = new List<Standing_Quote_Opportunity_Product__c>();        
        
        Map<String, Standing_Quote_Opportunity_Product__c> materialGrpToSQProds = new Map<String, Standing_Quote_Opportunity_Product__c>();
        Map<Id,Standing_Quote_Opportunity_Product__c> idToSQProds = new Map<Id,Standing_Quote_Opportunity_Product__c>();
        
        for(Standing_Quote_Opportunity_Product__c objSQProd : lstSQOptyProds){
            if(objSQProd.Line_Type__c == STRING_MG){
                materialGrpToSQProds.put(objSQProd.Material_Group__c, objSQProd);
                idToSQProds.put(objSQProd.Id, objSQProd);
            }
        }
        
        for(WrapperClass objWrap : selectedGroups){
            Standing_Quote_Opportunity_Product__c objSQProd  = materialGrpToSQProds.get(objWrap.MaterialGroup);            
            
            if(objWrap.isChecked){
                if(objSQProd != null){
                    idToSQProds.remove(objSQProd.Id);
                    if(objSQProd.Forecast_Amount__c != objWrap.ForecastAmount){
                        objSQProd.Forecast_Amount__c = objWrap.ForecastAmount;
                        lstSQProdsToUpsert.add(objSQProd);
                    }
                }
                else{
                    objSQProd = new Standing_Quote_Opportunity_Product__c(); 
                    objSQProd.Forecast_Amount__c = objWrap.ForecastAmount;
                    objSQProd.Material_Group__c = objWrap.MaterialGroup;
                    objSQProd.Opportunity__c = opportunityId;
                    objSQProd.Material_Group_Description__c = objWrap.MaterialGroup_Description;
                    lstSQProdsToUpsert.add(objSQProd);
                }
            }
            
        }
        lstSQProdsToDelete.addAll(idToSQProds.values());
        
        if(!lstSQProdsToUpsert.isEmpty())
            Upsert lstSQProdsToUpsert;
        if(!lstSQProdsToDelete.isEmpty())
            Delete lstSQProdsToDelete;
        return RETURN_MSG_SUCCESS;
    }
    
    /**
     * @author Tapas Chakraborty
     * @date   09 Sep 2020
     * @description    DCP-40571 wrapper class for holding the  material groups fetched from agreements
     * before update trigger method
     **/   
    public class WrapperClass
    {
        @AuraEnabled public boolean isChecked{get; set;}   
        @AuraEnabled public String MaterialGroup{get; set;}   
        @AuraEnabled public Decimal ForecastAmount{get; set;}   
        @AuraEnabled public String MaterialGroup_Description{get; set;}   
        /*
        * @Author:  Tapas Chakraborty
        * @Description : constructor of class WrapperClass 
        * @param :null
        */
        public WrapperClass(){
            isChecked = false;
        }
    }
    
}