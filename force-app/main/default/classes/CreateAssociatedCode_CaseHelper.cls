/**
 * @description       : Create associated code
 * @author            : Pooja Shalwadi
 * @last modified on  : 06-08-2022
**/
public class CreateAssociatedCode_CaseHelper {
  
     /**DCP-25243
    *  @AUTHOR Tapas Chakraborty
    *  @DESCRIPTION - fetch code title based on metat data type and case subtype and category
    *  @RETURN : void
    **/
    public static void fetchCodeTitleFromCase(List<Case> lstNewCases, Map<Id, Case> mapOldCases)
    {
        
        Map<Id,String> mapCodetitlesWithCases = new Map<Id,String>();
        Map<String,String> mapMetadata = new Map<String,String>();  

        //DCP-34275: Prepare Code Title set to fetch the Code Library records
		CasesHelper.AssociatedCodeMapping associatedCodeMappingQuery = new  CasesHelper.AssociatedCodeMapping();
        associatedCodeMappingQuery.initMapAssociatedCodesMapping();
        if(Cases.mapAssociatedCodesMapping != null && !Cases.mapAssociatedCodesMapping.isEmpty()){
            for(Associated_Code_Mapping__mdt associateMdt : Cases.mapAssociatedCodesMapping.values()){
                mapMetadata.put(associateMdt.Sub_Type__c+'_'+associateMdt.Category__c, associateMdt.Code_Title__c);
            }
        }       
        if(lstNewCases != null && !lstNewCases.isEmpty()){
			for(Case objNewCase : lstNewCases) 
            {
				
				Case objOldCase  = null;
				if(mapOldCases != null){
					objOldCase = mapOldCases.get(objNewCase.Id);
				}
                //DCP-34275 : Fetch Code Title from Metadata Types using case Sub Type and Category
				if(objNewCase.Status != objOldCase.Status && objNewCase.Status == System.label.CaseStatusCompleted && objOldCase.RecordTypeId==Cases.INQUIRY_CASE_RECORDTYPE
					&& mapMetadata.containsKey(objNewCase.Sub_Type__c+'_'+objNewCase.Category__c) && mapMetadata.get(objNewCase.Sub_Type__c+'_'+objNewCase.Category__c) != null)
                    {
						mapCodetitlesWithCases.put(objNewCase.Id, mapMetadata.get(objNewCase.Sub_Type__c+'_'+objNewCase.Category__c));
					} 
			}
		}  

        fetchCodeLibrary(lstNewCases,mapCodetitlesWithCases,mapOldCases);        
    }


    /**
    * @description :fetch code library based on case subtype and category(code title)
    * @param lstNewCases
    * @param mapCodetitlesWithCases
    * @param mapOldCases
    **/
    public static void fetchCodeLibrary(List<Case> lstNewCases, Map<Id,String> mapCodetitlesWithCases, Map<Id,Case> mapOldCases)
    {
        List<Code_Library__c> lstCodeLibrary = new List<Code_Library__c>();  
        if(mapCodetitlesWithCases != null && !mapCodetitlesWithCases.isEmpty()){
            Set<Id> setCaseIds = mapCodetitlesWithCases.keySet();
            Set<String> setCodeTitles = new Set<String>();
            
            // Added condition for CMCM - 10026
            for(Case caseRec:lstNewCases) {
                if(caseRec.Status != mapOldCases.get(caseRec.Id).Status && caseRec.Status == System.label.CaseStatusCompleted) {
                    setCodeTitles.add(mapCodetitlesWithCases.get(caseRec.Id));
                }
            }
            // Fetch Code Library records based on Code Titles fetched from metadata types
            CasesHelper.CodeLibraries codeLibrariesQuery = new  CasesHelper.CodeLibraries();
            codeLibrariesQuery.initMapCodeLibraryIdsToRec(setCodeTitles);

            if(Cases.mapCodeLibraryIdsToRec != null && !Cases.mapCodeLibraryIdsToRec.isEmpty()){
                lstCodeLibrary = Cases.mapCodeLibraryIdsToRec.values();
            }
            if(!lstCodeLibrary.isEmpty()){
                Cases.lstAssociationCodesToInsert=addAssociatedCodeRelatedToCase(lstNewCases,setCaseIds,lstCodeLibrary);
            }
        } 
        
    }

