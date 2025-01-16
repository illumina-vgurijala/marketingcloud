/**
 * Created by tnewman on 2018-11-28.
 */

trigger ApttusFavoriteConfigurationTrigger on Apttus_Config2__FavoriteConfiguration__c (after insert, after update) {
    ilib_SObjectDomain.triggerHandler(ApttusFavoriteConfigurations.class);
}