public abstract with sharing class CDCTriggerProcessHandler {
    protected Map<String, List<EventBus.ChangeEventHeader>> filteredEventsByOperationTypes = new Map<String, List<EventBus.ChangeEventHeader>>();
    protected Map<String, List<EventBus.ChangeEventHeader>> allEventsByOperationTypes = new Map<String, List<EventBus.ChangeEventHeader>>();
    protected SObjectType recordSObjectType;
    //Event Types
    protected final String CDC_CHANGE_TYPE_CREATE = 'CREATE';
    protected final String CDC_CHANGE_TYPE_UPDATE = 'UPDATE';
    protected final String CDC_CHANGE_TYPE_DELETE = 'DELETE';
    protected final String CDC_CHANGE_TYPE_UNDELETE = 'UNDELETE';

    //Virtual methods 
    public virtual void handleCreate(Set<Id> recordIds) {
    }
    public virtual void handleUpdate(Set<Id> recordIds) {
    }
    public virtual void handleDelete(Set<Id> recordIds) {
    }
    public virtual void handleUndelete(Set<Id> recordIds) {
    }
    public virtual void executeLast() {
    }
    public virtual Set<String> getTriggerControllingFields() {
        return new Set<String>();
    }

    public void run() {
        this.init();
        this.runHandleMethods();
        this.executeLast();
    }

    private void init() {
        Boolean checkChangedFields = Sets.isNotEmpty(this.getTriggerControllingFields());

        for (SObject event : Trigger.new) {
            EventBus.ChangeEventHeader header = (EventBus.ChangeEventHeader) event.get(
                'ChangeEventHeader'
            );

            if (null == this.recordSObjectType && String.isNotBlank(header?.getEntityName())) {
                this.recordSObjectType = Schema.getGlobalDescribe().get(header?.getEntityName());
            }

            //Set All events By operation Type
            if (!this.allEventsByOperationTypes.containsKey(header?.getChangeType())) {
                this.allEventsByOperationTypes.put(
                    header.getChangeType(),
                    new List<EventBus.ChangeEventHeader>()
                );
            }
            this.allEventsByOperationTypes.get(header?.getChangeType()).add(header);

            //Filter Events By operation Type
            if (
                header == null ||
                (header.getChangeType() == this.CDC_CHANGE_TYPE_UPDATE &&
                checkChangedFields &&
                !this.areSomeRequiredFieldValuesChanged(header))
            ) {
                continue;
            }

            if (!this.filteredEventsByOperationTypes.containsKey(header.getChangeType())) {
                this.filteredEventsByOperationTypes.put(
                    header.getChangeType(),
                    new List<EventBus.ChangeEventHeader>()
                );
            }

            this.filteredEventsByOperationTypes.get(header.getChangeType()).add(header);
        }
    }

    private void runHandleMethods() {
        if (this.isEventCreate()) {
            this.handleCreate(
                this.getEventRecordIds(
                    this.filteredEventsByOperationTypes.get(CDC_CHANGE_TYPE_CREATE)
                )
            );
        }

        //Can check additional changed event fields from 'allEventsByOperationTypes'
        this.handleUpdate(
            this.getEventRecordIds(this.filteredEventsByOperationTypes.get(CDC_CHANGE_TYPE_UPDATE))
        );

        if (this.isEventDelete()) {
            this.handleDelete(
                this.getEventRecordIds(
                    this.filteredEventsByOperationTypes.get(CDC_CHANGE_TYPE_DELETE)
                )
            );
        }

        if (this.isEventUndelete()) {
            this.handleUndelete(
                this.getEventRecordIds(
                    this.filteredEventsByOperationTypes.get(CDC_CHANGE_TYPE_UNDELETE)
                )
            );
        }
    }

    protected Set<Id> getEventRecordIds(EventBus.ChangeEventHeader eventHeader) {
        return this.getEventRecordIds(new List<EventBus.ChangeEventHeader>{ eventHeader });
    }

    protected Set<Id> getEventRecordIds(List<EventBus.ChangeEventHeader> eventHeaders) {
        Set<Id> recordIds = new Set<Id>();

        if (Lists.isEmpty(eventHeaders)) {
            return recordIds;
        }

        for (EventBus.ChangeEventHeader header : eventHeaders) {
            for (String recordId : header?.getRecordIds()) {
                recordIds.add(Id.valueOf(recordId));
            }
        }

        return recordIds;
    }

    protected Boolean areSomeRequiredFieldValuesChanged(EventBus.ChangeEventHeader eventHeader) {
        return this.areSomeRequiredFieldValuesChanged(
            eventHeader,
            this.getTriggerControllingFields()
        );
    }

    protected Boolean areSomeRequiredFieldValuesChanged(
        EventBus.ChangeEventHeader eventHeader,
        Set<String> fieldsToCheck
    ) {
        if (null == eventHeader) {
            return false;
        }
        Set<String> intersectionSet = new Set<String>(eventHeader?.getChangedFields());
        intersectionSet.retainAll(fieldsToCheck);

        return Sets.isNotEmpty(intersectionSet);
    }

    protected Boolean isEventCreate() {
        return this.filteredEventsByOperationTypes.containsKey(this.CDC_CHANGE_TYPE_CREATE) &&
            Lists.isNotEmpty(this.filteredEventsByOperationTypes.get(this.CDC_CHANGE_TYPE_CREATE));
    }
    protected Boolean isEventUpdate() {
        return this.filteredEventsByOperationTypes.containsKey(this.CDC_CHANGE_TYPE_UPDATE) &&
            Lists.isNotEmpty(this.filteredEventsByOperationTypes.get(this.CDC_CHANGE_TYPE_UPDATE));
    }
    protected Boolean isEventDelete() {
        return this.filteredEventsByOperationTypes.containsKey(this.CDC_CHANGE_TYPE_DELETE) &&
            Lists.isNotEmpty(this.filteredEventsByOperationTypes.get(this.CDC_CHANGE_TYPE_DELETE));
    }
    protected Boolean isEventUndelete() {
        return this.filteredEventsByOperationTypes.containsKey(this.CDC_CHANGE_TYPE_UNDELETE) &&
            Lists.isNotEmpty(
                this.filteredEventsByOperationTypes.get(this.CDC_CHANGE_TYPE_UNDELETE)
            );
    }
}
