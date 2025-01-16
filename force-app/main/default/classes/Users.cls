/* 
* @ Author       : Vignesh
* @ date         : 12-Jun-2020
* @ Description  : Trigger Handler for User object.
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* Vignesh               12-Jun-2020                  DCP-37395        Logic for updating Delegated Approver Fields.
* Anand Palla           26-Apr-2022                                   CodeScan Fix-Avoid Literals in If condition
* Aman Tyagi            31-mar-2022                                   CodeScan Fixes
* ---------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class Users extends ilib_SObjectDomain {
    
    //START CodeScan Fix [Avoid Literals in If condition]
    private static final String STRING_STANDARD = 'Standard';
    //END CodeScan Fix

    /**
    * @description initialise users
    * @author 
    * @param sObjectList 
    **/
    public Users (List<User> sObjectList)
    {
        super(sObjectList);
    }

    /*
    * @Author:Vignesh
    * @Description : constructor class 
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /**
        * @description 
        * @author returns users
        * @param sObjectList 
        * @return ilib_SObjectDomain 
        **/
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new Users(sObjectList);
        }
    }

     /*
    Author : Vignesh
    Description : Method to Perform After Update Operations.Added for DCP-37395.
    ReturnType : Void
    */
    public override void onAfterupdate(Map<Id, SObject> mapOld){
        Map<Id,Id> mapOOOEnabledUser = new Map<Id,Id>();
        List<Id> lstOOODisabledUser = new List<Id>();
        
        Map<Id,user> oldMap = (Map<Id,user>)mapOld;

        for (User objUser : (List<User>)records){
            User oldUser = oldMap.get(objUser.Id);
            
            //Checking for Out of office Checkbox checked or Delegated Approver Updated scenario.
            if ( objUser.Out_of_Office__c && (objUser.Out_of_Office__c != oldUser.Out_of_Office__c  ||
                objUser.DelegatedApproverId != oldUser.DelegatedApproverId)){
                mapOOOEnabledUser.put(objUser.Id,objUser.DelegatedApproverId);
            }
            
            //Checking for Out of office Checkbox unchecked.
            if(objUser.Out_of_Office__c != oldUser.Out_of_Office__c && !objUser.Out_of_Office__c){
                lstOOODisabledUser.add(objUser.Id);
            }
        }
        
        //Added as part of DCP-37395 for Triggering batch to update Proxy.
        if(!mapOOOEnabledUser.isEmpty() || !lstOOODisabledUser.isEmpty() )
            Database.executeBatch(new BatchUpdateProxyInQSR(mapOOOEnabledUser,lstOOODisabledUser ));
    }
    
    /*
    Author : Vignesh
    Description : Method to Perform Before Update Operations.
    ReturnType : Void
    */
    public override void onBeforeupdate(Map<Id, SObject> mapOld){
        //Added as part of DCP-37395 for validating Delegated Approver on OOO.
        list<user> lstUserToCheck = new list<user>();
        set<Id> setDelegatedApprovers = new set<Id>();
        Channel_Partner_Profile_Settings__c cp = Channel_Partner_Profile_Settings__c.getInstance(Userinfo.getProfileID());
        Map<Id,user> oldMap = (Map<Id,user>)mapOld;
        
        for (User objUser : (List<User>)records){
            User oldUser = oldMap.get(objUser.Id);
        //DCP-46051: Populating Previous Profile Id in User object when Profile is changing.
		if(Feature.isOn('UpdateUserRecord') && !cp.Is_Channel_Partner__c){
            if((objUser.ProfileId!=oldUser.ProfileId && objUser.IsActive) ||(objUser.ProfileId!=oldUser.ProfileId && !objUser.IsActive) || (objUser.ProfileId==oldUser.ProfileId && !objUser.IsActive && objUser.ProfileId != Label.ProfileIdNoAccess)){//prevent Previous_Profile_ID__c update if current profile is No Access
                objUser.Previous_Profile_ID__c = oldUser.ProfileId;
              }
			}
            if (objUser.Out_of_Office__c && String.isBlank(objUser.DelegatedApproverId) ){    
                objUser.addError(System.Label.QSR_Delegated_Approver_Error_Msg_On_OOO);
            }else{
                //Checking Delegated users on OOO and delegated Approver Update. 
                if ( objUser.Out_of_Office__c && (objUser.Out_of_Office__c != oldUser.Out_of_Office__c  ||
                    objUser.DelegatedApproverId != oldUser.DelegatedApproverId)){
                    setDelegatedApprovers.add(objUser.DelegatedApproverId);
                    lstUserToCheck.add(objUser);
                }
            }
        }
        //Added as part of DCP-37395. Method to update Delegated user.
        updateDelegatedApproverFields((List<user>)records , (Map<Id,user>)mapOld );
        //Method to check for Delegated Approver Access in QSR.
        if(!lstUserToCheck.isEmpty()){
            checkDelegatedApproverAccessinQSR(lstUserToCheck, setDelegatedApprovers );
        }
        
    }
        
             
    /**
    * @description Method to Perform After Insert Operations.
    * @author 
    **/
    public override void onAfterInsert()
    {
        set <Id> setUsers = new Set<Id>();
        for (User objUser : (List<User>)records)
        {
            if (objUser.userType == STRING_STANDARD)
                setUsers.add(objUser.Id);
            if(System.Test.isRunningTest())
                setUsers.add(objUser.Id);
        }
        if(!setUsers.isEmpty() && !(System.Test.isRunningTest() && System.isFuture()))
        Database.executeBatch(new ScheduledBatchSailPointUserSync(setUsers));
    }

    /*
    Author : Vignesh
    Description : Method to Perform Before Insert Operations.
    ReturnType : Void
    */
    public override void onBeforeInsert(){
        //Added as part of DCP-37395
        updateDelegatedApproverFields((List<User>)records,null);
    }
    
    /*
    Author : Vignesh
    Name : updateDelegatedApproverFields
    Description : Method to Assign Delegated Approver related fields - DCP-37395.
    ReturnType : Void
    */
    public void updateDelegatedApproverFields( list<user> lstUser , Map<Id,User> oldMap ){
        Map<Id,User> mapDelegatedUserId = new Map<Id,User>();
        Map<Id,User> mapUpdatedDelegatedUser = new Map<Id,User>();
        
        //Method to Check User Details
        mapDelegatedUserId = getDelegatedApproversToUpdate(lstUser, oldMap, mapDelegatedUserId , mapUpdatedDelegatedUser);
        
        //Assigning Delegated Approver fields - DCP-37395
        if(!mapUpdatedDelegatedUser.isEmpty()){
            for (User objUser : mapUpdatedDelegatedUser.values()){
                if(mapDelegatedUserId.containsKey(objUser.DelegatedApproverId)){
                    objUser.Delegated_Approver_Email__c = mapDelegatedUserId.get(objUser.DelegatedApproverId).Email;
                    objUser.Delegated_Approver_Name__c = mapDelegatedUserId.get(objUser.DelegatedApproverId).Name;
                }
            }
        }
    }
    
    /*
    Author : Vignesh
    Name : checkDelegatedApproverAccessinQSR
    Description : Method to Assign Delegated Approver related fields - DCP-37395.
    ReturnType : Void
    */
    public void checkDelegatedApproverAccessinQSR( list<user> lstUserToCheck , set<Id> setDelegatedApprovers ){
        set<String> setIdProfileNPermwithRead = new set<String>();
        set<String> setIdUserIdwithRead = new set<String>();
        Map<String,List<String>> mapuserIdtoProfileNPermSet = new Map<String,List<String>>();
        Map<Id,User> mapDelegatedUserId = new Map<Id,User>();
        
        if(!setDelegatedApprovers.isEmpty()){
            mapDelegatedUserId = new Map<Id,User>(new UsersSelector().selectByUserId(setDelegatedApprovers));
        }

        //Checking Delegated Approver Access for QSR object.
        if(!lstUserToCheck.isEmpty()){
            QualtricsSurveyResponses objQualtricsSurveyResponses = new QualtricsSurveyResponses(new list<Qualtrics_Survey_Response__c>());
            //Getting all profiles and perm. set having access to QSR.
            setIdProfileNPermwithRead = objQualtricsSurveyResponses.getProfileNPermSet('Qualtrics_Survey_Response__c');
            
            for(User obj : lstUserToCheck){
                //Checking QSR access for the delegated User's profile.
                if( mapDelegatedUserId.containsKey(obj.DelegatedApproverId) && setIdProfileNPermwithRead.contains(mapDelegatedUserId.get(obj.DelegatedApproverId).ProfileId)){
                    setIdUserIdwithRead.add(obj.Id);
                }else{
                    mapuserIdtoProfileNPermSet.put(obj.DelegatedApproverId, new List<String>{mapDelegatedUserId.get(obj.DelegatedApproverId).ProfileId});
                }
            }
            
            if(!mapuserIdtoProfileNPermSet.IsEmpty() && !setIdProfileNPermwithRead.IsEmpty()){
                //Extracting all Per. set of delegated user.
                mapuserIdtoProfileNPermSet = objQualtricsSurveyResponses.getAssignedPermissionSet(mapuserIdtoProfileNPermSet);
                //List of users with QSR access collected.
                setIdUserIdwithRead.addAll(objQualtricsSurveyResponses.getuserIdwithReadPerm(mapuserIdtoProfileNPermSet,setIdProfileNPermwithRead));
                //Error on Missing QSR Access.
                for (User objUser : lstUserToCheck){
                    if(String.isNotBlank(objUser.DelegatedApproverId) && !setIdUserIdwithRead.contains(objUser.DelegatedApproverId)){
                        objUser.addError(system.label.Delegated_Approver_Lack_QSR_Access);
                    }
                }
            }
        }
    }

    /*
    Author : Vignesh
    Name : getDelegatedApproversToUpdate
    Description : Method to get DelagatedApprovers email/Name - DCP-37395.
    ReturnType : Void
    */
    public Map<Id,User> getDelegatedApproversToUpdate(list<user> lstUser, Map<Id,User> oldMap, Map<Id,User> mapDelegatedUserId, Map<Id,User> mapUpdatedDelegatedUser ){
        set<Id> setDelegatedApprovers = new set<Id>();
        
        for(user objUser : lstUser){
            User oldUser = oldMap != Null ? oldMap.get(objUser.Id) : Null;
            Boolean isDelegatedApproverUpdated = oldUser != Null && objUser.DelegatedApproverId != oldUser.DelegatedApproverId ? True : False;
            Boolean isOOOUpdated = oldUser != Null && objUser.Out_of_Office__c != oldUser.Out_of_Office__c ? True : False;

            //Upadting Delegated Approver Name/Email Fields on update of delegated Approver.
            if((oldUser == Null && String.isNotBlank(objUser.DelegatedApproverId)) || isDelegatedApproverUpdated || isOOOUpdated ){

                if(String.isNotBlank(objUser.DelegatedApproverId) ){
                    setDelegatedApprovers.add(objUser.DelegatedApproverId);
                    mapUpdatedDelegatedUser.put(objUser.Id,objUser);
                }else{
                    objUser.Delegated_Approver_Email__c = Null;
                    objUser.Delegated_Approver_Name__c = Null;
                }
                
                //Updating Removed Delegated Approver EMail/Name fields on updaing during OOO.
                if((isDelegatedApproverUpdated && objUser.Out_of_Office__c) || (!objUser.Out_of_Office__c && isOOOUpdated)){
                    objUser.Removed_Delegated_Approver_Email__c = oldUser.Delegated_Approver_Email__c;
                    objUser.Removed_Delegated_Approver_Name__c = oldUser.Delegated_Approver_Name__c;
                }
            }
        }

        if(!setDelegatedApprovers.isEmpty()){
            mapDelegatedUserId = new Map<Id,User>(new UsersSelector().selectByUserId(setDelegatedApprovers));
        }
        return mapDelegatedUserId;
    }
}