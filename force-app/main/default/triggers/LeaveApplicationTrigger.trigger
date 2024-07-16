trigger LeaveApplicationTrigger on Leave_Application__c (before insert, before update,after update) {

    if(Trigger.isInsert && Trigger.isBefore){
        LeaveApplicationTriggerHandler.updateBalance(Trigger.New);
    }
    
    if(Trigger.isUpdate && Trigger.isbefore){
        system.debug('inside');
        LeaveApplicationTriggerHandler.CalcafterBalance(Trigger.New,Trigger.oldmap);
        LeaveApplicationTriggerHandler.ERPUpdate(Trigger.New,Trigger.oldmap);
    }

}