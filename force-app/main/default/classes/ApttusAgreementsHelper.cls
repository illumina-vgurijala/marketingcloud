/**
 *    @author Bharath Varma
 *    @date   29-Jun-2021
 *    @description :   Agreement Helper class to maintain common methods used for both Agreement and Agreement Line Items
*    Test Class 90% Coverage : TestApttusAgreements
 *   Test Class 75% Coverage :TestAgrLinesFindDuplicatesController , TestOpenOfferAgreements.
 *    Modification Log:
 *   ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 *       Developer                        Date               Description
 *     Bharath Varma                   29-Jun-2021          Initial Version
 *     Bharath Varma                   07-Apr-2022          Removed future method as it was replaced by a Queueable (AutoUpdateFieldsOnAgreementQueueable.cls)  
 *     Saddam                          25-Aug-2022          Modified getMapIdToAgreement() and updateAgrFromLineItems() and created 2 new methods setAgreementValuesForRegularAgreements(),setAgreementValuesForOpenOfferAgreements() methods.
 *     Saddam                          25-Aug-2022          Modified  updateAgrFromLineItems Created 2 new methods to set agreement Open offer customer election and Openoffer Product type value and line type mapping.
 *     Ashwin                          25-Jan-2023          INC0449613 - Correct field used in conditions.
 *    ------------------------------------------------------------------------------------------------------------------------------------
 */
