/**
 *    @author KD
 *    @date   18-June-20020
 *    @description    Class to get the Profile records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *      Developer                      Date                Description
 *      Saddam                      11-Apr-22              Added constructor method to class.
 *      Gerardo Garcia              10-Nov-23              Add profile names static strings.
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class ProfilesSelector extends ilib_SObjectSelector{
    public static final String PROFILE_SALES = 'Sales User';
    public static final String PROFILE_COMM_OPS = 'Commercial Ops Quoting User';
/*
    * @author Saddam
    * @date 11-APR-22   
    */
    
     /*Constructor */

     public ProfilesSelector()

     {
 
         super(false, false, false, false);
   
 
     } 
    
    
    /*
    * @author Kushagra Desai
    * @date   
    * @description  set select fields
    */
    public List<Schema.SObjectField> getSObjectFieldList()
    {	
        return new List<Schema.SObjectField> {
            Profile.Name,
            Profile.id
        };
    }

    /*
    * @author Kushagra Desai
    * @description  describe the object
    *
    */
    public Schema.SObjectType getSObjectType()
    { 
        return Profile.sObjectType;
    }
    /**
     * @author :Kushagra Desai
     * @description return all Profile by name
     * Returns List<Profile> sObject Record 
     **/
    public List<Profile> getProfileByName(Set<String> setProfileName)
    {
        return (List<Profile>)Database.query(newQueryFactory().setCondition('Name IN :setProfileName').toSOQL());
    }
	/**
     * @author :Prashanth
     * @description return Profile Name by Id
     * Returns List<Profile> sObject Record 
     **/
    public List<Profile> getProfilesById(Set<Id> setProfileId)
    {
        return (List<Profile>)Database.query(newQueryFactory().setCondition('Id IN :setProfileId').toSOQL());
    }
}