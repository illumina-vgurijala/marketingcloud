trigger UserTerritory2AssociationTrigger on UserTerritory2Association (after insert, after update, after delete)
{
    ilib_SObjectDomain.triggerHandler(UserTerritory2Associations.class);
}