/*
 * @Author : Sravan Kumar Panchangam
 * @Description : DCP-9865 ASOP Integration 
 * @Date:2018-09-27
*/
trigger ApttusOrdersTrigger on Apttus_Config2__Order__c (before insert, before update, after insert, after update)
{
    ilib_SObjectDomain.triggerHandler(ApttusOrders.class);
}