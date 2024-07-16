public class LeaveApplicationTriggerHandler {
    
    public static void updateBalance(List<Leave_Application__c> newLeaves) {
        Set<Date> germanHolidays = getGermanHolidays();
        
        Set<Id> employeeIds = new Set<Id>();
        for (Leave_Application__c leave : newLeaves) {
            if (leave.Employee__c != null) {
                employeeIds.add(leave.Employee__c);
            }
        }
        
        Map<Id, User> employeeToManagerMap = new Map<Id, User>();
        for (User user : [SELECT Id, ManagerId,Vacation_Balance__c FROM User WHERE Id IN :employeeIds]) {
            employeeToManagerMap.put(user.Id, user);
        }
        
        for (Leave_Application__c leave : newLeaves) {
            Date startDate = leave.Start_Date__c;
            Date endDate = leave.End_Date__c;
            
            // Check if start date or end date is a German holiday
            if (germanHolidays.contains(startDate) || germanHolidays.contains(endDate)) {
                leave.addError('Start and/or End date cannot be on a German holiday.');
                continue; // Skip further processing for this record
            }
            
            // Populate Manager Id
            if (leave.Employee__c != null && employeeToManagerMap.containsKey(leave.Employee__c)) {
                leave.Manager__c = employeeToManagerMap.get(leave.Employee__c).ManagerId;
            }
            
            Integer weekdaysCount = 0;
            Date currentDate = startDate;
            
            while (currentDate <= endDate) {
                if (isWeekday(currentDate) && !germanHolidays.contains(currentDate)) {
                    weekdaysCount++;
                }
                currentDate = currentDate.addDays(1);
            }
            
            if (weekdaysCount > 15) {
                leave.addError('Leave cannot exceed 15 working days.');
            } else {
                leave.Balance__c = weekdaysCount;
                leave.Initial_Balance__c = employeeToManagerMap.get(leave.Employee__c).Vacation_Balance__c;
            }
        }
    }
    
    private static Boolean isWeekday(Date dat) {
        Datetime dt = DateTime.newInstance(dat.year(), dat.month(), dat.day());
        String dayOfWeekString = dt.format('EEEE');
        return !dayOfWeekString.equals('Saturday') && !dayOfWeekString.equals('Sunday');
    }
    
    private static Set<Date> getGermanHolidays() {
        Set<Date> germanHolidays = new Set<Date>();
        for (German_Holiday__c holiday : [SELECT Holiday_Date__c FROM German_Holiday__c]) {
            germanHolidays.add(holiday.Holiday_Date__c);
        }
        return germanHolidays;
    }
    
    public static void CalcafterBalance(List<Leave_Application__c> newLeaves,Map<Id, Leave_Application__c> oldLeavesMap){
        Map<Id, Decimal> employeeToVacationBalance = new Map<Id, Decimal>();
        
        for (Leave_Application__c leave : newLeaves) {
            Leave_Application__c oldLeave = oldLeavesMap.get(leave.Id);
            
            if (leave.Status__c == 'Approved' && oldLeave.Status__c != 'Approved') {
                
                Decimal afterBalance = leave.Initial_Balance__c - leave.Balance__c;
                
                if (afterBalance < 0) {
                    leave.addError('After balance cannot be less than 0.');
                    continue;
                }
                
                leave.After_Balance__c = afterBalance;
                
                if (!employeeToVacationBalance.containsKey(leave.Employee__c)) {
                    employeeToVacationBalance.put(leave.Employee__c, afterBalance);
                } else {
                    employeeToVacationBalance.put(leave.Employee__c, employeeToVacationBalance.get(leave.Employee__c) + afterBalance);
                }
            }
        }
        List<User> usersToUpdate = new List<User>();
        for (Id employeeId : employeeToVacationBalance.keySet()) {
            User user = new User(Id = employeeId);
            user.Vacation_Balance__c = Math.max(employeeToVacationBalance.get(employeeId), 0); // Ensure balance doesn't go below 0
            usersToUpdate.add(user);
        }
        
        if (!usersToUpdate.isEmpty()) {
            update usersToUpdate;
        }
    }
    
    public static void ERPUpdate(List<Leave_Application__c> newLeaves,Map<Id, Leave_Application__c> oldLeavesMap){
        for (Leave_Application__c leave : newLeaves) {
        Leave_Application__c oldLeave = oldLeavesMap.get(leave.Id);
        if (leave.Status__c == 'Approved' && oldLeave.Status__c != 'Approved') {
            updateVacationBalance(leave.Employee__c);
        }
    }
    }
    
    @future(callout=true)
    public static void updateVacationBalance(Id employeeId) {
        try {
            User user = [SELECT Id, Email, Vacation_Balance__c FROM User WHERE Id = :employeeId LIMIT 1];
            
            if (user == null) {
                System.debug('User not found for Id: ' + employeeId);
                return;
            }

            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://www.sap.com/api/vacationBalance');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody('{"email": "' + user.Email + '", "vacationBalance": ' + user.Vacation_Balance__c + '}');

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                System.debug('SAP system updated successfully');
            } else {
                System.debug('Failed to update SAP system: ' + res.getStatusCode() + ' ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('An error occurred: ' + e.getMessage());
        }
    }
}