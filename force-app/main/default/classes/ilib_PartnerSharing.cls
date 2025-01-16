/**
 *    @author KD
 *    @date   5-Nov-2020
 *    @description : Implementer class for partner sharing framework
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                  Description
  *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing abstract class ilib_PartnerSharing implements ilib_ShareFactory,Queueable{
    public Set<Id> setPartnerUserId;
    /**
    *    @author KD
    *    @date  5-Nov-2020
    *    @description execute method for Queueable
    */
    public void execute(QueueableContext context){
        deleteShareRecords();
        runBusinessSharingLogic();
    }
    /**
    *    @author KD
    *    @date  5-Nov-2020
    *    @description method to set user id of updated/created user on new instance of object.
    */
    public ilib_PartnerSharing setUserId(Set<Id> setUserId){
        System.debug('Inside ilib_PartnerSharing setUserId= '+setUserId);
        ilib_PartnerSharing obj = getInstance();
        obj.setPartnerUserId = setUserId;
        return obj;
    }
    /*
    * Description : Abstract method to return object type
    // Must be implemented in derived class
    */
    public abstract SObjectType getShareObjectType();
    /*
    * Description : Abstract method to return share object parent name
    // Must be implemented in derived class
    */
    public abstract String getShareParentFieldName();
    /*
    * Description : Abstract method for business logic
    // Must be implemented in derived class
    */
    public abstract void runBusinessSharingLogic();
     /*
    * Description : Abstract method to get instance of class
    // Must be implemented in derived class
    */
    public abstract ilib_PartnerSharing getInstance();
    /**
    *    @author KD
    *    @date  5-Nov-2020
    *    @description method to delete existing sharing for recalculation
    */
    public void deleteShareRecords(){
        List<Sobject> lstShareObj = new TAPS_ShareSelector((ilib_ShareFactory)getInstance()).selectManualByParentId(setPartnerUserId);
        System.debug('Delete Share Records-->'+lstShareObj);
        if(!lstShareObj.isEmpty())
            delete lstShareObj;
    }
}