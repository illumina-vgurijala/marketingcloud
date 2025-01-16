/**
*   @author Vignesh/KD
*   @date 24-Jan-2020
*   @description    Controller for Agreement Generate Screen
*   Test class for 90% coverage: TestAgreementOutputParametersForm
*   Test class for 75% coverage: TestAgreementOutputParametersForm
*   Modification Log:
*   -----------------------------------------------------------------------------------------------------------------------
*           Developer                   Date                Description
*           Kushagra Desai              10-Feb              Addedd SAP integration
*           Kushagra Desai              3-March-2020        JSON enhancement
*           Aditi Joshi                 8-Sep-2020          DCP-39985 - Added DisAgrNum toggle to SAP request
*           Satya Swain                 24-Feb-2021         TASK0569014: Fix to send only selected Material Group to SAP
*           Anand Palla                 03-Mar-2022         DCP-52310 - Removed the dependency on ERP numbers for auto-selection of MG1
*           Nishan Shetty               22-April-2022       CodeScan Fix:Avoid Literals in If condition
*           Jitesh Lakhwani             6-July-2022         Code Scan fixes of Comments
*           Himanshu                    16-Sep-2022         DCP54539 - Ability to generate CSP document from the OO Agreement
*   ------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class AgreementOutputParametersForm {

    //Start CodeScan Fix [Avoid Literals in If condition]
    private static final Integer INTEGER_TWO = 2;
    private static final Integer INTEGER_STATUS_CODE_200 = 200;
    //End CodeScan Fix

    /**
    *   @description : AgreementGenerateWrapper wrapper Class
    **/
    public class AgreementGenerateWrapper{
        public string CustomerErpNum;
        public string Status;
        public string DistiChannel;
        public string SalesOrg;
        public string PricingDate;
        public string AgreementNum;
        public string Curr;
        public string AgreeStartDate;
        public string AgreeExpDate;
        public string Language;
        public string HideListPrice;
		public string DisAgrNum;	//DCP-39985
        public string CustomerName;
        public string AgreementName;
        public List<MaterialGroup> im_mat_grpSet = new List<MaterialGroup>();
        public List<IncludeMaterial> im_mat_includeSet = new List<IncludeMaterial>();
        public List<ExcludeMaterial> im_mat_excludeSet = new List<ExcludeMaterial>();
        public List<Object> ex_returnSet = new List<Object>();
    }
    /**
    *   @description : Material Group Class
    **/
    public class MaterialGroup{
        public string MatGrp;
    }

    /**
    *   @description : Include Material Class
    **/
    public class IncludeMaterial{
        public string Matnr;
    }

    /**
    *   @description : Exclude Material Class
    **/
    public class ExcludeMaterial{
        public string Matnr;
    }
    /**
    *   @author Vignesh
    *   @description generate Initial data asWrapper
    **/
    @AuraEnabled(cacheable=true)
    public static AgreementWrapper getAgreementWrapper(string AgreementId) {
        List<Apttus__APTS_Agreement__c> lstAgreement = new ApttusAgreementSelectors().selectAgreementWithLines(new Set<Id>{AgreementId});
        List<Agreement_Account_Relationship__c> lstAgreementRelationShip;// DCP-54539 start
        if(lstAgreement[0].RecordType.Name == Label.AgreementRecordTypeNameOpenOffer) { 
            lstAgreementRelationShip = new AgreementAccountRelationshipSelectors().selectByAgreementIdAndOpenOffer(new Set<Id>{AgreementId});
        }
        else {
            lstAgreementRelationShip = new AgreementAccountRelationshipSelectors().selectByAgreementIdSortedByAccountName(new Set<Id>{AgreementId});
        }// DCP-54539 end
               return (new AgreementWrapper(lstAgreement[0],lstAgreementRelationShip));
    }
    /**
    *   @author Vignesh
    *   @description generate Agreement object asWrapper
    **/
    public class AgreementWrapper{
        @AuraEnabled public Apttus__APTS_Agreement__c objAgreement{get;set;}
        @AuraEnabled public list<MaterialGroupCode> lstMaterialGroupCode{get;set;}
        @AuraEnabled  public Map<String,String>  mapoflabels{get;set;}
        @AuraEnabled public String strCompanyName{get;set;}
        @AuraEnabled public List<Agreement_Account_Relationship__c> strAgreementRelationship{get;set;}
        @AuraEnabled public List<String> lstLanguageSet;

        /**
        *@description : Agreement Wrapper Class constructor
        *@param : Apttus__APTS_Agreement__c objAgreement,List<Agreement_Account_Relationship__c> lstAgreementRelationShip
        **/
        public AgreementWrapper(Apttus__APTS_Agreement__c objAgreement,List<Agreement_Account_Relationship__c> lstAgreementRelationShip ){
            this.objAgreement = objAgreement;
            this.strCompanyName = objAgreement.Apttus__Account__r.Name;
            lstMaterialGroupCode = new list<MaterialGroupCode>();
            this.strAgreementRelationship = lstAgreementRelationShip;
            this.lstLanguageSet = getPicklistValueBasedonRecordType('Apttus__APTS_Agreement__c','Preferred_Language__c',objAgreement.RecordTypeId);
            set<string> setMaterialGroup = new set<string>();
            for(Apttus__AgreementLineItem__c objALI : new ApttusAgreementLineItemSelectors().selectAgreementLineItem(new Set<Id>{objAgreement.id}) ){
                    setMaterialGroup.add(objALI.Material_Group_1__c);
            }
            for(Material_Group__mdt objMG : new MaterialGroupsSelector().selectAll()){
                lstMaterialGroupCode.add(new materialGroupCode(setMaterialGroup.contains(objMG.MasterLabel) ? true : false , objMG.MasterLabel,  objMG.Description__c ) );
            }

            this.mapoflabels = new Map<String,string>{
                    'Agreement_Details' => Label.Agreemenent_Generate_AgreementDetails,
                    'Agreement_Output_Parameters' => Label.Agreemenent_Generate_Agreement_Output_Parameters,
                    'Customer' => Label.Agreemenent_Generate_Customer,
                    'Customer_Name' => Label.Agreemenent_Generate_Customer_Name,
                    'Sales_Organization' => Label.Agreemenent_Generate_Sales_Organization,
                    'Distribution_Channel' => Label.Agreemenent_Generate_Distribution_Channel,
                    'Pricing_Date' => Label.Agreemenent_Generate_Pricing_Date,
                    'Expiration_Date' => Label.Agreemenent_Generate_Expiration_Date,
                    'Display_Customer_Discounted_Items_Only' => Label.Agreemenent_Generate_Display_Customer_Discounted_Items_Only,
                    'Material_Group_1_Code' => Label.Agreemenent_Generate_Material_Group_1_Code,
                    'Material_Group_1_Description' => Label.Agreemenent_Generate_Material_Group_1_Description,
                    'Material_Group_1' => Label.Agreemenent_Generate_Material_Group_1,
                    'Material_Selection' => Label.Agreemenent_Generate_Material_Selection,
                    'Include_All_Materials_from_Agreement' => Label.Agreemenent_Generate_Include_All_Materials_from_Agreement,
                    'Include_Additional_Materials_Up_to_10_Materials' => Label.Agreemenent_Generate_Include_Additional_Materials_Up_to_10_Materials,
                    'label_Exclude_Materials_Up_to_10_Materials' => Label.Agreemenent_Generate_Exclude_Materials_Up_to_10_Materials,
                    'Upload_Materials_to_Include_Exclude' => Label.Agreemenent_Generate_Upload_Materials_to_Include_Exclude,
                    'Template_to_upload_materials' => Label.Agreemenent_Generate_Template_to_upload_materials,
                    'The_CSV_file_has_been_read' => Label.Agreemenent_Generate_The_CSV_file_has_been_read,
                    'Please_upload_correct_file' => Label.Agreemenent_Generate_Please_upload_correct_file,
                    'Hide_List_Price' => Label.Agreemenent_Generate_Hide_List_Price,
					'Dis_Agr_Num' => Label.Agreemenent_Generate_Reference_Agreement_on_Price_List, //DCP-39985
                    'Language' => Label.Agreemenent_Generate_Language,
                    'Currency' => Label.Agreemenent_Generate_Currency
                };


        }
    }
    /**
    *   @author Vignesh
    *   @description Create Materail group Wrapper
    **/
    public class MaterialGroupCode{
        @AuraEnabled public Boolean isSelected{get;set;}
        @AuraEnabled public string  materialGroup{get;set;}
        @AuraEnabled public string Description{get;set;}

        /**
        *@description : MaterialGroupCode Wrapper Class constructor
        *@param : Boolean isSelected, string  materialGroup, string Description
        **/
        public MaterialGroupCode(Boolean isSelected, string  materialGroup, string Description){
            this.isSelected = isSelected;
            this.materialGroup = materialGroup;
            this.Description = Description;
        }
    }

    /**
    *   @author Vignesh
    *   @description : Reads uploaded file.
    **/
    @AuraEnabled
    public static string readCSVFile(Id idContentDocument){
        List<string> lstExcludeValue = new List<string> ();
        List<string> lstIncludeValue = new List<string> ();
        if(idContentDocument != null) {
            // getting File Data based on document id
            ContentVersion objVersion = new ContentVersionsSelector().selectByContentDocumentId(new set<Id>{idContentDocument})[0];
            // split the file data
            List<String> lstCSVLines = objVersion.VersionData.toString().split('\r\n');

            for(Integer i = 1; i < lstCSVLines.size(); i++){
                list<string> lstCommaseperatedvalues = new list<string>();
                lstCommaseperatedvalues = lstCSVLines[i].split(',');

                if(!lstCommaseperatedvalues.isempty()){
                    if(lstCommaseperatedvalues.size() == INTEGER_TWO){
                        if(!String.isBlank(lstCommaseperatedvalues[0]))
                            lstExcludeValue.add(lstCommaseperatedvalues[0]);
                        lstIncludeValue.add(lstCommaseperatedvalues[1]);
                    }
                    else{
                        lstExcludeValue.add(lstCommaseperatedvalues[0]);
                    }
                }
            }
        }
        return  '{"excludeValue": '+JSON.serialize(lstExcludeValue)
                +',"includeValue": '+JSON.serialize(lstIncludeValue)
                +'}';
    }
    /*
    * @author Kushagra Desai
    * @Description Generator method to create request JSON
    * @param Sobject Apttus__APTS_Agreement__c
    * @return JSON string
    */
    public static string createJSON(Apttus__APTS_Agreement__c agg,Set<String> lstIncludeMaterial,Set<String> lstExcludeMaterial,Boolean boolIncludeAllMaterial,List<MaterialGroupCode> lstSelectedGroupCode,String strPricingDate,Boolean boolHidePriceList,String strCompanyName,String strCompanyERP,String strCurr,String strLanguage,String strSalesOrg,Boolean boolDisAgrNum){	//DCP-39985 Added Parameter boolDisAgrNum
        Map<string,string> maplanguageISOCode = new Map<string,string>();
        maplanguageISOCode.put('Chinese','ZH');
        maplanguageISOCode.put('Chinese trad.','ZF');
        maplanguageISOCode.put('English','EN');
        maplanguageISOCode.put('French','FR');
        maplanguageISOCode.put('German','DE');
        maplanguageISOCode.put('Italian','IT');
        maplanguageISOCode.put('Japanese','JA');
        maplanguageISOCode.put('Korean','KO');
        maplanguageISOCode.put('Portuguese','PT');
        maplanguageISOCode.put('Spanish','ES');

        String strJSON;
        Datetime datePrincing= (Datetime)Date.valueOf(strPricingDate);
        strPricingDate ='\\'+'/Date(' + String.valueOf(datePrincing.getTime()) + ')'+'\\'+'/';
        AgreementGenerateWrapper agrWrap = new AgreementGenerateWrapper();
        agrWrap.Status = '';
        agrWrap.AgreementNum = agg.Apttus__FF_Agreement_Number__c;
        agrWrap.CustomerErpNum = strCompanyERP;
        agrWrap.CustomerName = strCompanyName.split(';')[0];
        agrWrap.DistiChannel = agg.Distribution_Channel__c;
        agrWrap.SalesOrg = strSalesOrg != null ? strSalesOrg : '';
        agrWrap.PricingDate = strPricingDate;
        agrWrap.Curr = strCurr != null ? strCurr : '';
        agrWrap.Language = (strLanguage != null && maplanguageISOCode.containsKey(strLanguage)) ? maplanguageISOCode.get(strLanguage) : '' ;
        agrWrap.AgreeStartDate = ApttusAgreementValidateController.generateSAPDate('Apttus__Contract_Start_Date__c','Apttus__APTS_Agreement__c',agg);
        agrWrap.AgreeExpDate = ApttusAgreementValidateController.generateSAPDate('Apttus__Contract_End_Date__c','Apttus__APTS_Agreement__c',agg);
        agrWrap.HideListPrice = boolHidePriceList ? 'X' : '';
		agrWrap.DisAgrNum = boolDisAgrNum || agg.RecordType.Name == Label.AgreementRecordTypeNameOpenOffer ? 'X' : '';	//DCP-39985 // DCP-54539
        agrWrap.AgreementName = agg.Name;
        if(boolIncludeAllMaterial && agg.Number_Of_Agreement_Line_Items__c > 0){
            for(Apttus__AgreementLineItem__c ALI : new ApttusAgreementLineItemSelectors().selectAgreementLineItem(new Set<Id>{agg.id})){
                if(!String.isBlank(ALI.Material_Number__c))
                    lstIncludeMaterial.add(ALI.Material_Number__c);

                // Commenting as part of TASK0569014
                /* if(!String.isBlank(ALI.Material_Group_1__c))
                    lstSelectedGroupCode.add(new materialGroupCode(true ,ALI.Material_Group_1__c,'')); */
            }
        }
        Set<String> setMaterialGrp = new Set<String>();
        for(MaterialGroupCode MGP : lstSelectedGroupCode){
            setMaterialGrp.add(MGP.materialGroup);
        }
        for(String mtrGrp : setMaterialGrp){
            MaterialGroup MG = new MaterialGroup();
            MG.MatGrp = mtrGrp;
            agrWrap.im_mat_grpSet.add(MG);
        }
        for(String includeMat : lstIncludeMaterial){
            IncludeMaterial IM = new IncludeMaterial();
            IM.Matnr = includeMat;
            agrWrap.im_mat_includeSet.add(IM);
        }
        for(String excludeMat : lstExcludeMaterial){
            ExcludeMaterial EM = new ExcludeMaterial();
            EM.Matnr = excludeMat;
            agrWrap.im_mat_excludeSet.add(EM);
        }
        strJSON = JSON.serializePretty(agrWrap);
        System.debug('---JSON--'+strJSON);
        return strJSON;
    }
    /**
    *   @author KD
    *   @description :
    **/
    @AuraEnabled
    public static string sendGenerateRequest(String strFormData,String strAgreementId){
        List<MaterialGroupCode> lstSelectedGroupCode;
        Boolean boolIncludeAllMaterial = false;
        Boolean boolHidePriceList = false;
		Boolean boolDisAgrNum = false;	//DCP-39985
        Set<String> lstIncludeMaterial = new Set<String>();
        Set<String> lstExcludeMaterial= new Set<String>();
        String strJSON;
        String strSAPResponse;
        Set<id> setAggIds = new Set<id>{strAgreementId};
        Apttus__APTS_Agreement__c objAgreement = new ApttusAgreementSelectors().selectAgreementWithLines(setAggIds)[0];
        Map<String,String> mapFormData = (Map<String,String>)JSON.deserialize(strFormData, Map<String,String>.class);
        System.debug('MAP-->'+mapFormData);
        if(mapFormData.containskey('selectedMaterialGroup')){
            lstSelectedGroupCode = (List<MaterialGroupCode>)JSON.deserialize(mapFormData.get('selectedMaterialGroup'),List<MaterialGroupCode>.class);
        }
        if(mapFormData.containskey('IncludeAllMaterial')){
            boolIncludeAllMaterial = Boolean.valueof(mapFormData.get('IncludeAllMaterial')); // DCP-54539
        }
        if(mapFormData.containskey('hideListPrice')){
            boolHidePriceList = Boolean.valueof(mapFormData.get('hideListPrice'));
        }
		if(mapFormData.containskey('disAgrNum')){			//DCP-39985
            boolDisAgrNum = Boolean.valueof(mapFormData.get('disAgrNum'));
        }
        if(mapFormData.containskey('includeAdditionalMaterials')){
            lstIncludeMaterial.addAll(mapFormData.get('includeAdditionalMaterials').split(','));
        }
        if(mapFormData.containskey('excludeAdditionalMaterials')){
            lstExcludeMaterial.addAll(mapFormData.get('excludeAdditionalMaterials').split(','));
        }
        if(mapFormData.containskey('includeMaterialFile')){
            lstIncludeMaterial.addAll((List<String>)JSON.deserialize(mapFormData.get('includeMaterialFile'),List<String>.class));
        }
        if(mapFormData.containskey('excludeMaterialFile')){
            lstExcludeMaterial.addAll((List<String>)JSON.deserialize(mapFormData.get('excludeMaterialFile'),List<String>.class));

        }
        strJSON = createJSON(objAgreement,lstIncludeMaterial,lstExcludeMaterial,boolIncludeAllMaterial,lstSelectedGroupCode,mapFormData.get('pricingDate'),boolHidePriceList,mapFormData.get('customerName'),mapFormData.get('customerERPNumber'),mapFormData.get('curr'),mapFormData.get('language'),mapFormData.get('salesOrg'),boolDisAgrNum);		//DCP-39985 : Added parameter boolDisAgrNum
        strSAPResponse = ApttusAgreementActionService.sendGenerateRequestToSAP(strJSON,strAgreementId);
        if(strSAPResponse.contains('Error-')){
            objAgreement.Pricing_Generation_Status__c = label.AgreementValidationStatusFailed.replace('{0}','Generate');
            update objAgreement;
            return Label.UI_Agreement_Generate_Failed+' '+strSAPResponse.replace('Error-','');
        }
        else{
            objAgreement.Pricing_Generation_Status__c = label.AgreementValidationStatusInProgress.replace('{0}','Generate');
            update objAgreement;
            return Label.UI_Agreement_Generate_Success;
        }
    }
    /**
    *   @author KD
    *   @description : Fetch picklist value depending on Record type
    **/
    @AuraEnabled
    public static List<String> getPicklistValueBasedonRecordType(String objectAPIName, String fieldAPIName, String recordTypeId){

       List<String> lstPicklistValues = new list<String>();

       if(recordTypeId != null){

           String method = 'GET';
           String endpoint = String.format('/services/data/v43.0/ui-api/object-info/{0}/picklist-values/{1}/{2}', new String[]{ objectAPIName, recordTypeId, fieldAPIName });

           HttpRequest request = new HttpRequest();
           request.setEndpoint('callout:Salesforce_Org'+endPoint);
           request.setMethod(method);

           HTTPResponse response = (new Http()).send(request);

           if(response.getStatusCode() == INTEGER_STATUS_CODE_200){

               Map<String,Object> root = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
               if(root.containsKey('values')){
                   List<Object> picklistVals = (List<Object>)root.get('values');
                   for(Object picklistVal : picklistVals){
                       Map<String,Object> picklistValMap = (Map<String,Object>) picklistVal;                    
                    lstPicklistValues.add((String)picklistValMap.get('value'));
                   }
               }

           }

       }
       return lstPicklistValues;
   }

    /**
    *@description : Piclist Value and label Wrapper Class
    **/
    public class PicklistValue{
        public String value {get;set;}
        public String label {get;set;}
    }
}