/***************************************************************************************************************************************
* NAME   : QualtricsSurveyResponse
* DESCRIPTION  : Domain class for QualtricsSurveyResponseTrigger.
*                    
* @AUTHOR : Digvijay Singh
* @DATE   : 14-Feb-2020  
* 
* MODIFICATION LOG: 
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Digvijay           14-Feb-2020         Initial Version. 
* Vignesh            11-Jun-2020         Updated Logic for QSR Proxy. DCP-37395
****************************************************************************************************************************************/

public with sharing class  QualtricsSurveyResponses extends ilib_SObjectDomain{
    
     public static FINAL list<string> QSR_OPEN_STATUSES = new list<string> {
     System.Label.QSRStatusInitiated,
     System.Label.QSRStatusInProgress,
     System.Label.QSRStatusAwaitingResponse};

    public QualtricsSurveyResponses(List<Qualtrics_Survey_Response__c> sObjectList)
    {
        super(sObjectList);
    }

    

    /*
* Boilerplate which is required for base class instantiation logic
*/
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new QualtricsSurveyResponses(sObjectList);
        }
    }
    
    
    /**
*  @author Digvijay Singh
*  @description - To be executed, when the  Qualtrics Survey Response is inserted. 
*               
**/
    public override void onBeforeInsert(){
        set<Id> setOriginalOwner = new set<Id>();
        Map<Id , Id> mapIdtoUser=new Map<Id, Id>();
        Map<Id, User> mapIdtoUserObj=new map<Id, User>();
        map<String,List<String>> mapuserIdtoProfileNPermSet=new map<String,List<String>>();
        set<String> setIdProfileNPermwithRead=new set<String>();
        set<String> setIdUserIdwithRead=new set<String>();
        
        //identify the origincal record ID for which the Qualtrics survey record is created 
        for(Qualtrics_Survey_Response__c qsrObj:(List<Qualtrics_Survey_Response__c>)records){
           if(qsrObj.Originating_Record_Owner__c!=null){
            setOriginalOwner.add(qsrObj.Originating_Record_Owner__c);
           }
        }
        
        //Fetch the User record for User Id's identified above 
        if(setOriginalOwner!=null && !setOriginalOwner.IsEmpty()){
            for(User obj: new UsersSelector().selectByUserId(setOriginalOwner)){
                mapIdtoUserObj.put(obj.Id, obj);
                if(obj.Manager.IsActive) {
                    //Add the Profile ID associated with the user to the map.
                    mapuserIdtoProfileNPermSet.put(obj.ManagerId,new List<String>{obj.Manager.ProfileId});
                }
            }
        }
        
        //Add any Permission Set associated with the user to the map.
        mapuserIdtoProfileNPermSet=getAssignedPermissionSet(mapuserIdtoProfileNPermSet);
        
        //Fetch the Profile and Permission set which has read access on QSR.
        setIdProfileNPermwithRead=getProfileNPermSet('Qualtrics_Survey_Response__c');
        
        
        //compare and fetch the User List who has Edit access on QSR object. 
        if(mapuserIdtoProfileNPermSet!=null && !mapuserIdtoProfileNPermSet.IsEmpty() && !setIdProfileNPermwithRead.IsEmpty()){
            setIdUserIdwithRead=getuserIdwithReadPerm(mapuserIdtoProfileNPermSet,setIdProfileNPermwithRead);
        }
        
        assignStatusAndOwner( (List<Qualtrics_Survey_Response__c>) records, mapIdtoUserObj, setIdUserIdwithRead  );

    }
    /**
    *  @author Vignesh
    *  @description - Toasign Status and owner fields. 
    *               
    **/
    public void assignStatusAndOwner(List<Qualtrics_Survey_Response__c> records , Map<Id, User> mapIdtoUserObj, set<String> setIdUserIdwithRead ){
        
        for(Qualtrics_Survey_Response__c qsrObj:(List<Qualtrics_Survey_Response__c>)records){
            if(qsrObj.NPS_Score__c!=null && qsrObj.NPS_Score__c>=0 && qsrObj.OSAT_Score__c!=Null && qsrObj.OSAT_Score__c>=0 
               && (qsrObj.NPS_Score__c<=6 || qsrObj.OSAT_Score__c<=4) ){
                   qsrObj.Status__c=Label.QSRStatusInitiated;
                   qsrObj.Low_Score_Flag__c=true;
               }else{
                   qsrObj.Status__c=Label.QSRStatusReviewNotRequired;
               }
                   
            if(mapIdtoUserObj!=null && !mapIdtoUserObj.isEMpty()){
                try{
                    assignOwnerAndProxyOwner(mapIdtoUserObj ,qsrObj,qsrObj.Originating_Record_Owner__c , setIdUserIdwithRead);
                   }Catch(Exception ex){
                    System.debug(ex);
                }
            }
        }
    }
    
    
    
    /**
*  @author Digvijay
*  @description - To be executed, when the QSR is updated. 
*               
**/
    public override void onBeforeUpdate(Map<Id, SObject> oldRecords){
        set<Id> setUserId = new set<Id>();
        Map<Id,User> mapUser = new Map<Id,User>();
        
        for(Qualtrics_Survey_Response__c qsrObj:(List<Qualtrics_Survey_Response__c>)records){

            Qualtrics_Survey_Response__c oldqsrObj =(Qualtrics_Survey_Response__c)oldRecords.get(qsrObj.id);
            
            //Remove Proxy on update of ownership.
            if(qsrObj.OwnerId != oldqsrObj.OwnerId || 
            (QSR_OPEN_STATUSES.Contains(qsrObj.status__c) && !QSR_OPEN_STATUSES.Contains(oldqsrObj.status__c)) 
             ){
                qsrObj.Proxy_Owner__c = Null;
                setUserId.add(qsrObj.OwnerId);
            }
        }
        
        if(!setUserId.IsEmpty()){
            mapUser = new Map<Id,User>(new UsersSelector().selectByUserId(setUserId));
        }
        
        //update the status and Date when Qualtrics record is updated 
        
        for(Qualtrics_Survey_Response__c qsrObj:(List<Qualtrics_Survey_Response__c>)records){
            Qualtrics_Survey_Response__c oldqsrObj =(Qualtrics_Survey_Response__c)oldRecords.get(qsrObj.id);
            
            if(oldqsrObj.Status__c==Label.QSRStatusInitiated && qsrObj.Status__c!=Label.QSRStatusInitiated){
                qsrObj.Date_Review_Initiated__c=Date.Today();
            }
            
            if(qsrObj.Status__c==Label.QSRStatusClosed_CaseCreated || 
               qsrObj.Status__c==Label.QSRStatusClosed_ReopenedOriginalRecord ||
               qsrObj.Status__c==Label.QSRStatusClosed_ReopenedAnotherExistingRecord   || 
               qsrObj.Status__c==Label.QSRStatusClosed_NotaComplaint || 
               qsrObj.Status__c==Label..QSRStatusClosed_FalsePositive || 
               qsrObj.Status__c==Label.QSRStatusClosed_NoCustomerResponse){
                   qsrObj.Date_Review_Completed__c=Date.Today();
               }
            
            //Check New owner's Proxy User for assignment.
            if( setUserId.contains(qsrObj.ownerId) && mapUser.containsKey(qsrObj.OwnerId) 
            && mapUser.get(qsrObj.OwnerId).Out_of_Office__c && String.isNotBlank(mapUser.get(qsrObj.OwnerId).DelegatedApproverId) 
            ){
                qsrObj.Proxy_Owner__c = mapUser.get(qsrObj.OwnerId).DelegatedApproverId;
            }
	//Added logic to count reopen - DCP-39027
                if(QSR_OPEN_STATUSES.contains(qsrObj.Status__c) && !QSR_OPEN_STATUSES.contains(oldqsrObj.Status__c)){
                    if(qsrObj.QSR_Reopen_Count__c == Null){
                        qsrObj.QSR_Reopen_Count__c = 0;
                    }
                    qsrObj.QSR_Reopen_Count__c = qsrObj.QSR_Reopen_Count__c+1;
                }
        }
    }

    
    /**
    *  @author Vignesh
    *  @description - Method to execute on After insert. 
    *               
    **/
    public override void onAfterInsert(){
        QualtricsSurveyResponseShareService.updateQSRShareBasedOnProxy((List<Qualtrics_Survey_Response__c>)records, Null);
    }
    
    /**
    *  @author Vignesh
    *  @description - Method to execute on After Update. 
    *               
    **/
    public override void onAfterUpdate(Map<Id, SObject> oldRecords){
        QualtricsSurveyResponseShareService.updateQSRShareBasedOnProxy((List<Qualtrics_Survey_Response__c>)records, (Map<Id, Qualtrics_Survey_Response__c>) oldRecords);
    }

    /**
    *  @author Vignesh
    *  @description - Method to Update Share QSR Record. DCP-37395.
    *  @return type void            
    **/
    public void assignOwnerAndProxyOwner(Map<Id,User> mapIdtoUserObj ,Qualtrics_Survey_Response__c qsrObj , Id userId, set<string> setIdUserIdwithRead){
        if(mapIdtoUserObj.containsKey(userId) && !String.IsBlank(mapIdtoUserObj.get(UserId).ManagerId) && setIdUserIdwithRead.Contains(mapIdtoUserObj.get(UserId).ManagerId)){
            qsrObj.ownerId = mapIdtoUserObj.get(UserId).ManagerId;
            
            if(mapIdtoUserObj.get(userId).Manager.Out_of_Office__c && mapIdtoUserObj.get(userId).Manager.DelegatedApproverId != Null && QSR_OPEN_STATUSES.Contains(qsrObj.status__c) ){
                qsrObj.Proxy_Owner__c = mapIdtoUserObj.get(userId).Manager.DelegatedApproverId;
            }
        }
    }
    
    
    /**
*  @author Digvijay Singh
*  @description - To get the List of Permisions set Id's which are assigned to the user . 
*               
**/ 
    
    public map<String,List<String>> getAssignedPermissionSet(map<String,List<String>> mapuserIdtoProfileNPermSet ){
        
        List<PermissionSetAssignment> lstPermSetAssignment =[SELECT PermissionSet.Name, PermissionSet.Id,AssigneeId  from PermissionSetAssignment  WHERE AssigneeId IN :mapuserIdtoProfileNPermSet.keySet()];
        
        for(PermissionSetAssignment obj:lstPermSetAssignment){
            
            if(mapuserIdtoProfileNPermSet!=null && mapuserIdtoProfileNPermSet.containsKey(obj.AssigneeId)){
                mapuserIdtoProfileNPermSet.get(obj.AssigneeId).add(obj.PermissionSet.Id);
            }else{
                mapuserIdtoProfileNPermSet.put(obj.AssigneeId,new List<String>{obj.PermissionSet.Id});
            }
            
        }
        
        return mapuserIdtoProfileNPermSet;
        
    }
    
    /**
*  @author Digvijay Singh
*  @description - To get the List of Profile and Permisions set Id's where the Sobject has Read Permission . 
*               
**/ 
    public Set<String> getProfileNPermSet(String sobjectApi){
        
        Set<String> setIdProfileNPerm=new Set<String>();
        
        List<PermissionSet> lstPermSet=[SELECT Id,Profile.Id,Profile.Name,Name , IsOwnedByProfile FROM PermissionSet WHERE  Id IN (
            SELECT ParentId FROM ObjectPermissions
            WHERE PermissionsRead = true and PermissionsEdit=true
            AND SObjectType =:sobjectApi)];
        
        for(PermissionSet obj:lstPermSet){
            if(obj.IsOwnedByProfile==true){
                setIdProfileNPerm.add(obj.Profile.Id);
            }else{
                setIdProfileNPerm.add(obj.Id);
            }
            
        }  
        
        return   setIdProfileNPerm;                                    
        
    }
    
    /**
*  @author Digvijay Singh
*  @description - To get the List of Users who has read Permission on a Sobject  . 
*               
**/ 
    public set<String> getuserIdwithReadPerm(map<String,List<String>> mapuserIdtoProfileNPermSet ,set<String> setIdProfileNPermwithRead){
        
        Set<String> setUserIdwithReadPerm=new set<String>();
        
        
        if(mapuserIdtoProfileNPermSet!=null && setIdProfileNPermwithRead!=null ){
            for(String strKey:mapuserIdtoProfileNPermSet.keySet()){
                
                for(String permSetId:mapuserIdtoProfileNPermSet.get(strKey)){
                    
                    if(setIdProfileNPermwithRead.contains(permSetId)){
                        
                        setUserIdwithReadPerm.add(strKey);
                        break;
                    }
                }
            }
            
        }  
        
        return setUserIdwithReadPerm;
    }
}