/**
*    @author Adyasha Satapathy
*    @date   2021-09-23
*    @description  DCP-:47727 LWC controller to detect duplicate agreement lines based on agreement id provided
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Adyasha Satapathy            2021-09-23           Initial Version
*         Maruthi B                    2022-05-30           DCP-52839 updated calculateDuplicateLines method and DuplicateDataSet inner class
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class AgreementLinesFindDuplicatesController 
{
    private static final String LOG_TITLE = 'AgreementLinesFindDuplicatesController';
    private static final String STRING_CODE_PARAMETER_FIELDS_LIST = 'LWC_Duplicate_AgrLineItems_Fields';
    
    /*
    *  @author:         Adyasha
    *  @description:    main method to be called from js controller which checks for duplicates
    */
    @AuraEnabled(cacheable=true)
    public static string getDuplicateAgreementLines(String agreementId)
    {
        Map<String, Apttus__AgreementLineItem__c> mapUniqueKeyToAgremeementLine = new Map<String, Apttus__AgreementLineItem__c>();        
        Set<Id> setAgreementIdsFromRelatedAgreements = new Set<Id>();
        AgreementLineDuplicateWrapper wrapperForDuplicateLines = new AgreementLineDuplicateWrapper();
        Set<Id> setLatestAgreementIds = null;

        try{
            List<Apttus__AgreementLineItem__c> lstAgreementLineItem = new ApttusAgreementLineItemSelectors().selectAgreementLineItem(new Set<Id>{agreementId});

            if(lstAgreementLineItem == null || lstAgreementLineItem.isEmpty()) 
            { 
                wrapperForDuplicateLines.strMessage = Label.No_Agreement_Lines_For_Duplicates_Validation;
                return JSON.serialize(wrapperForDuplicateLines);
            }

            List<String> lstFields = getFieldsListForDuplicateSearch(); 

            prepareMapOfUniqueKeyToAgremeementLine(lstAgreementLineItem, lstFields, mapUniqueKeyToAgremeementLine);
            Map<Id, List<Apttus__AgreementLineItem__c>> mapAgreementIdToListAgreementLines = getMapOfAgreementIdToListOfAgreementLines(agreementId);

            if(mapAgreementIdToListAgreementLines == null || mapAgreementIdToListAgreementLines.isEmpty())
            {
                wrapperForDuplicateLines.strMessage = Label.No_Agreement_Lines_For_Duplicates_Validation;
                return JSON.serialize(wrapperForDuplicateLines);
            }

            setLatestAgreementIds = prepareSupportDataForRelatedAgreements(mapAgreementIdToListAgreementLines.keySet(),setAgreementIdsFromRelatedAgreements);
            
            wrapperForDuplicateLines = calculateDuplicateLines(mapAgreementIdToListAgreementLines,mapUniqueKeyToAgremeementLine,setAgreementIdsFromRelatedAgreements,setLatestAgreementIds,lstFields);
            
            if(wrapperForDuplicateLines.duplicates == null || wrapperForDuplicateLines.duplicates.isEmpty()) { wrapperForDuplicateLines.strMessage = Label.No_Duplicate_Agreement_Lines_Found; }
            
            return JSON.serialize(wrapperForDuplicateLines);
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage()); 
        }
        
    }
    /*
    *  @author:         Adyasha
    *  @description:    returns list of fields for duplicate search for Agreement Line Item
    */
    public static List<String> getFieldsListForDuplicateSearch()
    {
        Code_Parameter__mdt objCodeParameter = new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String>{STRING_CODE_PARAMETER_FIELDS_LIST})[0];
        return objCodeParameter.Value__c.split(';');
    }

    /*
    *  @author:         Adyasha
    *  @description:    returns String of values based on Fields passed for Agreement Line Item
    */
    public static String getKeyForUniqueMap(Apttus__AgreementLineItem__c agreementLine,List<String> fieldsList)
    {
        String strKey = '';
        
        for(String fieldName : fieldsList)
        {              
            strKey += agreementLine.get(fieldName) == null || String.isBlank(String.valueOf(agreementLine.get(fieldName))) ? '****' :  String.valueOf(agreementLine.get(fieldName));
        }
        return strKey;
    }

    /*
    *  @author:         Adyasha
    *  @description:    prepares map containing unique key to agreement line prepared using values from list of fields 
    */
    private static void prepareMapOfUniqueKeyToAgremeementLine(List<Apttus__AgreementLineItem__c> lstAgreementLineItem, List<String> lstFields, Map<String, Apttus__AgreementLineItem__c> mapUniqueKeyToAgremeementLine)
    {
        for(Apttus__AgreementLineItem__c agreementLine : lstAgreementLineItem)
        {
            if(agreementLine.Discontinued__c == Label.Yes) { continue; }  
            String strKey = getKeyForUniqueMap(agreementLine,lstFields);            
            if(!mapUniqueKeyToAgremeementLine.containsKey(strKey))
            {
                mapUniqueKeyToAgremeementLine.put(strKey,agreementLine);
            }
        }
    }

    /*
    *  @author:         Adyasha
    *  @description:    prepares map containing agreement Id to List of corresponding Agreement Lines
    */
    private static Map<Id, List<Apttus__AgreementLineItem__c>> getMapOfAgreementIdToListOfAgreementLines(String agreementId)
    {
        List<Agreement_Account_Relationship__c> lstAggrementAccountRelationships = new AgreementAccountRelationshipSelectors().selectByAgreementId(new Set<Id>{agreementId});

        Set<Id> setAccountIds = UtilsCollection.getSetOfIds(lstAggrementAccountRelationships, 'Account__c');
        
        List<Apttus__AgreementLineItem__c> lstAllAgreementLines = new ApttusAgreementLineItemSelectors().selectByAccountIdsExcludingGivenAgreements(setAccountIds, new Set<Id>{agreementId}, new Set<String>{Label.AgreementStatusCategoryInEffect});

        Map<Id, List<Apttus__AgreementLineItem__c>> mapAgreementIdToListAgreementLines = (Map<Id, List<Apttus__AgreementLineItem__c>>) UtilsCollection.getMapOfIdToSObjects(lstAllAgreementLines,'Apttus__AgreementId__c');
        
        return mapAgreementIdToListAgreementLines;
    }

    /*
    *  @author:         Adyasha
    *  @description:    prepares suppport Data regarding related agreements of given agreement
    */
    private static Set<Id> prepareSupportDataForRelatedAgreements(Set<Id> setParentAgreementIds, Set<Id> setAgreementIdsFromRelatedAgreements)
    {
        Set<Id> setLatestAgreementIds = null;
        ilib_LogEvent.push(LOG_TITLE + '.prepareSupportDataForRelatedAgreements()');
        List<Apttus__APTS_Related_Agreement__c> lstRelatedAgreements = new ApttusRelatedAgreementSelectors().getRelatedAgreementToForParentAgreements(setParentAgreementIds);
        
        for(Apttus__APTS_Related_Agreement__c objRelatedAgreement : lstRelatedAgreements) 
        {
            setAgreementIdsFromRelatedAgreements.add(objRelatedAgreement.Apttus__APTS_Contract_From__c);
            setAgreementIdsFromRelatedAgreements.add(objRelatedAgreement.Apttus__APTS_Contract_To__c);
        }
        setLatestAgreementIds = getSetOfLatestAgreementIds(lstRelatedAgreements);
        ilib_LogEvent.message('setLatestAgreementIds ::: '+setLatestAgreementIds);
        ilib_LogEvent.pop();

        return setLatestAgreementIds;
    }

    /*
    *  @author:         Adyasha
    *  @description:    calculates the duplicate agreement lines in the system for given agreement 
    */
    private static AgreementLineDuplicateWrapper calculateDuplicateLines(Map<Id, List<Apttus__AgreementLineItem__c>> mapAgreementIdToListAgreementLines, Map<String, Apttus__AgreementLineItem__c> mapUniqueKeyToAgremeementLine, Set<Id> setAgreementIdsFromRelatedAgreements,Set<Id> setLatestAgreementIds, List<String> lstFields)
    {
        ilib_LogEvent.push(LOG_TITLE + '.calculateDuplicateLines()');
        AgreementLineDuplicateWrapper wrapper = new AgreementLineDuplicateWrapper();
        ilib_LogEvent.message('mapAgreementIdToListAgreementLines ::: '+JSON.serialize(mapAgreementIdToListAgreementLines));
        for(Id aggId : mapAgreementIdToListAgreementLines.keySet())
        {
            for(Apttus__AgreementLineItem__c agreementLine : mapAgreementIdToListAgreementLines.get(aggId))
            {
                String strKey = getKeyForUniqueMap(agreementLine,lstFields);
                if(agreementLine.Discontinued__c == Label.Yes) { continue; }
                if(mapUniqueKeyToAgremeementLine.containsKey(strKey) && mapUniqueKeyToAgremeementLine.get(strKey).Id != agreementLine.Id)
                {                    
                    String currentAgreementWholeNumber = mapUniqueKeyToAgremeementLine.get(strKey).Apttus__AgreementId__r.Apttus__FF_Agreement_Number__c.substringBefore('.');
                    String prospectDuplicateAgreementWholeNumber = agreementLine.Apttus__AgreementId__r.Apttus__FF_Agreement_Number__c.substringBefore('.');
                    Boolean isNotARelatedAgreement = currentAgreementWholeNumber != prospectDuplicateAgreementWholeNumber;            
                    
                    if(isNotARelatedAgreement && checkIfCurrentALIDateRangeCriteriaSatisifed(mapUniqueKeyToAgremeementLine,strKey,agreementLine) && checkIfAgreementIsLatest(agreementLine,setAgreementIdsFromRelatedAgreements,setLatestAgreementIds))                   
                    {
                         //DCP-52839
                        DuplicateDataSet wrapDuplicate = new DuplicateDataSet(agreementLine);
                        wrapDuplicate.existingDiscount = String.valueOf(mapUniqueKeyToAgremeementLine.get(strKey).Discount__c);
                        wrapDuplicate.existingDiscountType = mapUniqueKeyToAgremeementLine.get(strKey).Discount_Type__c; 
                        wrapper.duplicates.add(wrapDuplicate);
                    }
                }
            }
        }
        ilib_LogEvent.pop();
        return wrapper;
    }

    /*
    *  @author:         Adyasha
    *  @description:    checks if date criteria is satisfied between agreement lines
    */
    private static Boolean checkIfCurrentALIDateRangeCriteriaSatisifed(Map<String, Apttus__AgreementLineItem__c> mapUniqueKeyToAgremeementLine,String strKey,Apttus__AgreementLineItem__c agreementLine)
    {
        Boolean isCriteriaSatisfied = false;

        if((agreementLine.Apttus_CMConfig__StartDate__c <= mapUniqueKeyToAgremeementLine.get(strKey).Apttus_CMConfig__StartDate__c
        && mapUniqueKeyToAgremeementLine.get(strKey).Apttus_CMConfig__StartDate__c <= agreementLine.Apttus_CMConfig__EndDate__c)
        || (agreementLine.Apttus_CMConfig__StartDate__c <= mapUniqueKeyToAgremeementLine.get(strKey).Apttus_CMConfig__EndDate__c
        && mapUniqueKeyToAgremeementLine.get(strKey).Apttus_CMConfig__EndDate__c <= agreementLine.Apttus_CMConfig__EndDate__c))        
        {
            isCriteriaSatisfied = true;
        }
        return isCriteriaSatisfied;
    }

    /*
    *  @author:         Adyasha
    *  @description:    checks if the current agreement is the latest one and has no successors
    */
    private static Boolean checkIfAgreementIsLatest(Apttus__AgreementLineItem__c agreementLine,Set<Id> setAgreementIdsFromRelatedAgreements, Set<Id> setLatestAgreementIds)
    {
        Boolean boolCriteriaSatisfied = null;        

        if(!setAgreementIdsFromRelatedAgreements.contains(agreementLine.Apttus__AgreementId__c))
        { 
            boolCriteriaSatisfied = true;
        }
        else if(setLatestAgreementIds != null && setLatestAgreementIds.contains(agreementLine.Apttus__AgreementId__c))
        {
            boolCriteriaSatisfied = true;
        }
        else
        {
            boolCriteriaSatisfied = false;
        }               
        return boolCriteriaSatisfied;
    }

    /*
    *  @author:         Adyasha
    *  @description:    returns a set of all latest agreements which have no successors
    */
    private static Set<Id> getSetOfLatestAgreementIds(List<Apttus__APTS_Related_Agreement__c> lstRelatedAgreements)
    {
        Set<Id> setLatestAgreementIds = new Set<Id>();
        Map<String, Id> mapAgreementNumberStringToAgreementId = new Map<String,Id>();
        String agreementNumber = '';
        Boolean isContractTo = false;
       
        for(Apttus__APTS_Related_Agreement__c relationship : lstRelatedAgreements)
        {
            if(relationship.Apttus__APTS_Contract_To__r.Apttus__Status_Category__c == Label.AgreementStatusCategoryInEffect)
            {
                agreementNumber = relationship.Apttus__APTS_Contract_To__r.Apttus__FF_Agreement_Number__c;
                isContractTo = true;
            }
            else if(relationship.Apttus__APTS_Contract_From__r.Apttus__Status_Category__c == Label.AgreementStatusCategoryInEffect)
            {
                agreementNumber = relationship.Apttus__APTS_Contract_From__r.Apttus__FF_Agreement_Number__c;
                isContractTo = false;
            }
            String extract = String.isNotBlank(agreementNumber) ? agreementNumber.substringBefore('.') : '';
                        
            if(String.isNotBlank(extract))
            {
                if(!mapAgreementNumberStringToAgreementId.containsKey(extract))
                {
                    if(isContractTo)
                    {
                        mapAgreementNumberStringToAgreementId.put(extract,relationship.Apttus__APTS_Contract_To__c);
                    }

                    else{
                        mapAgreementNumberStringToAgreementId.put(extract,relationship.Apttus__APTS_Contract_From__c);
                    }

                }
            }
        }
        setLatestAgreementIds.addAll(mapAgreementNumberStringToAgreementId.values());
        return setLatestAgreementIds;
    }

    /*
    *  @author:         Adyasha
    *  @description:    wrapper class to store list of duplicate agreement lines with error message
    */
    public class AgreementLineDuplicateWrapper
    {
        public List<DuplicateDataSet> duplicates;
        public String strMessage;

        /* constructor */
        public AgreementLineDuplicateWrapper()
        {
            this.duplicates = new List<DuplicateDataSet>();
            this.strMessage = '';
        }
    }

    /*
    *  @author:         Adyasha
    *  @description:    wrapper class to store details pf duplicate agreement line item
    */
    public class DuplicateDataSet
    {
        public String agreementLineID;
        public String agreementLineName;
        public String agreemementId;
        public String agreementName;
        public String agreementNumber;
        public String lineType;
        public String customerERPNumber;
        public String salesOrg;
        public String distributionChannel;
        public String currencyValue;
        public String materialNumber;
        public String discount;
        public String discountPercent;
        public String discountType;
		public String existingDiscount;//DCP-52839     
        public String existingDiscountType;//DCP-52839
        public String startDate;
        public String endDate;
        public String discontinued;
        public String materialGroup;
        public String priceGroup;
        public String ucERPNumber;
        public String partnerRole;

        /* constructor */
        public DuplicateDataSet(Apttus__AgreementLineItem__c agreementLine)
        {
            this.agreementLineID = '/'+agreementLine.Id;
            this.agreementLineName = agreementLine.Name;
            this.agreemementId = '/'+agreementLine.Apttus__AgreementId__c;
            this.agreementName = agreementLine.Apttus__AgreementId__r.Name;
            this.agreementNumber = agreementLine.Apttus__AgreementId__r.Apttus__FF_Agreement_Number__c;
            this.customerERPNumber = agreementLine.Customer_ERP_Number__c;
            this.lineType = agreementLine.Line_Type__c;
            this.salesOrg = agreementLine.Sales_Org__c;
            this.distributionChannel = agreementLine.Distribution_Channel__c;
            this.currencyValue = agreementLine.CurrencyIsoCode;
            this.materialNumber = agreementLine.Material_Number__c;
            this.discount = String.valueOf(agreementLine.Discount__c);
            this.discountPercent = String.valueOf(agreementLine.Discount_In_Percent__c);
            this.discountType = agreementLine.Discount_Type__c;
            this.startDate = String.valueOf(agreementLine.Apttus_CMConfig__StartDate__c);
            this.endDate = String.valueOf(agreementLine.Apttus_CMConfig__EndDate__c);
            this.discontinued = agreementLine.Discontinued__c;
            this.materialGroup = agreementLine.Material_Group_1__c;
            this.priceGroup  =  agreementLine.Price_Group__c;
            this.ucERPNumber = agreementLine.Ultimate_Consignee_ERP_Number__c;
            this.partnerRole = agreementLine.Partner_Role__c;
        }
    }
}