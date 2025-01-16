trigger InterfaceCallTrigger on Interface_Call__e (after insert) {

    ilib_SObjectDomain.triggerHandler(InterfaceCalls.class);

}