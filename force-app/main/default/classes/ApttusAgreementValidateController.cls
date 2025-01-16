/**
 *   @author Kushagra Desai
 *   @date  10-Dec-2019
 *   @description   Controller class for Validate agreement interface
 *   Test class for 90% coverage: TestApttusAgreementValidateController, TestAgreementOutputParametersForm, TestApttusAgreements, TestBatchAutoTerminateAgreements,TestOpenOfferagreements
 *   Test class for 75% coverage: TestApttusAgreementValidateController 
 *   Modification Log:
 *   ---------------------------------------------------------------------------------------------------------------------------------
 *      Developer              Date              Description
 *      Kushagra Desai         27-Jan-2020       Activate Agreement support
 *      Kushagra Desai         04-Feb-2020       Added support for Cancel
 *      Kushagra Desai         04-Feb-2020       Added support for Terminate
 *      Kushagra Desai         19-Feb-2020       Start and end date update logic
 *      Kushagra Desai         24-Feb-2020       Start and end date update logic for Activate
 *      Kushagra Desai         26-Feb-2020       Start and end date update logic for Terminate
 *      Vishnu Kurra           02-Mar-2020       Added support for PreValidate
 *      Kushagra Desai         08-Apr-2020       Add Discountinued field on JSON
 *      Todd Newman            05-Aug-2020       INC0277130 - JPY and KRW currencies should not have units smaller than 1
 *      Rishab Wali            10-Nov-2020       Added Logic for DCP-34579 - Updating termination date field.
 *      Anish                  12-Dec-2020       Added logic for DCP-43353
 *      Rahul Bishnoi          13-May-2021       INC0320773 - fetching parent agreement number from new field created on amended agreement.
 *      Nesar Mohan            01-Apr-2022       Codescan Fix
 *      Mohd Juned             04-Aug-2022       TASK0793030 - added the logic so same start date send on pre-validate and validate
 *      Saddam/Himanshu        02-Sep-2022       DCP-54536 ,Created Agreement account contact relationship wrapper and Modifed agrmnt line item wrapper and modified createjson method for Open offer agrts.
 *      Maruthi                09-Sep-2022       DCP-56218 updated sendValidationRequest, sendPreValidationRequest, sendCancelRequest, sendActivateRequest, sendTerminateRequest, sendActionRequest and created updateAgreementBeforeValidate
 *      Rishi Sharma           19-Sept-2022      DCP-56529 - Agreements getting stuck with "Terminate In progress"
 *      Aman Tyagi             21-Sep-2022       created checkIfRelatedAgreementPresent() ,agreementSetCustomerStatus(),AgreementAccountRelationshipIncludeWrapper() , AgreementAccountRelationshipExcludeWrapper() , updated createJSON() as per DCP-56506      
 *      Vivek R                22-Sep-2022       DCP-56507 - modified the condtion for sending the start date and end date in generateTerminateStartDate(), generateTerminateEndDate() methods
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class ApttusAgreementValidateController {

    public static long datenow = Datetime.now().getTime();
    public static final String ERROR = 'Error-';
    public static final String REPLACEZERO = '{0}';
    public static final String BLANKSTR = '#@#@';
    public static final Set<String> SET_AGREEMENT_STAGE = new Set<String>{Label.AgreementActionValidate, Label.AgreementActionActivate, Label.AgreementActionPreValidate};  //TASK0793030
    public static final String ERROROPENOFFER = 'ErrorOpenOffer'; //DCP-54536
    public static final String DATESTR = '/Date('; //DCP-54536 Codescan Fix 
	private static final String LOG_TITLE = 'ApttusAgreementValidateController';
     
    /*
    *  @author      : Kushagra Desai
    *  @description : wrapper class for Agreement
    */

    public class AgreementWrapper {
        public String AgreementNum;
        public String Action;
        public String AgreeStartDate;
        public String AgreeEndDate;
        public List<AgreementLineWrapper> im_itemSet = new List<AgreementLineWrapper>();
        public List<Object> EX_ReturnSet = new List<Object>();
        //Added as part of Story DCP-34995
        public String AgreementId;
        public String ActionDate;
        public String ParentAgreeNum;
        //DCP-54536
        public String AgreementType;
        public String AgreementSubType;
        public List<AgreementAccountRelationshipIncludeWrapper> im_customer_includeSet = new List<AgreementAccountRelationshipIncludeWrapper>();
        public List<AgreementAccountRelationshipExcludeWrapper> im_customer_excludeSet = new List<AgreementAccountRelationshipExcludeWrapper>();
        /*
        *  @author      : Kushagra Desai
        *  @description : Constructor for wrapper class for Agreement
        *  @param       : String, Apttus__APTS_Agreement__c
        */

        public AgreementWrapper(String action, Apttus__APTS_Agreement__c agg)
        {
            this.AgreementNum = agg.Apttus__FF_Agreement_Number__c;
            this.Action = action.toUpperCase();
            this.AgreeStartDate = ApttusAgreementValidateController.generateSAPDate('Apttus__Contract_Start_Date__c', 'Apttus__APTS_Agreement__c', agg);
            this.AgreeEndDate = ApttusAgreementValidateController.generateSAPDate('Apttus__Contract_End_Date__c', 'Apttus__APTS_Agreement__c', agg);
            //Added as part of Story DCP-34995
            this.AgreementId = agg.id;
            this.ActionDate = ApttusAgreementValidateController.generateActionSAPDate(Date.today());
            //DCP-54536
            this.AgreementType = agg.recordType.Name;
            this.AgreementSubType = agg.Apttus__Subtype__c;
        }

        /*
        *  @author      : Kushagra Desai
        *  @description : Method - Set Parent Number
        *  INC0320773 - fetching parent agreement number from new field created on amended agreement.
        *  @param       : Apttus__APTS_Agreement__c
        *  @return      : void
        */

        public void setParentNumber(Apttus__APTS_Agreement__c agreement)
        {
            if (!agreement.Agreement_Not_Amended__c)
            {
                this.ParentAgreeNum = String.valueOf(agreement.Parent_Agreement_Number__c);
            }
            else
            {
                this.ParentAgreeNum = '';
            }
        }
    }

    /*
    *  @author      : Kushagra Desai
    *  @description : wrapper class for Agreement line
    *  @param       : NA
    *  @return      : NA
    */

    public class AgreementLineWrapper {
        public String Customer;
        public String Curr;
        public String SalesOrg;
        public String DistChnl;
        public String PriceGroup;
        public String UltCons;
        public String CondType;
        public String CondTable;
        public String Material;
        public String MaterialGroup;
        public String Lob;
        public String ProdCategory;
        public String ProdLine;
        public String ProdGroup;
        public String PartnerRole;
        public String Rate;
        public String RateUnit;
        public String StartDate;
        public String EndDate;
        public String LineItemId;
        //Added as part of Story DCP-34995
        public String LineStatus;
        //Added Discontinued field
        public String SfdcDisFlag;
        public String Cstcndgrp4;//DCP-43353
        public String Cstcndgrp5;//CMCM-5305
        //DCP-54536
        public string CustomerElection;//dcp-54536
        public string OldCustomerElection;//dcp-54536
        public Boolean isFixedPrice;//dcp-54536
        
        /*
        *  @author      : Kushagra Desai
        *  @description : Paramterised constructor
        *  @param       : String, Apttus__AgreementLineItem__c, String, Integer
        */

        public AgreementLineWrapper(String action, Apttus__AgreementLineItem__c agrline, String currencyCode, Integer ratePrecision)
        {
            Boolean boolAgrmntLineItemIsOpenOffer = agrLine.RecordType.DeveloperName == Label.AgreementLineItemRecordTypeDevNameOpenOffer ;
            this.Lob = '';
            this.ProdCategory = '';
            this.ProdLine = '';
            this.ProdGroup = '';
            this.CondType = boolAgrmntLineItemIsOpenOffer ? '' : agrline.Condition_Type__c;
            this.CondTable = boolAgrmntLineItemIsOpenOffer ? '' : agrline.Condition_Table__c;
             //DCP-54536
             this.Customer = boolAgrmntLineItemIsOpenOffer ? toStringNoNulls(agrline.Apttus__AgreementId__r.Account_ERP_Number__c) : toStringNoNulls(agrline.Customer_ERP_Number__c);
             this.Curr = boolAgrmntLineItemIsOpenOffer ? toStringNoNulls(agrline.Apttus__AgreementId__r.CurrencyIsoCode) : toStringNoNulls(agrline.CurrencyIsoCode);
             this.SalesOrg = boolAgrmntLineItemIsOpenOffer ? toStringNoNulls(agrline.Apttus__AgreementId__r.Sales_Org__c) : toStringNoNulls(agrline.Sales_Org__c);
             this.DistChnl = boolAgrmntLineItemIsOpenOffer ? toStringNoNulls(agrline.Apttus__AgreementId__r.Distribution_Channel__c) : toStringNoNulls(agrline.Distribution_Channel__c);
             //DCP-54536
            this.PriceGroup = toStringNoNulls(agrline.Price_Group__c);
            this.UltCons = toStringNoNulls(agrline.Ultimate_Consignee_ERP_Number__c);
            this.MaterialGroup = toStringNoNulls(agrline.Material_Group_1__c);
            this.Material = toStringNoNulls(agrline.Apttus__ProductId__r.Material_Number__c);
            this.PartnerRole = toStringNoNulls(agrline.Partner_Role__c);
            // INC0277130 ratePrecision
            this.Rate = boolAgrmntLineItemIsOpenOffer ? toStringNoNulls(generateRateForOpenOffer(agrline)) : toStringNoNulls(agrline.Discount__c);// DCP 54536
            this.RateUnit = 
                (agrline.Customer_Election__c == System.label.CustomElectionPickListQuote && agrline.Quote_Discount_Type__c == System.label.AliDiscountTypePercent) ||
                (agrline.Customer_Election__c == System.label.CustomElectionPickListSupplyAgreement && agrline.Supply_Agreement_Discount_Type__c ==System.label.AliDiscountTypePercent)||
                (agrline.Customer_Election__c == System.label.CustomElectionPickListUniversalGrid && agrline.Universal_Grid_Discount_Type__c == System.label.AliDiscountTypePercent)||
                (agrline.Customer_Election__c == System.label.CustomElectionPickListPSP ) ||
                (agrline.Discount_Type__c == System.label.AliDiscountTypePercent) ? '%' : currencyCode;
            this.StartDate = 
                (action == Label.AgreementActionTerminate)
                ? ApttusAgreementValidateController.generateTerminateStartDate(agrline)
                : SET_AGREEMENT_STAGE.contains(action)                                          //TASK0793030
                    ? ApttusAgreementValidateController.generateStartDate(agrline)
                    : generateActionSAPDate(agrline.Apttus_CMConfig__StartDate__c);
            this.EndDate =
                (action == Label.AgreementActionTerminate)
                ? ApttusAgreementValidateController.generateTerminateEndDate(agrline)
                : SET_AGREEMENT_STAGE.contains(action)                                          //TASK0793030
                    ? ApttusAgreementValidateController.generateEndDate(agrline)
                    : generateActionSAPDate(agrline.Apttus_CMConfig__EndDate__c);
            this.LineItemId = agrline.Name;
            //Added as part of Story DCP-34995
            this.LineStatus = toStringNoNulls(agrline.Apttus_CMConfig__LineStatus__c);
            if (String.isBlank(this.StartDate)) { this.StartDate = generateActionSAPDate(agrline.Apttus_CMConfig__StartDate__c); }
            if (String.isBlank(this.EndDate)) { this.EndDate = generateActionSAPDate(agrline.Apttus_CMConfig__EndDate__c); }
            this.SfdcDisFlag = agrline.Discontinued__c == Label.AgreementLineItemDiscontinuedYes ? 'X' : '';
            this.Cstcndgrp4 = String.isNotBlank(String.valueOf(agrline.Customer_Condition_Group_4__c)) ? String.valueOf(agrline.Customer_Condition_Group_4__c) :'';//DCP-43353
            this.Cstcndgrp5 = agrline.Apttus__AgreementId__r.Freight_Charge__c != null && agrline.Apttus__AgreementId__r.Freight_Charge__c == 'Do Not Charge'
                                ? 'NF' :'';//CMCM-5305
             //DCP-54536
             this.CustomerElection = getValueForElection(agrLine.Customer_Election__c,boolAgrmntLineItemIsOpenOffer);
             this.OldCustomerElection = getValueForElection(agrLine.Previous_Customer_Elections__c, boolAgrmntLineItemIsOpenOffer);
             this.isFixedPrice = (agrLine.Customer_Election__c == System.label.CustomElectionPickListQuote && agrLine.Quote_Discount_Type__c == System.label.AgreementLineitemsDiscountTypeFixedPrice) || 
                                 (agrLine.Customer_Election__c == System.label.CustomElectionPickListSupplyAgreement && agrLine.Supply_Agreement_Discount_Type__c == System.label.AgreementLineitemsDiscountTypeFixedPrice) ? true : false;
 
         }
         /*
         *  @author      : Aman Tyagi
         *  @description : Method to set the value of customer election in wrapper
         *  @param       : String strElectionValue, Boolean boolAgrmntLineItemIsOpenOffer
         *  @return      : String
         */
         private String getValueForElection(String strElectionValue, Boolean boolAgrmntLineItemIsOpenOffer) {
             if(String.isBlank(strElectionValue) || !boolAgrmntLineItemIsOpenOffer) { return  ''; }
             return strElectionValue == System.label.CustomElectionPickListQuote || strElectionValue == System.label.CustomElectionPickListSupplyAgreement ? 'GF' :
             strElectionValue == System.label.CustomElectionPickListUniversalGrid ? 'UG' : strElectionValue == System.label.CustomElectionPickListPSP ? 'PSP' : '';
             
         }

        

        /*
        *  @author      : Kushagra Desai
        *  @description : Method to return string if not blank, empty string if blank
        *  @param       : Object
        *  @return      : String
        */

        private String toStringNoNulls(Object raw)
        {
            return (String.isNotBlank(String.valueOf(raw)))
                ? String.valueOf(raw)
                : '';
        }
    }
    
    /*
    *  @author      : saddam
    *  @description : wrapper class for AccountRelationship include wrapper ,DCP-54536
    *  @param       : NA
    *  @return      : NA
    */

    public class AgreementAccountRelationshipIncludeWrapper {

        public String Customer;
        public String CustomerStatus;

        /*
        *  @author      : saddam
        *  @description : Paramterised constructor
        *  @param       : Agreement_Account_Relationship__c
        */
        public AgreementAccountRelationshipIncludeWrapper(String customerERPNumber, String customerStatus) {
            this.Customer = customerERPNumber;
            this.CustomerStatus =customerStatus;
        }        
    }

    /*
    *  @author      : saddam
    *  @description : wrapper class for AccountRelationship Exclude wrapper ,DCP-54536
    *  @param       : NA
    *  @return      : NA
    */

    public class AgreementAccountRelationshipExcludeWrapper {

        public String Customer;
        /*
        *  @author      : saddam
        *  @description : Paramterised constructor
        *  @param       : Agreement_Account_Relationship__c
        */
        public AgreementAccountRelationshipExcludeWrapper(String customerERPNumber) {
            this.Customer = customerERPNumber;
        }
    }

    /*
    * @author Kushagra Desai
    * @Description Generator method to create request JSON
    * @param Sobject Apttus__APTS_Agreement__c, String
    * @return JSON string
    * Modified Method to For Open Offer agreement Line Items,DCP-54536
    */
    public static string createJSON(Apttus__APTS_Agreement__c agg, String action) {
        
        String strJSON;
        Boolean boolCheckDate = false;
        Boolean boolCheckDateOpenOffer = false;
        Boolean boolAgrmntTypeIsOpenOffer = agg.RecordType.Name == Label.AgreementRecordTypeNameOpenOffer; //dcp-54536
        AgreementWrapper agrWrap = new AgreementWrapper(action, agg);
        //INC0320773 - fetching parent agreement number from new field created on amended agreement.
        agrWrap.setParentNumber(agg);

        // INC0277130 - JPY and KRW currencies should not have units smaller than 1
        Integer ratePrecision = ApttusAgreements.getCurrencyPrecision(agg.CurrencyIsoCode);

        for (Apttus__AgreementLineItem__c agrline : new ApttusAgreementLineItemSelectors().selectAgreementLineItem(new Set<Id>{agg.id})) {
           
            Boolean boolAgrmntLineItemIsOpenOffer = agrLine.RecordType.DeveloperName == Label.AgreementLineItemRecordTypeDevNameOpenOffer ;
            Boolean boolCheckSupplyAgreementStartDate = agrLine.Customer_Election__c == Label.CustomElectionPickListSupplyAgreement && agrLine.Supply_Agreement_Start_Date__c > Date.today();
            Boolean boolCheckNonAmendedAgreementStartDate = agrline.Apttus__AgreementId__r.Agreement_Not_Amended__c && (agrline.Apttus__AgreementId__r.Apttus__Contract_Start_Date__c > Date.today() || agrline.Apttus_CMConfig__StartDate__c > Date.today() || boolCheckSupplyAgreementStartDate);
            Boolean boolCheckOpenOfferAgreementDates = action == System.Label.AgreementActionActivate && boolAgrmntLineItemIsOpenOffer && (boolCheckNonAmendedAgreementStartDate || agrline.Apttus__AgreementId__r.Apttus__Contract_End_Date__c < Date.today() || agrline.Apttus_CMConfig__EndDate__c < Date.today());

            if (agrline.Apttus_CMConfig__EndDate__c < Date.today()
                && agrline.Apttus_CMConfig__StartDate__c < Date.today()
                && agrline.Apttus_CMConfig__LineStatus__c == Label.AgreementLineItemLineStatusNew 
                && (action == Label.AgreementActionValidate || action == Label.AgreementActionActivate)
                && agrline.Discontinued__c == Label.AgreementLineItemDiscontinuedNo
                && !boolAgrmntLineItemIsOpenOffer) {
                    boolCheckDate = true;
                    break;
            } else if(boolCheckOpenOfferAgreementDates) {
                    boolCheckDateOpenOffer = true;
                    break; }
            agreementLineItemWrapperCreator(agrline,boolAgrmntLineItemIsOpenOffer,action,ratePrecision,agrWrap);
        }
        
        populateAffiliateDetailsForAgreement(boolAgrmntTypeIsOpenOffer, agg, agrWrap);
        
        strJSON = JSON.serializePretty(agrWrap);
        System.debug('Pretty JSON-->' + JSON.serializePretty(agrWrap));

        return boolCheckDate ? ERROR : boolCheckDateOpenOffer ? ERROROPENOFFER : strJSON;
    }

    /*
    * @author Aman Tyagi
    * @Description  populate the JSON for affiliates in agreement
    * @param  Boolean boolIsRelatedAgreementPresent ,Agreement_Account_Relationship__c objAgreementAccountRelationship, Set<String> setCustomerERPIds
    * @return  AgreementAccountRelationshipIncludeWrapper
    */
    public static void populateAffiliateDetailsForAgreement(Boolean boolAgreementTypeIsOpenOffer,Apttus__APTS_Agreement__c objAgreement, AgreementWrapper objAgreementWrapper) {
        if(boolAgreementTypeIsOpenOffer) {
            //DCP-56506             
            Map<String, Boolean> mapCustomerERPToOptInValue = new Map<String, Boolean>();
            boolean boolIsRelatedAgreementPresent =  checkIfRelatedAgreementPresent(objAgreement,mapCustomerERPToOptInValue);
            for(Agreement_Account_Relationship__c objAgreementAccountRelationship : new AgreementAccountRelationshipSelectors().selectByAgreementId(new Set<Id>{objAgreement.Id})) {
                 //DCP-58324 : Changed set to map as parameter in setAgreementAccountRelationInclusionWrapper
                if(objAgreementAccountRelationship.Opt_In_Receiving_Open_Offer_Discount__c) {
                    AgreementAccountRelationshipIncludeWrapper objAARInclusionWrapper = setAgreementAccountRelationInclusionWrapper(boolIsRelatedAgreementPresent,objAgreementAccountRelationship,mapCustomerERPToOptInValue);
                    objAgreementWrapper.im_customer_includeSet.add(objAARInclusionWrapper);
                } else if(objAgreementAccountRelationship.Opt_In_Receiving_Open_Offer_Discount__c == false && objAgreement.Parent_Agreement_Number__c != null && checkIfExclusionCriteriaSatisfiedForAAR(boolIsRelatedAgreementPresent, objAgreementAccountRelationship, mapCustomerERPToOptInValue)) {
                    AgreementAccountRelationshipExcludeWrapper objAARExclusionWrapper = setAgreementAccountRelationExclusionWrapper(boolIsRelatedAgreementPresent,objAgreementAccountRelationship,mapCustomerERPToOptInValue.keySet());
                    objAgreementWrapper.im_customer_excludeSet.add(objAARExclusionWrapper);
                }
            }
        }
    }

    /*
    * @author Aman Tyagi
    * @Description  to return AgreementAccountRelationshipIncludeWrapper 
    * @param  Boolean boolIsRelatedAgreementPresent ,Agreement_Account_Relationship__c objAgreementAccountRelationship, Set<String> setCustomerERPIds
    * @return  AgreementAccountRelationshipIncludeWrapper
    */
    public static AgreementAccountRelationshipIncludeWrapper setAgreementAccountRelationInclusionWrapper(Boolean boolIsRelatedAgreementPresent ,Agreement_Account_Relationship__c objAgreementAccountRelationship, Map<String, Boolean> mapCustomerERPToOptInValue) {
        AgreementAccountRelationshipIncludeWrapper objAARInclusionWrapper = null;
        if(boolIsRelatedAgreementPresent && !mapCustomerERPToOptInValue.isEmpty()) {
            if(mapCustomerERPToOptInValue.containsKey(objAgreementAccountRelationship.Customer_ERP_Number__c) && mapCustomerERPToOptInValue.get(objAgreementAccountRelationship.Customer_ERP_Number__c)==true ) {
                objAARInclusionWrapper = new AgreementAccountRelationshipIncludeWrapper(objAgreementAccountRelationship.Customer_ERP_Number__c,Label.AgreementLineItemLineStatusExisting); 
            } else {
                objAARInclusionWrapper = new AgreementAccountRelationshipIncludeWrapper(objAgreementAccountRelationship.Customer_ERP_Number__c,Label.AgreementLineItemLineStatusNew);
            }
        } else {
            objAARInclusionWrapper = new AgreementAccountRelationshipIncludeWrapper(objAgreementAccountRelationship.Customer_ERP_Number__c,Label.AgreementLineItemLineStatusNew);
        }
        return objAARInclusionWrapper;
    }

    /*
    * @author Aman Tyagi
    * @Description  to return AgreementAccountRelationshipExcludeWrapper
    * @param  Boolean boolIsRelatedAgreementPresent ,Agreement_Account_Relationship__c objAgreementAccountRelationship, Map<String, Boolean> mapCustomerERPToOptInValue
    * @return  AgreementAccountRelationshipExcludeWrapper
    */
    public static AgreementAccountRelationshipExcludeWrapper setAgreementAccountRelationExclusionWrapper(Boolean boolIsRelatedAgreementPresent ,Agreement_Account_Relationship__c objAgreementAccountRelationship, Set<String> setCustomerERPIds) {
        AgreementAccountRelationshipExcludeWrapper objAARExclusionWrapper = null;
        if(boolIsRelatedAgreementPresent && !setCustomerERPIds.isEmpty()) {
            objAARExclusionWrapper =  new AgreementAccountRelationshipExcludeWrapper(objAgreementAccountRelationship.Customer_ERP_Number__c);
        }
        return objAARExclusionWrapper;
    }

    /*
    * @author Aman Tyagi
    * @Description  to check if previous AAR was included but now excluded for Open Offer
    * @param  Boolean boolIsRelatedAgreementPresent ,Agreement_Account_Relationship__c objAgreementAccountRelationship, Map<String, Boolean> mapCustomerERPToOptInValue
    * @return  Boolean
    */
    public static Boolean checkIfExclusionCriteriaSatisfiedForAAR(Boolean boolIsRelatedAgreementPresent,Agreement_Account_Relationship__c objAgreementAccountRelationship, Map<String, Boolean> mapCustomerERPToOptInValue) {
        return boolIsRelatedAgreementPresent && mapCustomerERPToOptInValue.containsKey(objAgreementAccountRelationship.Customer_ERP_Number__c) && mapCustomerERPToOptInValue.get(objAgreementAccountRelationship.Customer_ERP_Number__c) == true;
    }

    /*
    * @author Aman Tyagi
    * @Description  method to return if agreement has related agreement as per DCP-56506
    * @param  Apttus__APTS_Agreement__c objAgreement,List<Apttus__APTS_Related_Agreement__c> relatedAgg,Map<String, Boolean> mapCustomerERPToOptInValue
    * @return  boolean
    */
    public static boolean checkIfRelatedAgreementPresent(Apttus__APTS_Agreement__c objAgreement,Map<String, Boolean> mapCustomerERPToOptInValue) {
        boolean boolRelatedAgreementPresent = false;
        if(objAgreement.Parent_Agreement_Number__c != null) {
            List<Apttus__APTS_Related_Agreement__c> lstRelatedAgreement = new ApttusRelatedAgreementSelectors().getRelatedAgreementTo(objAgreement.Id);
            boolRelatedAgreementPresent = true;
            Set<Id> setRelatedAgreementIds = new Set<Id>{lstRelatedAgreement[0].Apttus__APTS_Contract_From__c}; 
            populateCustomerERPMapForAgreementAccountRelationships(setRelatedAgreementIds,mapCustomerERPToOptInValue);
        }
        return boolRelatedAgreementPresent;       
    }

    /*
    * @author Aman Tyagi
    * @Description  method to add the customer ERP number of related agreement as per DCP-56506
    * @param  Set<Id> setRelatedAgreementIds, Map<String, Boolean> mapCustomerERPToOptInValue
    * @return  void
    */
    public static void populateCustomerERPMapForAgreementAccountRelationships(Set<Id> setRelatedAgreementIds,Map<String, Boolean> mapCustomerERPToOptInValue) {           
        for(Agreement_Account_Relationship__c objAgreementAccountRelationship : new AgreementAccountRelationshipSelectors().selectByAgreementId(setRelatedAgreementIds)) {
            mapCustomerERPToOptInValue.put(objAgreementAccountRelationship.Customer_ERP_Number__c, objAgreementAccountRelationship.Opt_In_Receiving_Open_Offer_Discount__c);
        }          
    }

    /*
    * @author saddam
    * @Description : method to create a wrapper for agr line items. 
    * @param Sobject Apttus__AgreementLineItem__c, boolean, string,Integer,AgreementWrapper 
    */
    public static void agreementLineItemWrapperCreator(Apttus__AgreementLineItem__c objAgrLineItem,Boolean boolAgrmntLineItemIsOpenOffer,String action,Integer ratePrecision,AgreementWrapper agrWrap) {
        
        Boolean boolExcludeLineItemPSP = boolAgrmntLineItemIsOpenOffer && objAgrLineItem.Open_Offer_Line_Type__c != System.label.OpenOfferLineTypePSP;
        Boolean boolCheckAgreementLineEndDate = objAgrLineItem.Apttus_CMConfig__EndDate__c >= Date.today();
        Boolean boolMsaExcludeAgreementLineItem = boolAgrmntLineItemIsOpenOffer && (objAgrLineItem.Supply_Agreement_End_Date__c == null || objAgrLineItem.Supply_Agreement_End_Date__c < Date.today()) && objAgrLineItem.Customer_Election__c == Label.CustomElectionPickListSupplyAgreement;
        Boolean boolIncludeLineItemForOpenOfferActivation = boolExcludeLineItemPSP && !boolMsaExcludeAgreementLineItem && boolCheckAgreementLineEndDate;
        Boolean boolIncludeLineItemForNonOpenOffer = !boolAgrmntLineItemIsOpenOffer && objAgrLineItem.Line_Type__c != Label.AgreementLineTypeQuotas;
        Boolean boolIncludeLineItemForOpenOffer = (boolIncludeLineItemForOpenOfferActivation && action == System.Label.AgreementActionActivate) || (boolExcludeLineItemPSP && action != System.Label.AgreementActionActivate);

        if(boolIncludeLineItemForNonOpenOffer || boolIncludeLineItemForOpenOffer) {  
            AgreementLineWrapper linewrap = new AgreementLineWrapper(action, objAgrLineItem, objAgrLineItem.CurrencyIsoCode, ratePrecision);
            agrWrap.im_itemSet.add(linewrap);
        }
    }

    /*
    * @author Kushagra Desai
    * @Description Router method to call spefic action as per argument
    * @param Sobject Apttus__APTS_Agreement__c ,String Action
    * @return  string
    */ 
    @AuraEnabled
    public static string sendActionRequest(String strAgreementId, String action, String priorValidationStatus)
    {
        if (action == Label.AgreementActionValidate){
            return sendValidationRequest(strAgreementId, action, priorValidationStatus);}
        if (action == Label.AgreementActionPreValidate){
            return sendPreValidationRequest(strAgreementId, action);}
        if (action == Label.AgreementActionActivate){
            return sendActivateRequest(strAgreementId, action, priorValidationStatus);}
        if (action == Label.AgreementActionCancel){
            return sendCancelRequest(strAgreementId, action, priorValidationStatus);}
        if (action == Label.AgreementActionTerminate){
            return sendTerminateRequest(strAgreementId, action, priorValidationStatus);}        
        else {
            return null; }
    }

    /*
    * @author Maruthi
    * @Description: Update validation status to inprogress DCP-56218
    * @param Id
    * @return  string
    */
    @AuraEnabled
    public static string updateAgreementBeforeValidate(String strAgreementId, String action) {  
        ilib_LogEvent.push(LOG_TITLE +'.updateAgreementBeforeValidate');  
        ilib_LogEvent.info('strAgreementId-->'+strAgreementId);   
        try {
            Set<id> setAggIds = new Set<id>{strAgreementId};                
            Apttus__APTS_Agreement__c objAgreement = new ApttusAgreementSelectors().selectAgreements(setAggIds)[0];
            String strPriorValidationStatus = objAgreement.Validation_Status__c;            
            if(objAgreement.Validation_Status__c == Label.AgreementValidationStatusInProgress){
                ilib_LogEvent.pop();
                ilib_LogEvent.emit();
                return ERROR +Label.UI_ErrorMessage_Agreement_Under_Validation ;
            }else{      
                if(action != Label.AgreementActionPreValidate){
                    objAgreement.Validation_Status__c = label.AgreementValidationStatusInProgress.replace(REPLACEZERO,action);
                    update objAgreement;
                    ilib_LogEvent.pop();
                    ilib_LogEvent.emit();
                    return strPriorValidationStatus;
                }   
                ilib_LogEvent.pop();
                ilib_LogEvent.emit();     
                return '';
            }
            
        }catch (Exception e) {            
            throw new AuraHandledException(e.getMessage());          
        }           
    }


    /*
    * @author Kushagra Desai
    * @Description create SAP format date
    * @param String, String and Sobject
    * @return String date
    */
    public static String generateSAPDate(String dtVar,String objName, Sobject objConfig){
        Datetime dtDate = (Datetime)objConfig.get(dtVar);
        if(dtDate == null) { return ''; }
        else 
        {
            String strDate = '\\'+DATESTR + dtDate.getTime() + ')'+'\\'+'/';
            return strDate;
        }
    }
    /*
    * @author vishnu Kurra
    * @Description create Action SAP format date
    * @param Date
    * @return String date
    */
    public static String generateActionSAPDate(Date dtDate){
        Datetime dtTodaylocal = (Datetime)dtDate;
           String strDate = '\\'+DATESTR + dtTodaylocal.getTime() + ')'+'\\'+'/';
           return strDate;
       }
    /*
    * @author Kushagra Desai
    * @Description  method to send Validation request
    * @param Sobject Apttus__APTS_Agreement__c ,String Action, String Action, String previous validation status
    * @return  string
    */
    @AuraEnabled
    public static string sendValidationRequest(String strAgreementId,String action, String priorValidationStatus){
        Set<id> setAggIds = new Set<id>{strAgreementId};
        Apttus__APTS_Agreement__c objAgreement = new ApttusAgreementSelectors().selectAgreementWithLines(setAggIds)[0];
        if(priorValidationStatus == Label.AgreementValidationStatusSentToSAP){
            return ERROR +Label.UI_ErrorMessage_Agreement_Under_Validation ;
        }
        else if(objAgreement.Apttus_Approval__Approval_Status__c != Label.AgreementApprovalStatusApproved){
            return ERROR +Label.UI_ErrorMessage_Agreement_Not_Approved;
        }
        else if(objAgreement.Number_Of_Agreement_Line_Items__c == 0){
            objAgreement.Validation_Status__c = Label.UI_Agreement_Validation_Status_Completed.replace(REPLACEZERO,action);
            update objAgreement;
            return Label.UI_Message_Agreement_Action_Complete.replace(REPLACEZERO,action);
        }
        else{
            return ApttusAgreementActionService.sendRequestToSAP(objAgreement, action, priorValidationStatus);
        }
    }

     /*
    * @author Vishnu Kurra
    * @Description  method to send PreValidation request
    * @param Sobject Apttus__APTS_Agreement__c ,String Action
    * @return  string
    */
    @AuraEnabled
    public static string sendPreValidationRequest(String strAgreementId,String action){
        Set<id> setAggIds = new Set<id>{strAgreementId};
        Apttus__APTS_Agreement__c objAgreement = new ApttusAgreementSelectors().selectAgreementWithLines(setAggIds)[0];
            return ApttusAgreementActionService.sendRequestToSAP(objAgreement, action, null);//DCP-56218
    }

    /*
    *  @author      : Kushagra Desai
    *  @description : Method to Send Cancel Request to SAP
    *  @param       : String, String Action
    *  @return      : String
    */    
    @AuraEnabled
    public static string sendCancelRequest(String strAgreementId,String action){
        Set<id> setAggIds = new Set<id>{strAgreementId};
        Apttus__APTS_Agreement__c objAgreement = new ApttusAgreementSelectors().selectAgreementWithLines(setAggIds)[0];
        if(objAgreement.Number_Of_Agreement_Line_Items__c == 0 || !objAgreement.Is_Validated_Successful__c){
            objAgreement.Validation_Status__c = Label.UI_Agreement_Validation_Status_Completed.replace(REPLACEZERO,action);
            objAgreement.Apttus__Status__c = Label.AgreementStatusCancelled;
            objAgreement.Apttus__Status_Category__c = Label.AgreementStatusCategoryCancelled;
            ApttusAgreementActionService.updateParentAgreement(objAgreement,action);
            update objAgreement;
            return Label.UI_Message_Agreement_Action_Complete.replace(REPLACEZERO,action);
        }
        else
            return ApttusAgreementActionService.sendRequestToSAP(objAgreement, action, null);//DCP-56218
    }

    /*
    *  @author      : Maruthi
    *  @description : Method to Send Cancel Request to SAP //DCP-56218
    *  @param       : String, String Action, String previous validation status
    *  @return      : String
    */
    @AuraEnabled
    public static string sendCancelRequest(String strAgreementId,String action, String priorValidationStatus) {
        ilib_LogEvent.push(LOG_TITLE +'.sendCancelRequest');  
        ilib_LogEvent.info('priorValidationStatusCancel-->'+priorValidationStatus);                         
        try {
            Set<id> setAggIds = new Set<id>{strAgreementId};
            Apttus__APTS_Agreement__c objAgreement = new ApttusAgreementSelectors().selectAgreementWithLines(setAggIds)[0];
            if(objAgreement.Number_Of_Agreement_Line_Items__c == 0 || !objAgreement.Is_Validated_Successful__c) {
                objAgreement.Validation_Status__c = Label.UI_Agreement_Validation_Status_Completed.replace(REPLACEZERO,action);
                objAgreement.Apttus__Status__c = Label.AgreementStatusCancelled;
                objAgreement.Apttus__Status_Category__c = Label.AgreementStatusCategoryCancelled;
                ApttusAgreementActionService.updateParentAgreement(objAgreement,action);
                update objAgreement;
                ilib_LogEvent.pop();
                ilib_LogEvent.emit();
                return Label.UI_Message_Agreement_Action_Complete.replace(REPLACEZERO,action);
            }
            else {
                ilib_LogEvent.pop();
                ilib_LogEvent.emit();
                return ApttusAgreementActionService.sendRequestToSAP(objAgreement, action, priorValidationStatus);//DCP-56218
            }            
        }catch (Exception e) {            
            throw new AuraHandledException(e.getMessage());          
        }        
    }
	
    /*
    * @author Kushagra Desai
    * @Description  method to send Activate request
    * @param Sobject Apttus__APTS_Agreement__c ,String Action, String previous validation status
    * @return  string
    */
    @AuraEnabled
    public static string sendActivateRequest(String strAgreementId,String action, String priorValidationStatus){
        Set<id> setAggIds = new Set<id>{strAgreementId};
        Apttus__APTS_Agreement__c objAgreement = new ApttusAgreementSelectors().selectAgreementWithLines(setAggIds)[0];
        Boolean boolAgrmntTypeIsOpenOffer = objAgreement.RecordType.Name == Label.AgreementRecordTypeNameOpenOffer; //dcp-54536
        if(objAgreement.Number_Of_Agreement_Line_Items__c == 0){
            if(ApttusAgreementErrorHandler.callCLMActivate(objAgreement)){
                Apttus__APTS_Agreement__c objAgreementUpdated = new ApttusAgreementSelectors().selectAgreementWithLines(setAggIds)[0];
                objAgreementUpdated.Validation_Status__c = Label.UI_Agreement_Validation_Status_Completed.replace(REPLACEZERO,action);
                update objAgreementUpdated;
                ApttusAgreementActionService.updateParentAgreement(objAgreement,Label.AgreementActionActivate);
                return Label.UI_Message_Agreement_Action_Complete.replace(REPLACEZERO,action);
            }
            else
                return Label.UI_Message_Agreement_Action_Failed.replace(REPLACEZERO,action);
        } else if(objAgreement.Number_Of_Agreement_Line_Items__c > 0 && (boolAgrmntTypeIsOpenOffer || priorValidationStatus == Label.AgreementValidationStausValidateCompleted || priorValidationStatus == Label.AgreementValidationStatusActivateFailed)) {        
            return ApttusAgreementActionService.sendRequestToSAP(objAgreement, action, priorValidationStatus); //DCP-56218
        } else {
            return ERROR +Label.UI_ErrorMessage_Agreement_Not_Validate;
        }  
    }
    /*
    * @author Kushagra Desai
    * @Description  method to terminate request
    * @param Sobject Apttus__APTS_Agreement__c ,String Action
    * @return  string
    */
    @AuraEnabled 
    public static string sendTerminateRequest(String strAgreementId,String action){ 
        Set<id> setAggIds = new Set<id>{strAgreementId};
        Apttus__APTS_Agreement__c objAgreement = new ApttusAgreementSelectors().selectAgreementWithLines(setAggIds)[0];
        if(objAgreement.Number_Of_Agreement_Line_Items__c == 0 || String.isBlank(objAgreement.Validation_Status__c)){
            objAgreement.Validation_Status__c = Label.UI_Agreement_Validation_Status_Completed.replace(REPLACEZERO,action);
            objAgreement.Apttus__Status__c = Label.AgreementStatusCategoryTerminated;
            objAgreement.Apttus__Status_Category__c = Label.AgreementStatusCategoryTerminated;
            update objAgreement;
            return Label.UI_Message_Agreement_Action_Complete.replace(REPLACEZERO,action);
        }
        else{
            return ApttusAgreementActionService.sendRequestToSAP(objAgreement, action, null);} //DCP-56218
    }

    /*
    * @author Maruthi
    * @Description  method to terminate request DCP-56218
    * @param Sobject Apttus__APTS_Agreement__c ,String Action, String previous validation status
    * @return  string
    */
    @AuraEnabled
    public static string sendTerminateRequest(String strAgreementId, String action, String priorValidationStatus) { 
        ilib_LogEvent.push(LOG_TITLE +'.sendTerminateRequest');  
        ilib_LogEvent.info('priorValidationStatusTerminate-->'+priorValidationStatus);      
        try{
            Set<id> setAggIds = new Set<id>{strAgreementId};
            Apttus__APTS_Agreement__c objAgreement = new ApttusAgreementSelectors().selectAgreementWithLines(setAggIds)[0];
            if(objAgreement.Number_Of_Agreement_Line_Items__c == 0 || String.isBlank(priorValidationStatus)) {
                objAgreement.Validation_Status__c = Label.UI_Agreement_Validation_Status_Completed.replace(REPLACEZERO,action);
                objAgreement.Apttus__Status__c = Label.AgreementStatusCategoryTerminated;
                objAgreement.Apttus__Status_Category__c = Label.AgreementStatusCategoryTerminated;
                update objAgreement;
                ilib_LogEvent.pop();
                ilib_LogEvent.emit();
                return Label.UI_Message_Agreement_Action_Complete.replace(REPLACEZERO,action);
            }
            else {
                // Changes for DCP-56529
                if(System.isBatch()){
                    objAgreement.Validation_Status__c='Terminate in Progress';
                    update objAgreement;
                    //Publishing platform event so the call to SAP happens in a separate transaction
                    List<Admin_Operation__e> lstAgreementTerminate = new List<Admin_Operation__e>();
                    lstAgreementTerminate.add(new Admin_Operation__e(Related_Record__c=objAgreement.id,Name__c='ApttusAgreementTerminateService'));
                    ilib_LogEvent.message('publishing platform event');
                    EventBus.publish(lstAgreementTerminate);
                    ilib_LogEvent.pop();
                    ilib_LogEvent.emit();
                    return Label.UI_Message_Agreement_Action_Complete.replace(REPLACEZERO,action);
                }else{
                    ilib_LogEvent.pop();
                    ilib_LogEvent.emit();
                    return ApttusAgreementActionService.sendRequestToSAP(objAgreement, action, priorValidationStatus);
                }
                
            } 
        }catch (Exception e) {            
            throw new AuraHandledException(e.getMessage());          
        }                          
    }
	
    /*
    * @author Kushagra Desai
    * @Description generate SAP format date for Line Start date
    * @param Apttus__AgreementLineItem__c
    * @return String date
    */
    public static string generateStartDate(Apttus__AgreementLineItem__c agrline){
        Datetime dtStartDateLocal = (Datetime)agrline.Apttus_CMConfig__StartDate__c;
        Datetime dtTodaylocal = (Datetime)Date.today();
        Datetime dtSupplyAgreementStartDateLocal = (Datetime)agrline.Supply_Agreement_Start_Date__c;
        if(dtStartDateLocal != null ) {
            if(agrline.Customer_Election__c == System.Label.CustomElectionPickListSupplyAgreement && dtSupplyAgreementStartDateLocal !=null ) {
                if(dtSupplyAgreementStartDateLocal < dtTodaylocal){
                    return '\\'+DATESTR + dtTodaylocal.getTime() + ')'+'\\'+'/';
                } else {
                    return '\\'+DATESTR + dtSupplyAgreementStartDateLocal.getTime() + ')'+'\\'+'/';
                 }
            } else if(dtStartDateLocal < dtTodaylocal) {
                if(agrline.Discontinued__c == Label.AgreementLineItemDiscontinuedYes && (agrline.Apttus_CMConfig__LineStatus__c == Label.AgreementLineItemLineStatusUpdated|| agrline.Apttus_CMConfig__LineStatus__c == Label.AgreementLineItemLineStatusExisting)) 
                    {
                        return '\\'+ DATESTR + dtTodaylocal.getTime() + ')'+'\\'+'/';
                    }
                    if(agrline.Discontinued__c == Label.AgreementLineItemDiscontinuedNo && (agrline.Apttus_CMConfig__LineStatus__c == Label.AgreementLineItemLineStatusUpdated|| agrline.Apttus_CMConfig__LineStatus__c == Label.AgreementLineItemLineStatusNew))
                    {
                        return '\\'+ DATESTR + dtTodaylocal.getTime() + ')'+'\\'+'/';
                    }
                }
            else if(dtStartDateLocal >= dtTodaylocal) { return '\\'+ DATESTR + dtStartDateLocal.getTime() + ')'+'\\'+'/'; }
            else { return '\\'+ DATESTR + dtStartDateLocal.getTime() + ')'+'\\'+'/'; }
        }
            return '';
    }

    /*
    * @author Kushagra Desai
    * @Description generate SAP format date for Line Start date (Terminate)
    * @param Apttus__AgreementLineItem__c
    * @return String date
    */
    public static string generateTerminateStartDate(Apttus__AgreementLineItem__c agrline)
    {
        // DCP-56507 Updated the Termination start date logic.
        Datetime dtStartDateLocal = agrLine.RecordType.DeveloperName == Label.AgreementLineItemRecordTypeDevNameOpenOffer && agrline.Customer_Election__c == System.Label.CustomElectionPickListSupplyAgreement ? (Datetime)agrline.Supply_Agreement_Start_Date__c : (Datetime)agrline.Apttus_CMConfig__StartDate__c;
        Datetime dtEndDatelocal = agrLine.RecordType.DeveloperName == Label.AgreementLineItemRecordTypeDevNameOpenOffer && agrline.Customer_Election__c == System.Label.CustomElectionPickListSupplyAgreement ? (Datetime)agrline.Supply_Agreement_End_Date__c :(DateTime)agrline.Apttus_CMConfig__EndDate__c;
        Datetime dtTodaylocal = (Datetime)Date.today();        
        
        if(dtStartDateLocal != null && dtEndDatelocal != null) {
            if ((dtStartDateLocal < dtTodaylocal && dtEndDatelocal < dtTodaylocal) || agrline.Discontinued__c == Label.AgreementLineItemDiscontinuedYes) {
                return '\\' + DATESTR + dtStartDateLocal.getTime() + ')' + '\\' + '/';
            } else if(dtStartDateLocal < dtTodaylocal && dtEndDatelocal >= dtTodaylocal) {
                return '\\' + DATESTR + dtTodaylocal.getTime() + ')' + '\\' + '/'; // Fix for pointer 3
            } else if(dtStartDateLocal >= dtTodaylocal && dtEndDatelocal >= dtTodaylocal) {
                return '\\' + DATESTR + dtStartDateLocal.getTime() + ')' + '\\' + '/'; //Fix for pointer 4
            }           
        }
        return '';
    }

    /*
    * @author Kushagra Desai
    * @Description generate SAP format date for Line end date
    * @param Apttus__AgreementLineItem__c
    * @return String date
    */
    public static string generateEndDate(Apttus__AgreementLineItem__c agrline){
        Datetime dtEndDatelocal = (DateTime)agrline.Apttus_CMConfig__EndDate__c;
        Datetime dtStartDateLocal = (Datetime)agrline.Apttus_CMConfig__StartDate__c;
        Datetime dtTodaylocal = (Datetime)Date.today();
        Datetime dtSupplyAgreementEndDateLocal = (Datetime)agrline.Supply_Agreement_End_Date__c;
        if(dtStartDateLocal != null && dtEndDatelocal != null) {
            if(agrline.Customer_Election__c == System.Label.CustomElectionPickListSupplyAgreement && dtSupplyAgreementEndDateLocal !=null) {
                 return '\\'+DATESTR + dtSupplyAgreementEndDateLocal.getTime() + ')'+'\\'+'/';
               } else if(dtStartDateLocal < dtTodaylocal) {
                if(agrline.Discontinued__c == Label.AgreementLineItemDiscontinuedYes && (agrline.Apttus_CMConfig__LineStatus__c == Label.AgreementLineItemLineStatusUpdated|| agrline.Apttus_CMConfig__LineStatus__c == Label.AgreementLineItemLineStatusExisting)) 
                {
                    return '\\'+DATESTR + dtTodaylocal.getTime() + ')'+'\\'+'/';
                }    
                if(agrline.Discontinued__c == Label.AgreementLineItemDiscontinuedNo && (agrline.Apttus_CMConfig__LineStatus__c == Label.AgreementLineItemLineStatusUpdated|| agrline.Apttus_CMConfig__LineStatus__c == Label.AgreementLineItemLineStatusNew))
                {
                    return '\\'+DATESTR + dtEndDatelocal.getTime() + ')'+'\\'+'/';
                }    
            }
            else if(dtStartDateLocal >= dtTodaylocal) { return '\\'+DATESTR + dtEndDatelocal.getTime() + ')'+'\\'+'/'; }
            else { return '\\'+DATESTR + dtEndDatelocal.getTime() + ')'+'\\'+'/'; }
        }
        return '';
    }
    /*
    * @author Kushagra Desai
    * @Description generate SAP format date for Line End date (Terminate)
    * @param Apttus__AgreementLineItem__c
    * @return String date
    */
    public static string generateTerminateEndDate(Apttus__AgreementLineItem__c agrline){
        // DCP-56507 Updated the Termination start date logic.
        Datetime dtStartDateLocal = agrLine.RecordType.DeveloperName == Label.AgreementLineItemRecordTypeDevNameOpenOffer && agrline.Customer_Election__c == System.Label.CustomElectionPickListSupplyAgreement ? (Datetime)agrline.Supply_Agreement_Start_Date__c : (Datetime)agrline.Apttus_CMConfig__StartDate__c;
        Datetime dtEndDatelocal = agrLine.RecordType.DeveloperName == Label.AgreementLineItemRecordTypeDevNameOpenOffer && agrline.Customer_Election__c == System.Label.CustomElectionPickListSupplyAgreement ? (Datetime)agrline.Supply_Agreement_End_Date__c :(DateTime)agrline.Apttus_CMConfig__EndDate__c;
        
        if(dtStartDateLocal != null && dtEndDatelocal != null) {          
            return '\\' + DATESTR + dtEndDatelocal.getTime() + ')' + '\\' + '/';        
        }
        return '';
    }

    /*
    * @author Rishab Wali
    * @Description DCP-34579 Updates the Termination Date on the Agreement
    * @param - Agreement Id and Date Termination Date
    * @return Boolean
    */
    @AuraEnabled
    public static string updateTerminationDateAgreement(Id agreementId , String termDate )
    {
        Apttus__APTS_Agreement__c objAgreement = new Apttus__APTS_Agreement__c(Id = agreementId);
        if(termDate == BLANKSTR) 
        { 
            objAgreement.Apttus__Termination_Date__c = null;   
        }
        else 
        {
            objAgreement.Apttus__Termination_Date__c = Date.valueOf(termDate);
        }
		
        try
        {
            update objAgreement;
            return 'true';
        }
        Catch(Exception e)
        {
            return e.getMessage();
        } 
    }
    /*
    * @author Himanshu
    * @Description generate rate for open offer agreement line item
    * @param Apttus__AgreementLineItem__c
    * @return String discount
    */
    public static Decimal generateRateForOpenOffer(Apttus__AgreementLineItem__c agrline) {
        if(agrline.Customer_Election__c == Label.CustomElectionPickListQuote) {
            return agrline.Quote_Discount__c;
        } else if(agrline.Customer_Election__c == Label.CustomElectionPickListSupplyAgreement) {
            return agrline.Supply_Agreement_Discount__c;
        } else if(agrline.Customer_Election__c == Label.CustomElectionPickListUniversalGrid) {
            return agrline.Universal_Grid_Discount__c;
        } else {
            return agrline.PSP_Discount__c;
        }
    }
}