    /**
    * @description : query associated code based on code library title
    * @param lstNewCases 
    * @param setCaseIds 
    * @param lstCodeLibrary 
    * @return List<Associated_Codes__c> 
    **/
    public static List<Associated_Codes__c> addAssociatedCodeRelatedToCase(List<Case> lstNewCases,Set<Id> setCaseIds,List<Code_Library__c> lstCodeLibrary)
    {

        List<Associated_Codes__c> lstAssociatedCodesQueried = new List<Associated_Codes__c>();
        Map<Id, List<Associated_Codes__c>> caseIdToAssociatedCodes = new Map<Id, List<Associated_Codes__c>>();
        List<Associated_Codes__c> lstAssociationCodes = new List<Associated_Codes__c>();
        //DCP-34275:  Prepare Code Library Id set to check and create Associated codes
        Set<Id> setCodeIds = new Set<Id>();
        for(Code_Library__c codeLibrary : lstCodeLibrary){
            setCodeIds.add(codeLibrary.Id);
        }
        CasesHelper.AssociatedCodes associatedCodesQuery = new  CasesHelper.AssociatedCodes();                
        associatedCodesQuery.initMapAssociatedCodeIdsToAssociatedCodes(setCaseIds);
        if(Cases.mapAssociatedCodeIdsToAssociatedCodes != null && !Cases.mapAssociatedCodeIdsToAssociatedCodes.isEmpty()){
            for(Associated_Codes__c objAssociatedCode  : Cases.mapAssociatedCodeIdsToAssociatedCodes.values()){
                if(setCodeIds.contains(objAssociatedCode.Code_Title__c)){
                    lstAssociatedCodesQueried.add(objAssociatedCode);
                }                       
            }

        }
        
        for(Associated_Codes__c objAssoCode : lstAssociatedCodesQueried)
        {
            if(!caseIdToAssociatedCodes.containsKey(objAssoCode.Case__c))
                caseIdToAssociatedCodes.put(objAssoCode.Case__c, new List<Associated_Codes__c>());
            caseIdToAssociatedCodes.get(objAssoCode.Case__c).add(objAssoCode);
        }
        if(lstNewCases != null && !lstNewCases.isEmpty()){ 
            lstAssociationCodes = createAssociatedCodeToInsert(lstNewCases,setCaseIds,lstCodeLibrary,caseIdToAssociatedCodes);
        } 
        return lstAssociationCodes;  
    }

    /**
    * @description : Add associated code instatnces to a list for creation
    * @param lstNewCases 
    * @param lstCodeLibrary 
    * @param caseIdToAssociatedCodes 
    * @return List<Associated_Codes__c> 
    **/
    public static List<Associated_Codes__c> createAssociatedCodeToInsert(List<Case> lstNewCases,Set<Id> setCaseIds,List<Code_Library__c> lstCodeLibrary,Map<Id, List<Associated_Codes__c>> caseIdToAssociatedCodes)
    {
        List<Associated_Codes__c> lstAssociationCodes = new List<Associated_Codes__c>();
        Map<String, String> codeTypeToCaseFields = new Map<String, String>{System.label.AssociatedCodeTypeSubject => 'Has_Inquiry_Case_Subject_Code__c', 
        System.label.AssociatedCodeTypeAnalysis => 'Has_Analysis_Code__c',
        System.label.AssociatedCodeTypeResolution => 'Has_Resolution_Code__c', 
        System.label.AssociatedCodeTypeVerification => 'Has_Verification_Code__c',
        System.label.AssociatedCodeTypeHazard => 'HasHazardCode__c', 
        System.label.CodeLibraryCodeTypeLogisticsReviewCode => 'Contains_Logistics_Analysis_Code__c'};

        for(Case objCase : lstNewCases){
            if(!setCaseIds.contains(objCase.Id))
                continue;
            Id idCase = objCase.Id;
            for(Code_Library__c codeLibrary : lstCodeLibrary){
                if(caseIdToAssociatedCodes== null || !caseIdToAssociatedCodes.containsKey(idCase) || caseIdToAssociatedCodes.get(idCase).size()==0)
                {
                    Associated_Codes__c objAssociatedCode = new Associated_Codes__c();
                    objAssociatedCode.Code_Title__c = codeLibrary.Id;
                    objAssociatedCode.Case__c = idCase;
                    objAssociatedCode.Code_Type__c=codeLibrary.Code_Type__c;
                    objAssociatedCode.Case_Type__c=codeLibrary.Case_Type__c;
                    lstAssociationCodes.add(objAssociatedCode);

                    if(codeTypeToCaseFields.get(codeLibrary.Code_Type__c) != null && objCase.get(codeTypeToCaseFields.get(codeLibrary.Code_Type__c)) != null)
                        objCase.put(codeTypeToCaseFields.get(codeLibrary.Code_Type__c), true);
                } 
            } 
        } 

        return lstAssociationCodes;
    }
}
