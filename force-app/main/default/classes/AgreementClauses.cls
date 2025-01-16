/*    @author Saswati Prusty
*    @date   02-Mar-2020
*    @description    AgreementClauses domain class 
*    Modification Log:
*   ---------------------------------------------------------------------------------------------------------------------------
*    Developer                      Date               Description
*    Saswati Prusty                02-Mar-2020         DCP:Initial Version : 
*    Karthik Rayani                27-Aug-2020         DCP-40114 picklist to multipicklist changes for region__c & action__c in custom approval matrix 
*    Himanshu                      31-Mar-2022         Code Scan Fixes
*    Avina                         14-Jun-2022         CMSI-68,Added instrumentation
*    Preetha                       08-July-2022        CMSI-51 added WorkStream
*    Jitesh Lakhwani               09-Jan-2023         CodeScan Fix

--------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class AgreementClauses extends ilib_SObjectDomain{

    private static final String LOG_TITLE = 'AgreementClauses';
    /**
    * @description Parameterized Constructor called
    * @params List<Apttus__Agreement_Clause__c> sObjectList
    * @return void
    **/
    public AgreementClauses(List<Apttus__Agreement_Clause__c> sObjectList) {
        super(sObjectList);
    }
    
    
    /**
    * Boilerplate which is required for base class instantiation logic
    **/
    public class Constructor implements ilib_SObjectDomain.IConstructable {
        /**
        * @description  Constructor of base class
        * @params List<SObjects> sObjectList
        * @return sObjectList
        **/
        public ilib_SObjectDomain construct(List<SObject> sObjectList) {
            return new AgreementClauses(sObjectList);
        }
    }
    
    /**
    * Called during before insert event (e.g. set defaults before insert of proposal record)
    **/
    
    public override void onbeforeInsert(){
        ilib_LogEvent.message('@@@ Inside onbeforeInsert method');//CMSI-68
        
        List<Apttus__Agreement_Clause__c> lstAgreementClauses = (List<Apttus__Agreement_Clause__c>)records;
        set<Id> setAgreements = new set<Id>();
        for(Apttus__Agreement_Clause__c oAgreementClause : lstAgreementClauses)
        {
            ilib_LogEvent.message('@@@ Inside onbeforeInsert method - loop');//CMSI-68
            setAgreements.add(oAgreementClause.Apttus__Agreement__c);
        }
        ilib_LogEvent.info('setAgreements-->: '+setAgreements);//CMSI-68

        List<Apttus__APTS_Agreement__c> lstAgreements = new ApttusAgreementSelectors().selectAgreements(setAgreements);
        List<Apttus__APTS_Agreement__c> listAgr = new List<Apttus__APTS_Agreement__c>();
        for(Apttus__APTS_Agreement__c oAgreement : lstAgreements )
        {
           if(!((oAgreement.Apttus__Status__c =='In Renewal' || oAgreement.Apttus__Status__c =='In Amendment' ) && oAgreement.Apttus__Status_Category__c =='Request'))
           {    
               listAgr.add(oAgreement);
           }
        }
        if(!listAgr.isEmpty())
        setClauseApproval(lstAgreementClauses,listAgr);
    }
    
    /**
* Called during before update event.
**/
    
    public override void onBeforeUpdate(Map<Id, sObject> existingRecords){
        List<Apttus__Agreement_Clause__c> lstAgreementClauses = (List<Apttus__Agreement_Clause__c>)records;

       /* List<Schema.SObjectField> lstFieldAPINames = UtilsObject.getSObjectFields('Apttus__Agreement_Clause__c').values();
        System.debug('@@@ Agreement record before update- '+lstAgreementclauses);
        for (Apttus__Agreement_Clause__c objAgreementClause : (List<Apttus__Agreement_Clause__c>)records)
        {
            Boolean booFoundDifference = false;
            for (Schema.SObjectField fieldName : lstFieldAPINames)
            {
                 booFoundDifference = false;
                String strFieldName = fieldName.getDescribe().getName();
                if (objAgreementClause.get(strFieldName) != existingRecords.get(objAgreementClause.Id).get(strFieldName))
                {
                    booFoundDifference = true;
                    break;
                }

            }
             if (booFoundDifference)
                lstAgreementClauses.add(objAgreementClause);

        } */
        
        if (lstAgreementClauses.size()>0)
        {
            Map<Id, Apttus__Agreement_Clause__c> idToOldAgreementClauses = (Map<Id,Apttus__Agreement_Clause__c>)existingRecords;
            Set<Id> setAgreement = new Set<Id>();
            for(Apttus__Agreement_Clause__c oAgreementClause : lstAgreementClauses)
            {
              
                
                if(oAgreementClause.Apttus__Action__c != idToOldAgreementClauses.get(oAgreementClause.id).Apttus__Action__c)                   
                {
                    setAgreement.add(oAgreementClause.Apttus__Agreement__c);
                }
                  
            }
            ilib_LogEvent.info('setAgreement-->: '+setAgreement);//CMSI-68
            
              List<Apttus__APTS_Agreement__c> lstAgreements = new ApttusAgreementSelectors().selectAgreements(setAgreement);
              ilib_LogEvent.info('lstAgreements-->: '+UtilsCollection.getSetOfIds(lstAgreements));//CMSI-68
        if(lstAgreements.size()>0)
        setClauseApproval(lstAgreementClauses,lstAgreements);
        
    }
    }
    /*CMSI-51
    * method will return the workstream
    */
    public override string getWorkstream(){
        return ilib_LogEvent.SALES;
    }
    
    /*
    @author: Saswati Prusty
    @Description: DCP-32046 : Approval Method for Agreement Clauses
    @Param: Agreement Clause records
    */
    
    public void setClauseApproval( List<Apttus__Agreement_Clause__c> lstAgreementClauses, List<Apttus__APTS_Agreement__c> lstAgreements){
        ilib_LogEvent.push(LOG_TITLE + '.setClauseApproval()');//CMSI-68
        ilib_LogEvent.info('@@@ Inside setClauseApproval method');//CMSI-68
        ilib_LogEvent.info('lstAgreementClausesId-->: '+UtilsCollection.getSetOfIds(lstAgreementClauses));//CMSI-68
        ilib_LogEvent.info('lstAgreementsId-->: '+UtilsCollection.getSetOfIds(lstAgreements));//CMSI-68
        Map<Id, Apttus__APTS_AGreement__c> mapIdtoAgreement= new Map<Id,Apttus__APTS_AGreement__c>();
        for(Apttus__APTS_Agreement__c oAgreement:lstAgreements)
        {
            mapIdtoAgreement.put(oAgreement.id, oAgreement);
        }
        ilib_LogEvent.info('mapIdtoAgreement' + mapIdtoAgreement);//CMSI-68
        
        // For Agreement Record type
        Map<Id, RecordTypeInfo> agreementRecordTypeinfo = Apttus__APTS_Agreement__c.sObjectType.getDescribe().getRecordTypeInfosById();
        ilib_LogEvent.info('agreementRecordTypeinfo' + agreementRecordTypeinfo);//CMSI-68
        
        List<Custom_Approval_Matrix__c> lstCustomApprovalMatrix = new CustomApprovalMatrixSelector().selectActive();
        ilib_LogEvent.info('@@@ Inside setClauseApproval method - Approval Matrices'+UtilsCollection.getSetOfIds(lstCustomApprovalMatrix));//CMSI-68
        CustomApprovalMatrixWrapper customMatrixWrapper = getCustomApprovalMatrixWrapper(lstCustomApprovalMatrix);
        ilib_LogEvent.info('@@@ Inside setClauseApproval method - CustomMAtrix WRapper '+customMatrixWrapper);//CMSI-68
        set<Id> agreementApprovalRequired = new set<Id>();
        for(Apttus__Agreement_Clause__c oAgreementClause : lstAgreementClauses)
        {
            // String strApprovalCategory = '';
            String strApprovalStatus = null;
            CustomApprovalMatrixResult objApprovalMatrix;
            String strEmailQueue = null;
            String strRegion=null;
            
            String rTName = null;
            if(mapIdtoAgreement.containskey(oAgreementClause.Apttus__Agreement__c))
            {
                if(agreementRecordTypeinfo.containsKey(mapIdtoAgreement.get(oAgreementClause.Apttus__Agreement__c).RecordTypeId)) {
                    rtName = agreementRecordTypeinfo.get(mapIdtoAgreement.get(oAgreementClause.Apttus__Agreement__c).RecordTypeId).getName();
                }
                ilib_LogEvent.message('@@@ RTNAME - '+rtName );//CMSI-68
            }
            
            
            if(oAgreementClause.Apttus__Action__c!=null||oAgreementClause.Apttus__Action__c!='')
            {
                if(customMatrixWrapper.agreementClauseToListApprovalMatrix.containskey(oAgreementClause.Apttus__Clause__c))
                {
                    ilib_LogEvent.message('####### inside wrapper condition : agreementClauseToListApprovalMatrix.containskey ');//CMSI-68
                    List<Custom_Approval_Matrix__c> lstApprovalMatrix = customMatrixWrapper.agreementClauseToListApprovalMatrix.get(oAgreementClause.Apttus__Clause__c);
                    // mapAgreementIdToRegion.containskey(oAgreementClause.Apttus__Agreement__c);
                    strRegion = oAgreementClause.Region__c;
                    objApprovalMatrix = getApprovalMatrix(oAgreementClause,strRegion,lstApprovalMatrix,rtName);
                    ilib_LogEvent.message('@@@ Approval Matrix  Found - '+ objApprovalMatrix);//CMSI-68
                    strEmailQueue = (objApprovalMatrix.soApprovalMatrix == null ? null : objApprovalMatrix.soApprovalMatrix.Email_Queue__c);
                    if(objApprovalMatrix.soApprovalMatrix.id!=null)
                    {
                        oAgreementClause.Approval_Matrix_Clause_Approval__c = objApprovalMatrix.soApprovalMatrix.id;
                        strApprovalStatus = System.Label.AgreementApprovalStatusApprovalRequired;
                        agreementApprovalRequired.add(oAgreementClause.Apttus__Agreement__c);
                        ilib_LogEvent.message('agreementApprovalRequired-->: '+agreementApprovalRequired);//CMSI-68
                    }
                }
                if(oAgreementClause.Approval_Status__c!= System.Label.AgreementApprovalStatusPendingApproval)
                oAgreementClause.Approval_Status__c = strApprovalStatus;
                oAgreementClause.Clause_Approval_Email_Queue__c = strEmailQueue;
                
            }
            // oAgreementClause.Apttus__Agreement__r.Apttus_Approval__Approval_Status__c =strApprovalStatus;
        }
        
        for(Apttus__APTS_Agreement__c objAgreement: lstAgreements)
        {
            if(agreementApprovalRequired.contains(objAgreement.Id) && objAgreement.Apttus_Approval__Approval_Status__c!='Pending Approval')
            {
                objAgreement.Apttus_Approval__Approval_Status__c = System.Label.AgreementApprovalStatusApprovalRequired;
            }
        }
        update lstAgreements;
        ilib_LogEvent.info('lstAgreementsId-->: '+UtilsCollection.getSetOfIds(lstAgreements));//CMSI-68
        ilib_LogEvent.pop();//CMSI-68 
        
        
    }
    
    /*
@author: Saswati Prusty
@Description: DCP-32046 : Fetch Approval Matrix Method for Agreement Clauses
@Param: Agreement Clause records
*/
    
    /*  public void getApprovalMatrix( List<Apttus__Agreement_Clause__c> lstAgreementClauses){



} */
    
    /*
@author: Saswati
@Story : DCP-31789
@param: List of Agreement Line Items.
@param: Agreement record
@param: List Of all Approval Matrices
@param: Distribution Channel
@Description : Find Approval Matrix for Approval Framework
*/
    
    
    private CustomApprovalMatrixResult getApprovalMatrix( Apttus__Agreement_Clause__c oAgreementClause, String strRegion,  List<Custom_Approval_Matrix__c> lstApprovalMatrix, string strAgreementRecordType){
        //Integer intApprovalLevel;
        ilib_LogEvent.message('oAgreementClause-->: '+oAgreementClause);//CMSI-68
        ilib_LogEvent.message('strRegion-->: '+strRegion);//CMSI-68
        ilib_LogEvent.message('strAgreementRecordType-->: '+strAgreementRecordType);//CMSI-68
        Custom_Approval_Matrix__c objApprovalMatrix = new Custom_Approval_Matrix__c();
        
        if (lstApprovalMatrix.size() > 0 ){
           
            boolean boolRegionCheck = false;
            boolean boolActionCheck = false;
            boolean boolAgreementRecordTypeCheck = false;
            boolean boolClauseNameCheck = false; 
            
            for (Custom_Approval_Matrix__c objMatrix : lstApprovalMatrix){ 
                ilib_LogEvent.fine('Inside loop for Approval Matrix - '+ objMatrix);//CMSI-68
                boolAgreementRecordTypeCheck = (objMatrix.Agreement_Record_Type__c == strAgreementRecordType);    
                boolClauseNameCheck = (objMatrix.Clause_Name__c == oAgreementClause.Apttus__Clause__c);  
                if(!String.isBlank(objMatrix.Region__c))        
                    boolRegionCheck = (objMatrix.Region__c.split(';').contains(strRegion)); //DCP-40114
                if(!String.isBlank(objMatrix.Action__c)) 
                    boolActionCheck = (objMatrix.Action__c.split(';').contains(oAgreementClause.Apttus__Action__c)); //DCP-40114
                if(boolClauseNameCheck && boolRegionCheck && boolActionCheck && boolAgreementRecordTypeCheck){
                   
                    objApprovalMatrix = objMatrix;
                    break;
                }                    
            }
        }
        
        CustomApprovalMatrixResult result = new CustomApprovalMatrixResult();
        result.soApprovalMatrix = objApprovalMatrix;
        ilib_LogEvent.message('result - '+ result);//CMSI-68
        return result;
    }
    
    
    /**
*  @author Saswati Prusty
*  @description Wrapper class for List of Appproval Matrix
**/
    public class CustomApprovalMatrixWrapper {
        
        public Map<String, List<Custom_Approval_Matrix__c>> agreementClauseToListApprovalMatrix {
            get {
                if (agreementClauseToListApprovalMatrix == null) agreementClauseToListApprovalMatrix = new Map<String, List<Custom_Approval_Matrix__c>>();
                return agreementClauseToListApprovalMatrix;
            }
            set;
        }
    }
    
    
    
    
    /**
*  @author Saswati
*  @description Convert Custom Approval Matrix List to Wrapper (i.e. group matrix records based on approval category)
*  @param List<Custom_Approval_Matrix__c> List of Custom Approval Matrix
*  @return CustomApprovalMatrixWrapper Approval Matrix Wrapper
**/
    
    private CustomApprovalMatrixWrapper getCustomApprovalMatrixWrapper(List<Custom_Approval_Matrix__c> lstCustomApprovalMatrix){
        ilib_LogEvent.push(LOG_TITLE + '.getCustomApprovalMatrixWrapper()');//CMSI-68
        CustomApprovalMatrixWrapper objcustomMatrixWrapper = new CustomApprovalMatrixWrapper();
        for (Custom_Approval_Matrix__c am : lstCustomApprovalMatrix)
        {
            if(am.RecordType.DeveloperName == System.Label.RecordTypeCustomApprovalMatrixClauseApproval){
                if(!objcustomMatrixWrapper.agreementClauseToListApprovalMatrix.containsKey(am.Clause_Name__c)) objcustomMatrixWrapper.agreementClauseToListApprovalMatrix.put(am.Clause_Name__c, new List<Custom_Approval_Matrix__c>());
                objcustomMatrixWrapper.agreementClauseToListApprovalMatrix.get(am.Clause_Name__c).add(am);
            } 
        }
        ilib_LogEvent.info('objcustomMatrixWrapper - '+ objcustomMatrixWrapper);//CMSI-68
        ilib_LogEvent.pop();//CMSI-68
        return objcustomMatrixWrapper;
    }
    
    /*
    *@author  Saswati Prusty
    *@description Wrapper Method for storing custom approval matrix result
    */
    public class CustomApprovalMatrixResult {
        Custom_Approval_Matrix__c soApprovalMatrix;
    } 
    
    
    
    
    
}