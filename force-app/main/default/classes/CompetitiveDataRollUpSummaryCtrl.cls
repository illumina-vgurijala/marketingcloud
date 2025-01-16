/**
 *    @author Kushagra Desai
 *    @date   29-Aug-2019
 *    @description  Controller class for COmpetitiveDataRollUpSummary
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Jitesh Lakhwani               6-July-2022            Code Scan fixes of Comments
 *    Prem Ranjan                   20-Feb-2023          CodeScan Fixes (APEX) Variable Naming Conventions 
 *    Gerardo Garcia                18-Oct-2023          Add accountId
 *    Gerardo Garcia                14-Feb-2024          CMCM-5648 getJSONProductNames that would be used on combo-boxes CCT custom Form create/edit
 *    ------------------------------------------------------------------------------------ 
 *                       
 */
public with sharing class CompetitiveDataRollUpSummaryCtrl {

    public static Set<Id> setAccountid = new Set<Id>();
    @TestVisible
    private static final String OTHER_OPTION = 'Other';
    @TestVisible
    private static final String OUTSOURCED_OPTION = 'Outsourced / Service Provider';
    private static final String CCT_OBJ_API_NAME = 'Competitive_Complementary_Technology__c';

    /**
     * @description: This will load intital company data. It will contain company name and it's respective label which will returned in a wrapper class.
     * @param : String recordId
     * @return : MasterData - wrapper class
    */
    @AuraEnabled(cacheable=true)
    public static MasterData initRecords(String recordId){
        List<DataTableWrapper> lstObjDataTable = new List<DataTableWrapper>();
        Account_Plan__c objAccountPlanInstance = new AccountPlanSelector().getAccountPlanByAccountPlanRecordId(recordId);
        if( objAccountPlanInstance != null){
            List<Account> objAccount = new AccountsSelector().getAccountsHierarchy(objAccountPlanInstance.Account_Name__r.Ultimate_Parent_Id__c, objAccountPlanInstance.Account_Name__r.Ultimate_Parent__c);
            setAccountid = UtilsCollection.getSetOfIds(objAccount,'Id');  
            if(!setAccountid.isEmpty()){
                List<AggregateResult> lstAggCompetitiveData = new CompetitiveTechnologySelector().getAggregateResult('CompetitorName__c',setAccountid);
                    for(AggregateResult aggData : lstAggCompetitiveData){
                        DataTableWrapper objDataTableWrapper = new DataTableWrapper((String)aggData.get('CompetitorName__c'),(Integer)aggData.get('NumberOfRecord'));
                        lstObjDataTable.add(objDataTableWrapper);
                    }
                system.debug('--~~~Final List--~~~'+lstObjDataTable);
                List<CustomDisplayText> lstLabel = new List<CustomDisplayText>();

                CustomDisplayText cdt = new CustomDisplayText();
                cdt.LabelName = 'UI_CompetitiveDataRollUpSummaryCtrl_Error';
                cdt.LabelValue = Label.UI_CompetitiveDataRollUpSummaryCtrl_Error;
                lstLabel.add(cdt);

                cdt.LabelName = 'UI_CompetitiveDataRollUpSummaryCtrl_Header';
                cdt.LabelValue = Label.UI_CompetitiveDataRollUpSummaryCtrl_Header;

                Map<String,String> mapLabelToValue = new Map<String,String>();
                mapLabelToValue.put('UI_CompetitiveDataRollUpSummaryCtrl_Error',Label.UI_CompetitiveDataRollUpSummaryCtrl_Error);
                mapLabelToValue.put('UI_CompetitiveDataRollUpSummaryCtrl_Header',Label.UI_CompetitiveDataRollUpSummaryCtrl_Header);

                MasterData mdt = New MasterData();
                mdt.CompData = lstObjDataTable;
                mdt.lstLabels = JSON.serialize(mapLabelToValue);
                mdt.accountId = objAccountPlanInstance.Account_Name__c;

                system.debug('--Labelssssss-> '+lstLabel);
                System.debug('---Final---?'+mdt);
                return mdt; 
            }
        }

        return null;
    }

    /**
     * @description: This will create the related data for the company passed as parameter(strComapnyName) and will form the 'RelatedDataTable' wrapper to return it to UI.
     * @param : String recordId,Integer Offset,String strCompanyName
     * @return : List<RelatedDataTable> - wrapper class
    */
    @AuraEnabled(cacheable=true)
    public static List<RelatedDataTable> relatedRecords(String recordId,Integer Offset,String strCompanyName){
        Account_Plan__c objAccountPlanInstance = new AccountPlanSelector().getAccountPlanByAccountPlanRecordId(recordId);
        if( objAccountPlanInstance != null){
            List<Account> objAccount = new AccountsSelector().getAccountsHierarchy(objAccountPlanInstance.Account_Name__r.Ultimate_Parent_Id__c, objAccountPlanInstance.Account_Name__r.Ultimate_Parent__c);
            setAccountid = UtilsCollection.getSetOfIds(objAccount,'Id');
        }
        system.debug('Account Id ---> '+setAccountid);
        system.debug('Account Id ---> '+Offset);
        system.debug('Account Id ---> '+strCompanyName);
        if(!setAccountid.isEmpty()){
            List<RelatedDataTable> lstRelatedData = new List<RelatedDataTable>();
            List<Competitive_Complementary_Technology__c> lstCompetitiveData = new CompetitiveTechnologySelector().getAllRecords(setAccountid,Offset,strCompanyName);
            System.debug('List of data--> '+lstCompetitiveData);
            for(Competitive_Complementary_Technology__c compData : lstCompetitiveData){
                RelatedDataTable objDetails = new RelatedDataTable(compData);
                lstRelatedData.add(objDetails);
            }
            return lstRelatedData;
        }
        return null;
    }

    /**
     * @description: Deliver JSON that is used to generate dynamic comboxes.
     * @param : String recordId,Integer Offset,String strCompanyName
     * @return : List<RelatedDataTable> - wrapper class
    */
    @AuraEnabled(cacheable=true)
    public static Map<String, Map<String, List<String>>> getJSONProductNames() {

        Map<String, Map<String, List<String>>> wrapper = new Map<String, Map<String, List<String>>>();
        Map<String, String> competitorMap = new Map<String, String>();
        try {
            // get available product categories from picklist
            List<PickListValueWrapper> productCategories = UtilsObject.getPicklistFromDescribe(CCT_ProductName__mdt.Product_Category_1__c.getDescribe());

            setDefaultOptions(wrapper, productCategories, competitorMap);
            setOptionsFromRecords(wrapper, productCategories, competitorMap);
            addOtherOptionInProducts(wrapper);

            ilib_LogEvent.message(JSON.serializePretty(wrapper));
            ilib_LogEvent.emit();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return wrapper;
    }

    /**
     * @description: Initialize  options for available competitors name picklist with all categories picklist
     * For Competitors name picklist it will Add "Other" and "Outsourced / Service Provider"
     * For productCategories picklist  it will Add "Other"
     * Also for each category will add "Other" Product Name.
     * @param: wrapper of options.
     */
    private static void setDefaultOptions(Map<String, Map<String, List<String>>> wrapper, List<PickListValueWrapper> productCategories, Map<String, String> competitorMap) {
        // get available competitors name from pick list
        List<PickListValueWrapper> competitorNames = UtilsObject.getPicklistFromDescribe(CCT_ProductName__mdt.Competitor_Name__c.getDescribe());
        competitorNames.add(new PickListValueWrapper(OTHER_OPTION, OTHER_OPTION));
        competitorNames.add(new PickListValueWrapper(OUTSOURCED_OPTION, OUTSOURCED_OPTION));

        // add other option.
        productCategories.add(new PickListValueWrapper(OTHER_OPTION, OTHER_OPTION));

        // generate initial wrapper from default options.
        for(PickListValueWrapper competitorName : competitorNames) {
            wrapper.put(competitorName.strValue, getMapCatProd(productCategories));
            //Do not add other & outsourced option to map
            if(competitorName.strKey != OTHER_OPTION && competitorName.strKey != OUTSOURCED_OPTION){
                competitorMap.put(competitorName.strKey, competitorName.strValue);
            }
        }
    }

    /**
     * @description: Adds Other option on products as last item for every category. It won't add if 'Outsourced / Service Provider' as competitor name.
     * @param: wrapper to fill info.
     */
    private static void addOtherOptionInProducts(Map<String, Map<String, List<String>>> wrapper) {
        for(String competitorName : wrapper.keySet()) {

            Map<String, List<String>> mapCatProductName = wrapper.get(competitorName);
            for(String category : mapCatProductName.keySet()) {
                List<String> products = mapCatProductName.get(category);
                products.add(OTHER_OPTION);
            }
        }
    }

    /**
     * @description: returns a map of categories with empty product list.
     */
    private static Map<String, List<String>> getMapCatProd(List<PickListValueWrapper> productCategories) {
        Map<String, List<String>> mapCategories =  new Map<String, List<String>>();
        for(PickListValueWrapper pCat : productCategories) {
            mapCategories.put(pCat.strValue, new List<String>());
        }

        return mapCategories;
    }

    /**
     * @description: Fill options from CCT_ProductName__mdt records metadata.
     */
    private static void setOptionsFromRecords(Map<String, Map<String, List<String>>> wrapper, List<PickListValueWrapper> productCategories, Map<String, String> competitorMap) {

        // get filter of active categories strings.
        List<String> categories = new List<String>();
        for(PickListValueWrapper entry: productCategories) {
            categories.add(entry.strValue);
        }
    
        List<CCT_ProductName__mdt> records = [SELECT Competitor_Name__c, 
            Product_Category_1__c, Product_Name__c 
            FROM CCT_ProductName__mdt 
            WHERE Enable__c = true
            AND Competitor_Name__c IN :competitorMap.keySet()
            AND Product_Category_1__c IN :categories
            ORDER BY Competitor_Name__c, Product_Name__c ASC];

        for(CCT_ProductName__mdt record : records) {
            Map<String, List<String>> category = wrapper.get(competitorMap.get(record.Competitor_Name__c));
        
            if(category == null) {
                category = new  Map<String, List<String>>();
            }

            List<String> productNames = category.get(record.Product_Category_1__c);

            if(productNames == null) {
                productNames = new List<String>();
            }
            productNames.add(record.Product_Name__c);

            category.put(record.Product_Category_1__c, productNames);

            wrapper.put(competitorMap.get(record.Competitor_Name__c), category);
        }
    }

    /**
     * @description: Retrieves Object Name.
     * @param: String recordId
     * @return: String. Object Name
     */
    @AuraEnabled
    public static string getObjectNameById(Id recordId){
        try {
            if(String.isBlank(recordId)) return null;

            String sObjName = recordId.getSObjectType().getDescribe().getName();
            if(sObjName == CCT_OBJ_API_NAME) {
                Competitive_Complementary_Technology__c cct = new CompetitiveTechnologySelector().getRecodById(recordId);
                return CompetitiveTechnologySelector.isAccountType(cct) ? 'Account' : 'Opportunity';
            }
            return sObjName;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description: Wrapper class to store datatable data and labels.
     * @param : None
     * @return : None
    */
    public class MasterData{
        @AuraEnabled
        public List<DataTableWrapper> CompData;
        @AuraEnabled
        public String lstLabels;
        @AuraEnabled
        public String accountId;
    }

    /**
     * @description: Wrapper class to store datatable data and labels.
     * @param : None
     * @return : None
    */
    public class CustomDisplayText{
        @AuraEnabled
        public String LabelName;
        @AuraEnabled
        public String LabelValue;
    }
    /**
     * @description: DataTableWrapper wrapper class for data table to store company name and total record
     * @param : None
     * @return : None
    */
    public class DataTableWrapper {
        @AuraEnabled
        public String CompanyName;
        @AuraEnabled
        public Integer NumberOfRecord;  
        /*
        @AuraEnabled
        public Set<RelatedDataTable> CompetitiveDataList;
        */
        /**
        * @description: DataTableWrapper wrapper class constructor
        * @param : None
        * @return : None
        */
        public DataTableWrapper(String CompanyName,Integer NumberOfRecord){
            this.CompanyName=CompanyName;
            this.NumberOfRecord = NumberOfRecord;
            //CompetitiveDataList = new List<RelatedDataTable>(lstCompData);
        }
    }

    /**
     * @description: RelatedDataTable wrapper class store company related data.
     * @param : None
     * @return : None
     */
    public class RelatedDataTable {
        @AuraEnabled public String Company;
        @AuraEnabled public String CompanyOther;
        @AuraEnabled public String ProductName;
        @AuraEnabled public String ProductNameOther;
        @AuraEnabled public String IsInUse;
        @AuraEnabled public Decimal NumberOfUnits;
        @AuraEnabled public String CreatedByUser;
        @AuraEnabled public String AccountName;
        @AuraEnabled public String AccountId;
        @AuraEnabled public String Name;
        @AuraEnabled public String Id;

        /**
         * @description: RelatedDataTable wrapper class constructor.
         * @param : None
         * @return : None
         */
        public RelatedDataTable(Competitive_Complementary_Technology__c compData){
            this.Company = compData.CompetitorName__c;
            this.CompanyOther = compData.Company_Other__c;
            this.ProductName = compData.ProductName__c;
            this.ProductNameOther = compData.Product_Name_Other__c;
            this.IsInUse = compData.Is_In_Use__c;
            this.NumberOfUnits = compData.Number_Of_Units__c;
            this.AccountId = compData.Account__c;
            this.AccountName = compData.Account__r.Name;
            this.CreatedByUser = compData.CreatedBy.Name;
            this.Name = compData.Name;
            this.Id =compData.Id;
        }
    }
}