import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getLeaveTypes from '@salesforce/apex/LeaveApplicationController.getLeaveTypes';
import getVacationBalance from '@salesforce/apex/LeaveApplicationController.getVacationBalance';
import createLeaveApplication from '@salesforce/apex/LeaveApplicationController.createLeaveApplication';
import USER_ID from '@salesforce/user/Id';

export default class ApplicationForLeave extends LightningElement {
    @track startDate;
    @track endDate;
    @track typeOfLeave;
    @track vacationBalance;
    @track leaveTypes = [];

    @wire(getLeaveTypes)
    wiredLeaveTypes({ error, data }) {
        if (data) {
            this.leaveTypes = data.map(type => {
                return { label: type, value: type };
            });
        } else if (error) {
            this.showToast('Error', 'Error loading leave types', 'error');
        }
    }

    connectedCallback() {
        this.loadVacationBalance();
    }

    loadVacationBalance() {
        getVacationBalance()
            .then(result => {
                this.vacationBalance = result;
            })
            .catch(error => {
                this.showToast('Error', 'Error fetching vacation balance', 'error');
            });
    }

    handleInputChange(event) {
        const field = event.target.dataset.id;
        if (field === 'startDate') {
            this.startDate = event.target.value;
        } else if (field === 'endDate') {
            this.endDate = event.target.value;
        } else if (field === 'typeOfLeave') {
            this.typeOfLeave = event.target.value;
        }
    }

    handleSubmit() {
        if (this.isFormValid()) {
            createLeaveApplication({
                employeeId: USER_ID,
                startDate: this.startDate,
                endDate: this.endDate,
                typeOfLeave: this.typeOfLeave,
            })
                .then(() => {
                    this.showToast('Success', 'Leave application submitted successfully', 'success');
                    this.clearFields();
                    this.loadVacationBalance();
                })
                .catch(error => {
                    this.showToast('Error', 'Error submitting leave application', 'error');
                });
        } else {
            this.showToast('Error', 'Please fill all required fields', 'error');
        }
    }

    isFormValid() {
        const allValid = [...this.template.querySelectorAll('lightning-input, lightning-combobox')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
        return allValid;
    }

    clearFields() {
        this.startDate = null;
        this.endDate = null;
        this.typeOfLeave = null;
        this.reason = null;
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(event);
    }
}