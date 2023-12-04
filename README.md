# CDC-Trigger-Handler

## Use case
```java
public abstract with sharing class CDCTriggerHandlerAbstract extends CDCTriggerProcessHandler {
    private Set<SObject> recordsToUpdate = new Set<SObject>();

    public virtual override void handleCreate(Set<Id> recordIds) {
      //Do something
    }

    public virtual override void handleUpdate(Set<Id> recordIds) {
     //Do something
    }

    public virtual override void handleDelete(Set<Id> recordIds) {
     //Do something
    }

    public virtual override void executeLast() {
        if (this.recordsToUpdate.isEmpty()) {
            return;
        }

        Database.update(new List<SObject>(this.recordsToUpdate), false);
    }
}
```
