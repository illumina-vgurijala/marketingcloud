trigger UserTrigger on User (after insert,after update,before Update,Before Insert) {

    ilib_SObjectDomain.triggerHandler(Users.class);

}