public with sharing class ApttusAgreementsHelper {

    private static final String UC_MATERIAL = 'UC - Material';
    private static Map<Id, RecordTypeInfo> rtMap;
    private static Set<string> setOfOpenOfferStatus = new Set<string>{'Election Template','Signatures','In Effect','Amended','Cancelled'};
    private static final String STRCOLON = ' : ';
    private static final String STRCOMMA = ',';
    public static Boolean boolIsAgreementLineDeleted = false;


    /*
    @Author : Bharath Varma
    @Story : DCP-47006
    @Description : Method to get record type map.
    @Test Class : TestApttusAgreements.testUCMaterialRollUp
    */
    public static Map<Id, RecordTypeInfo> getRecordTypeMap()
    {
        if (rtMap == null) { rtMap = Apttus__APTS_Agreement__c.sObjectType.getDescribe().getRecordTypeInfosById(); }
        return rtMap;
    }
  
    
    /*
    @Author : Bharath Varma
    @Story : DCP-47006
    @Description : Method to get Id to Agreement Map.
    @Parameters : List of Agreements
    @Test Class : TestApttusAgreements.testUCMaterialRollUp
    @Modified  : Added a condition to check Open Offer agreement. DCP-54810 
    @MODIFIED AUTHOR : SADDAM 
    */
    public static Map<Id, Apttus__APTS_Agreement__c> getMapIdToAgreement(List<Apttus__APTS_Agreement__c> lstAgreements) {
        String rtName;
        Map<Id, RecordTypeInfo> idToRecordTypeInfo = getRecordTypeMap();
        Map<Id, Apttus__APTS_Agreement__c> mapIdToAgreement = new Map<Id, Apttus__APTS_Agreement__c>();

        for(Apttus__APTS_Agreement__c agr: lstAgreements) {
            if (agr.RecordTypeId != null) {
                rtName = idToRecordTypeInfo.get(agr.RecordTypeId).getDeveloperName(); 
            }
            if(rtName == Label.AgreementRecordTypeChannelPartner) {
                agr.ALIs_with_UC_Material_Group__c = 0;
                agr.ALIs_with_UC_Material_Discount__c = 0;
                agr.ALIs_with_UC_Material_Discount_Amount__c = 0;
                agr.ALIs_with_UC_Material_Fixed_Price__c = 0;
                mapIdToAgreement.put(agr.Id, agr);
            }
            else if(AutoUpdateFieldsOnAgreementQueueable.boolIsOpenOfferAgreement == true && rtName == Label.AgreementRecordTypeOpenOffer) {
                mapIdToAgreement.put(agr.Id, agr);
            }
        }
        ilib_LogEvent.info('mapIdToAgreement: '+mapIdToAgreement);
        return mapIdToAgreement;
    }

    /*
    @Author : Bharath Varma
    @Story : DCP-47006
    @Description : Method to Update the fields on Agreement based on the type of line items
    @Parameters : List of Agreements, Map Id to Agreement
    @Test Class : TestApttusAgreements.testUCMaterialRollUp
    @Modfied method and split the code to to 2 new methods to  check  Open offer agreements.
    @MODIFIED AUTHOR : SADDAM 
    */
    public static List<Apttus__APTS_Agreement__c> updateAgrFromLineItems(List<Apttus__AgreementLineItem__c> lstAgreementLineItems, Map<Id, Apttus__APTS_Agreement__c> mapIdToAgreement) {
      
        List<Apttus__APTS_Agreement__c> lstUpdatedAgts = new List<Apttus__APTS_Agreement__c>();
        Set<Id> setUpdatedAgreementIds = new Set<Id>();
        Map<Id, RecordTypeInfo> idToRecordTypeInfo = getRecordTypeMap();
        Map<Id,Set<String>> mapOfAgrIdToOpenOfferElectionToProductTypeAndLineStatusAndLineType =  new Map<Id,Set<String>>();    //DCP-56505
        Map<Id,Set<String>> mapOfAgrIdToOpenOfferProductTypeToLineTypeAndLineStatus =  new Map<Id,Set<String>>();    //DCP-56505

        for(Apttus__AgreementLineItem__c agrLI : lstAgreementLineItems) {
            Boolean erpAndSalesOrg = mapIdToAgreement.containsKey(agrLI.Apttus__AgreementId__c) && mapIdToAgreement.get(agrLI.Apttus__AgreementId__c).Account_ERP_Number__c == agrLI.Customer_ERP_Number__c && mapIdToAgreement.get(agrLI.Apttus__AgreementId__c).Sales_Org__c == agrLI.Sales_Org__c;
            Boolean currencyCheck = mapIdToAgreement.containsKey(agrLI.Apttus__AgreementId__c) && agrLI.CurrencyIsoCode == mapIdToAgreement.get(agrLI.Apttus__AgreementId__c).CurrencyIsoCode;
           
            if(!mapIdToAgreement.containsKey(agrLI.Apttus__AgreementId__c)) {continue;}
            Boolean boolIsOpenOffer =  idToRecordTypeInfo.get(mapIdToAgreement.get(agrLI.Apttus__AgreementId__c).RecordTypeId).getDeveloperName() == System.label.AgreementRecordTypeOpenOffer;
            
            if(boolIsOpenOffer) {
                setAgreementValuesForOpenOfferAgreements(agrLI,mapIdToAgreement,mapOfAgrIdToOpenOfferElectionToProductTypeAndLineStatusAndLineType,mapOfAgrIdToOpenOfferProductTypeToLineTypeAndLineStatus);
            } else {
                setAgreementValuesForRegularAgreements(erpAndSalesOrg,currencyCheck,agrLI,mapIdToAgreement);
            }


            if(mapIdToAgreement.containsKey(agrLI.Apttus__AgreementId__c) && !setUpdatedAgreementIds.contains(agrLI.Apttus__AgreementId__c)) {
                lstUpdatedAgts.add(mapIdToAgreement.get(agrLI.Apttus__AgreementId__c));
                setUpdatedAgreementIds.add(agrLI.Apttus__AgreementId__c);
            }
        }
        return lstUpdatedAgts;  

    }    
    /*
    @Author : saddam
    @Story : DCP-54532
    @Description : Method to Update the fields on Open offer status of OO Agreement based on the type of line status fo agrmnt line items.
    @Parameters : Agreement record and Map of agreement id to agreement record.
    @Test Class : tESToPENoFFERAGREEMENTS
    @Modified : DCP-54532
    */
    public static void  setAgreementValuesForOpenOfferAgreements(Apttus__AgreementLineItem__c agrLI,Map<Id, Apttus__APTS_Agreement__c> mapIdToAgreement,Map<Id,Set<String>> mapOfAgrIdToOpenOfferElectionToProductTypeAndLineStatusAndLineType,Map<Id,Set<String>> mapOfAgrIdToOpenOfferProductTypeToLineTypeAndLineStatus) {

        Boolean boolLineStatusCriteriaSatisfied   = agrLI.Apttus_CMConfig__LineStatus__c == System.label.AgreementLineItemLineStatusNew || agrLI.Apttus_CMConfig__LineStatus__c == System.label.AgreementLineItemLineStatusUpdated;

        if(boolLineStatusCriteriaSatisfied && !setOfOpenOfferStatus.contains(mapIdToAgreement.get(agrLI.Apttus__AgreementId__c).Open_Offer_Status__c) && !boolIsAgreementLineDeleted) { 
            mapIdToAgreement.get(agrLI.Apttus__AgreementId__c).Open_Offer_Status__c = System.label.AgreementOpenOfferStatusElectionTemplate;
        }
         
        setAgreementOpenOfferCustomerElectionToProductTypeAndLineStatusAndLineType(agrLI, mapOfAgrIdToOpenOfferElectionToProductTypeAndLineStatusAndLineType);

        setAgreementOpenOfferLineTypeToProductTypeAndLineStatus(agrLI, mapOfAgrIdToOpenOfferProductTypeToLineTypeAndLineStatus);
        
        if(mapIdToAgreement.containskey(agrLI.Apttus__AgreementId__c) && mapOfAgrIdToOpenOfferElectionToProductTypeAndLineStatusAndLineType.containsKey(agrLI.Apttus__AgreementId__c)) {
            mapIdToAgreement.get(agrLI.Apttus__AgreementId__c).Open_Offer_Election_And_Product_Type__c = String.join(new List<String>(mapOfAgrIdToOpenOfferElectionToProductTypeAndLineStatusAndLineType.get(agrLI.Apttus__AgreementId__c)), ';');
        }

        if(mapIdToAgreement.containskey(agrLI.Apttus__AgreementId__c) && mapOfAgrIdToOpenOfferProductTypeToLineTypeAndLineStatus.containsKey(agrLI.Apttus__AgreementId__c)) {
            mapIdToAgreement.get(agrLI.Apttus__AgreementId__c).Open_Offer_Product_and_Line_Type__c = String.join(new List<String>(mapOfAgrIdToOpenOfferProductTypeToLineTypeAndLineStatus.get(agrLI.Apttus__AgreementId__c)), ';');
        }
    }

     /*
    @Author : saddam
    @Story : DCP-56505
    @Description : Method to Update Open offer Customer Election.
    @Parameters : Agreement record and Map of agreement id to Set of string.
    @Test Class : 
    */
    public static void setAgreementOpenOfferCustomerElectionToProductTypeAndLineStatusAndLineType(Apttus__AgreementLineItem__c agrLI,Map<Id,Set<String>> mapOfAgrIdToOpenOfferElectionToProductTypeAndLineStatusAndLineType) {
        
        Set<String> setStringCustomerElectionAndProductTypeAndLineStatusAndLineType = new Set<String>();
        if(mapOfAgrIdToOpenOfferElectionToProductTypeAndLineStatusAndLineType.containskey(agrLI.Apttus__AgreementId__c) ) {
            mapOfAgrIdToOpenOfferElectionToProductTypeAndLineStatusAndLineType.get(agrLI.Apttus__AgreementId__c).add(agrLI.Customer_Election__c+STRCOLON+agrLI.Apttus__ProductId__r.Material_Class__c+STRCOMMA+agrLI.Apttus_CMConfig__LineStatus__c+STRCOMMA+agrLI.Open_Offer_Line_Type__c);
        } else if(!mapOfAgrIdToOpenOfferElectionToProductTypeAndLineStatusAndLineType.containskey(agrLI.Apttus__AgreementId__c)) {
            setStringCustomerElectionAndProductTypeAndLineStatusAndLineType.add(agrLI.Customer_Election__c+STRCOLON+agrLI.Apttus__ProductId__r.Material_Class__c+STRCOMMA+agrLI.Apttus_CMConfig__LineStatus__c+STRCOMMA+agrLI.Open_Offer_Line_Type__c);
            mapOfAgrIdToOpenOfferElectionToProductTypeAndLineStatusAndLineType.put(agrLI.Apttus__AgreementId__c,setStringCustomerElectionAndProductTypeAndLineStatusAndLineType);
        }
    }
     /*
    @Author : saddam
    @Story : DCP-56505
    @Description : Method to Update Open offer Customer Election.
    @Parameters : Agreement record and Map of agreement id to Set of string.
    @Test Class : 
    */
    public static void setAgreementOpenOfferLineTypeToProductTypeAndLineStatus(Apttus__AgreementLineItem__c agrLI,Map<Id,Set<String>> mapOfAgrIdToOpenOfferProductTypeToLineTypeAndLineStatus) {
        
        Set<String> setStringProductTypeToLineTypeAndLineStatus = new Set<String>();
        if(mapOfAgrIdToOpenOfferProductTypeToLineTypeAndLineStatus.containskey(agrLI.Apttus__AgreementId__c) ) {
            mapOfAgrIdToOpenOfferProductTypeToLineTypeAndLineStatus.get(agrLI.Apttus__AgreementId__c).add(agrLI.Apttus__ProductId__r.Material_Class__c+STRCOLON+agrLI.Open_Offer_Line_Type__c+STRCOMMA+agrLI.Apttus_CMConfig__LineStatus__c);
        } else if(!mapOfAgrIdToOpenOfferProductTypeToLineTypeAndLineStatus.containskey(agrLI.Apttus__AgreementId__c)) {
            setStringProductTypeToLineTypeAndLineStatus.add(agrLI.Apttus__ProductId__r.Material_Class__c+STRCOLON+agrLI.Open_Offer_Line_Type__c+STRCOMMA+agrLI.Apttus_CMConfig__LineStatus__c);
            mapOfAgrIdToOpenOfferProductTypeToLineTypeAndLineStatus.put(agrLI.Apttus__AgreementId__c,setStringProductTypeToLineTypeAndLineStatus);
        }
    }

    /*
    *  @author       : Saddam
    *  @description  : Set value of bool
    *  @param        : Boolean boolValue
    *  @return       : void
    */
    public static void setFlagForAgreementlineDeletion(Boolean boolValue) {
        boolIsAgreementLineDeleted = boolValue;
    } 

    /*
    *  @author       : Saddam
    *  @description  : get value of boolean
    *  @param        : null
    *  @return       : Boolean
    */
    public static Boolean isFlagForAgreementlineDeletionTrue() {
        return boolIsAgreementLineDeleted;
    }

    /*
    @Author : saddam
    @Story : DCP-54810
    @Description : Method to Update the fields on Non Open offer Agreement.
    @Parameters : Agreement record and Map of agreement id to agreement record,Boolean ,Agreement record.
    @Test Class : 
    */
    public static void  setAgreementValuesForRegularAgreements(Boolean erpAndSalesOrg,Boolean currencyCheck, Apttus__AgreementLineItem__c agrLI, Map<Id, Apttus__APTS_Agreement__c> mapIdToAgreement) {
           
        if(erpAndSalesOrg &&  agrLI.Line_Type__c == 'UC - Material Group 1') {
            mapIdToAgreement.get(agrLI.Apttus__AgreementId__c).ALIs_with_UC_Material_Group__c += 1;
        } else if(erpAndSalesOrg &&  agrLI.Line_Type__c == UC_MATERIAL && agrLI.Discount_Type__c == '% Discount') {                         //INC0449613
            mapIdToAgreement.get(agrLI.Apttus__AgreementId__c).ALIs_with_UC_Material_Discount__c += 1;
        } else if(erpAndSalesOrg &&  agrLI.Line_Type__c == UC_MATERIAL && agrLI.Discount_Type__c == 'Discount Amount' && currencyCheck) {   //INC0449613
            mapIdToAgreement.get(agrLI.Apttus__AgreementId__c).ALIs_with_UC_Material_Discount_Amount__c += 1;
        } else if(erpAndSalesOrg &&  agrLI.Line_Type__c == UC_MATERIAL &&  agrLI.Discount_Type__c == 'Fixed Amount' && currencyCheck) {     //INC0449613
            mapIdToAgreement.get(agrLI.Apttus__AgreementId__c).ALIs_with_UC_Material_Fixed_Price__c += 1;
        }  
    }

}