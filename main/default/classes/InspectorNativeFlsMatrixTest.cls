@IsTest
private class InspectorNativeFlsMatrixTest {
    @IsTest
    static void getFieldPermissionMatrixReturnsPermissionableFieldsAndExistingGrants() {
        PermissionSet permissionSet = new PermissionSet(Name = 'Test_Fls_Matrix_Set', Label = 'Test FLS Matrix Set');
        insert permissionSet;
        insert new FieldPermissions(
            ParentId = permissionSet.Id,
            SobjectType = 'Opportunity',
            Field = 'Opportunity.Description',
            PermissionsRead = true,
            PermissionsEdit = false
        );
        insert new ObjectPermissions(
            ParentId = permissionSet.Id,
            SobjectType = 'Opportunity',
            PermissionsRead = true,
            PermissionsCreate = true,
            PermissionsEdit = false,
            PermissionsDelete = false,
            PermissionsViewAllRecords = false,
            PermissionsModifyAllRecords = false
        );

        Test.startTest();
        InspectorNativeFlsMatrix.FlsMatrixResult result = InspectorNativeFlsMatrix.getFieldPermissionMatrix('Opportunity');
        Test.stopTest();

        Boolean foundPhoneField = false;
        for (InspectorNativeFlsMatrix.FieldOption option : result.fields) {
            System.assert(String.isNotBlank(option.apiName), 'Every field option should have an apiName');
            System.assert(String.isNotBlank(option.label), 'Every field option should have a label');
            if (option.apiName == 'Description') {
                foundPhoneField = true;
            }
        }
        System.assert(foundPhoneField, 'Description is a permissionable standard field and should be offered');

        Boolean foundPermissionSet = false;
        for (InspectorNativeFieldPermissions.PermissionSetOption option : result.permissionSets) {
            if (option.id == permissionSet.Id) {
                foundPermissionSet = true;
            }
        }
        System.assert(foundPermissionSet, 'The permission set created above should be listed');

        Boolean foundExistingGrant = false;
        for (InspectorNativeFlsMatrix.FlsGrantState grant : result.existingGrants) {
            if (grant.permissionSetId == permissionSet.Id && grant.fieldApiName == 'Description') {
                foundExistingGrant = true;
                System.assertEquals(true, grant.readAccess);
                System.assertEquals(false, grant.editAccess);
            }
        }
        System.assert(foundExistingGrant, 'The existing Description grant should be reported, keyed by plain field apiName');

        Boolean foundExistingObjectPermission = false;
        for (InspectorNativeFlsMatrix.ObjectPermissionState state : result.existingObjectPermissions) {
            if (state.permissionSetId == permissionSet.Id) {
                foundExistingObjectPermission = true;
                System.assertEquals(true, state.readAccess);
                System.assertEquals(true, state.createAccess);
                System.assertEquals(false, state.editAccess);
            }
        }
        System.assert(foundExistingObjectPermission, 'The existing object-level permission should be reported');
    }

    @IsTest
    static void getFieldPermissionMatrixThrowsForAnUnknownObject() {
        Boolean threw = false;
        Test.startTest();
        try {
            InspectorNativeFlsMatrix.getFieldPermissionMatrix('Definitely_Not_A_Real_Object__x');
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assert(threw, 'An unknown object api name should surface as a thrown exception');
    }

    @IsTest
    static void saveFieldPermissionsCreatesANewGrant() {
        PermissionSet permissionSet = new PermissionSet(Name = 'Test_Fls_Save_Set1', Label = 'Test FLS Save Set 1');
        insert permissionSet;

        InspectorNativeFlsGrant grant = new InspectorNativeFlsGrant();
        grant.fieldApiName = 'NextStep';
        grant.permissionSetId = permissionSet.Id;
        grant.readAccess = true;
        grant.editAccess = false;

        Test.startTest();
        InspectorNativeFlsMatrix.saveFieldPermissions(
            'Opportunity',
            JSON.serialize(new List<InspectorNativeFlsGrant>{ grant }),
            JSON.serialize(new List<InspectorNativeObjectPermissionGrant>())
        );
        Test.stopTest();

        FieldPermissions created = [
            SELECT PermissionsRead, PermissionsEdit
            FROM FieldPermissions
            WHERE ParentId = :permissionSet.Id AND SobjectType = 'Opportunity' AND Field = 'Opportunity.NextStep'
        ];
        System.assertEquals(true, created.PermissionsRead);
        System.assertEquals(false, created.PermissionsEdit);
    }

    @IsTest
    static void saveFieldPermissionsUpdatesAnExistingGrant() {
        PermissionSet permissionSet = new PermissionSet(Name = 'Test_Fls_Save_Set2', Label = 'Test FLS Save Set 2');
        insert permissionSet;
        insert new FieldPermissions(
            ParentId = permissionSet.Id,
            SobjectType = 'Opportunity',
            Field = 'Opportunity.LeadSource',
            PermissionsRead = true,
            PermissionsEdit = false
        );

        InspectorNativeFlsGrant grant = new InspectorNativeFlsGrant();
        grant.fieldApiName = 'LeadSource';
        grant.permissionSetId = permissionSet.Id;
        grant.readAccess = false;
        grant.editAccess = true;

        Test.startTest();
        InspectorNativeFlsMatrix.saveFieldPermissions(
            'Opportunity',
            JSON.serialize(new List<InspectorNativeFlsGrant>{ grant }),
            JSON.serialize(new List<InspectorNativeObjectPermissionGrant>())
        );
        Test.stopTest();

        List<FieldPermissions> updated = [
            SELECT PermissionsRead, PermissionsEdit
            FROM FieldPermissions
            WHERE ParentId = :permissionSet.Id AND SobjectType = 'Opportunity' AND Field = 'Opportunity.LeadSource'
        ];
        System.assertEquals(1, updated.size(), 'The existing row should be updated in place, not duplicated');
        System.assertEquals(true, updated[0].PermissionsRead, 'Edit access should imply read access');
        System.assertEquals(true, updated[0].PermissionsEdit);
    }

    @IsTest
    static void saveFieldPermissionsDeletesAnExistingGrantWhenBothUnchecked() {
        PermissionSet permissionSet = new PermissionSet(Name = 'Test_Fls_Save_Set3', Label = 'Test FLS Save Set 3');
        insert permissionSet;
        insert new FieldPermissions(
            ParentId = permissionSet.Id,
            SobjectType = 'Opportunity',
            Field = 'Opportunity.Type',
            PermissionsRead = true,
            PermissionsEdit = true
        );

        InspectorNativeFlsGrant grant = new InspectorNativeFlsGrant();
        grant.fieldApiName = 'Type';
        grant.permissionSetId = permissionSet.Id;
        grant.readAccess = false;
        grant.editAccess = false;

        Test.startTest();
        InspectorNativeFlsMatrix.saveFieldPermissions(
            'Opportunity',
            JSON.serialize(new List<InspectorNativeFlsGrant>{ grant }),
            JSON.serialize(new List<InspectorNativeObjectPermissionGrant>())
        );
        Test.stopTest();

        List<FieldPermissions> remaining = [
            SELECT Id
            FROM FieldPermissions
            WHERE ParentId = :permissionSet.Id AND SobjectType = 'Opportunity' AND Field = 'Opportunity.Type'
        ];
        System.assertEquals(0, remaining.size(), 'Unchecking both boxes should remove the grant entirely, unlike the additive-only Field Creator flow');
    }

    // Grants travel as a JSON string, parsed with JSON.deserialize() inside the method - a raw,
    // hand-written JSON literal (not built via JSON.serialize() of a real object, like every other
    // test here) exercises that parsing directly, the same shape the actual client payload takes.
    @IsTest
    static void saveFieldPermissionsParsesARawJsonStringPayload() {
        PermissionSet permissionSet = new PermissionSet(Name = 'Test_Fls_Json_Set', Label = 'Test FLS JSON Set');
        insert permissionSet;

        String grantsJson =
            '[{"fieldApiName":"Description","permissionSetId":"'
            + permissionSet.Id
            + '","readAccess":true,"editAccess":false}]';

        Test.startTest();
        InspectorNativeFlsMatrix.saveFieldPermissions('Opportunity', grantsJson, '[]');
        Test.stopTest();

        FieldPermissions created = [
            SELECT PermissionsRead, PermissionsEdit
            FROM FieldPermissions
            WHERE ParentId = :permissionSet.Id AND SobjectType = 'Opportunity' AND Field = 'Opportunity.Description'
        ];
        System.assertEquals(true, created.PermissionsRead);
        System.assertEquals(false, created.PermissionsEdit);
    }

    @IsTest
    static void saveFieldPermissionsIsANoOpWhenGivenNoGrantsAtAll() {
        Test.startTest();
        InspectorNativeFlsMatrix.saveFieldPermissions('Opportunity', JSON.serialize(new List<InspectorNativeFlsGrant>()), JSON.serialize(new List<InspectorNativeObjectPermissionGrant>()));
        Test.stopTest();
        // No exception thrown is the assertion here - nothing to query, there was nothing to do.
    }

    @IsTest
    static void saveFieldPermissionsCreatesANewObjectPermission() {
        PermissionSet permissionSet = new PermissionSet(Name = 'Test_Fls_Obj_Set1', Label = 'Test FLS Object Set 1');
        insert permissionSet;

        InspectorNativeObjectPermissionGrant grant = new InspectorNativeObjectPermissionGrant();
        grant.permissionSetId = permissionSet.Id;
        grant.readAccess = true;
        grant.createAccess = true;
        grant.editAccess = false;
        grant.deleteAccess = false;
        grant.viewAllAccess = false;
        grant.modifyAllAccess = false;

        Test.startTest();
        InspectorNativeFlsMatrix.saveFieldPermissions(
            'Opportunity',
            JSON.serialize(new List<InspectorNativeFlsGrant>()),
            JSON.serialize(new List<InspectorNativeObjectPermissionGrant>{ grant })
        );
        Test.stopTest();

        ObjectPermissions created = [
            SELECT PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete
            FROM ObjectPermissions
            WHERE ParentId = :permissionSet.Id AND SobjectType = 'Opportunity'
        ];
        System.assertEquals(true, created.PermissionsRead);
        System.assertEquals(true, created.PermissionsCreate);
        System.assertEquals(false, created.PermissionsEdit);
        System.assertEquals(false, created.PermissionsDelete);
    }

    @IsTest
    static void saveFieldPermissionsCascadesObjectPermissionDependencies() {
        PermissionSet permissionSet = new PermissionSet(Name = 'Test_Fls_Obj_Set2', Label = 'Test FLS Object Set 2');
        insert permissionSet;

        // Requesting only Delete (without Read/Edit explicitly checked) should still end up with
        // Read and Edit granted too - the same cascade the client enforces before a click ever
        // reaches here, re-applied server-side so a stale/bypassed payload can't leave an
        // inconsistent combination in the database.
        InspectorNativeObjectPermissionGrant grant = new InspectorNativeObjectPermissionGrant();
        grant.permissionSetId = permissionSet.Id;
        grant.readAccess = false;
        grant.editAccess = false;
        grant.deleteAccess = true;

        Test.startTest();
        InspectorNativeFlsMatrix.saveFieldPermissions(
            'Opportunity',
            JSON.serialize(new List<InspectorNativeFlsGrant>()),
            JSON.serialize(new List<InspectorNativeObjectPermissionGrant>{ grant })
        );
        Test.stopTest();

        ObjectPermissions created = [
            SELECT PermissionsRead, PermissionsEdit, PermissionsDelete
            FROM ObjectPermissions
            WHERE ParentId = :permissionSet.Id AND SobjectType = 'Opportunity'
        ];
        System.assertEquals(true, created.PermissionsDelete);
        System.assertEquals(true, created.PermissionsEdit, 'Delete access should imply Edit access');
        System.assertEquals(true, created.PermissionsRead, 'Delete access should imply Read access');
    }

    @IsTest
    static void saveFieldPermissionsUpdatesAnExistingObjectPermissionInPlace() {
        PermissionSet permissionSet = new PermissionSet(Name = 'Test_Fls_Obj_Set3', Label = 'Test FLS Object Set 3');
        insert permissionSet;
        insert new ObjectPermissions(
            ParentId = permissionSet.Id,
            SobjectType = 'Opportunity',
            PermissionsRead = true,
            PermissionsCreate = false,
            PermissionsEdit = false,
            PermissionsDelete = false,
            PermissionsViewAllRecords = false,
            PermissionsModifyAllRecords = false
        );

        InspectorNativeObjectPermissionGrant grant = new InspectorNativeObjectPermissionGrant();
        grant.permissionSetId = permissionSet.Id;
        grant.readAccess = true;
        grant.createAccess = true;

        Test.startTest();
        InspectorNativeFlsMatrix.saveFieldPermissions(
            'Opportunity',
            JSON.serialize(new List<InspectorNativeFlsGrant>()),
            JSON.serialize(new List<InspectorNativeObjectPermissionGrant>{ grant })
        );
        Test.stopTest();

        List<ObjectPermissions> updated = [
            SELECT PermissionsRead, PermissionsCreate
            FROM ObjectPermissions
            WHERE ParentId = :permissionSet.Id AND SobjectType = 'Opportunity'
        ];
        System.assertEquals(1, updated.size(), 'The existing row should be updated in place, not duplicated');
        System.assertEquals(true, updated[0].PermissionsCreate);
    }

    // Confirmed live: saving a field-level grant for a permission set with zero object-level access
    // on the object fails with INVALID_CROSS_REFERENCE_KEY unless object-level Read is granted
    // alongside it, in a genuinely separate, already-committed Apex transaction (see
    // InspectorNativeFlsMatrix's class doc comment - folding the auto-grant into saveFieldPermissions
    // itself was tried first and confirmed NOT to work, even though the object-level upsert itself
    // reported success). This exercises ensureObjectReadForFieldGrants directly, for a permission set
    // that has no ObjectPermissions row on Opportunity at all yet.
    //
    // Note: this only verifies ensureObjectReadForFieldGrants's own DML in isolation, run inside one
    // Apex test transaction - it can't reproduce (or rule back in) the specific same-transaction
    // ordering failure that motivated splitting this into its own method, since a single test method
    // calling both methods back to back is still one transaction under the hood. That distinction is
    // only observable via a real deploy, which is how the original failure was found.
    @IsTest
    static void ensureObjectReadForFieldGrantsCreatesReadWhenMissingEntirely() {
        PermissionSet permissionSet = new PermissionSet(Name = 'Test_Fls_AutoRead_Set1', Label = 'Test FLS Auto Read Set 1');
        insert permissionSet;

        InspectorNativeFlsGrant grant = new InspectorNativeFlsGrant();
        grant.fieldApiName = 'Description';
        grant.permissionSetId = permissionSet.Id;
        grant.readAccess = true;
        grant.editAccess = false;

        Test.startTest();
        InspectorNativeFlsMatrix.ensureObjectReadForFieldGrants('Opportunity', JSON.serialize(new List<InspectorNativeFlsGrant>{ grant }));
        Test.stopTest();

        List<ObjectPermissions> created = [
            SELECT PermissionsRead, PermissionsCreate, PermissionsEdit
            FROM ObjectPermissions
            WHERE ParentId = :permissionSet.Id AND SobjectType = 'Opportunity'
        ];
        System.assertEquals(1, created.size(), 'Object-level Read should be granted so a subsequent field grant is actually usable');
        System.assertEquals(true, created[0].PermissionsRead);
        System.assertEquals(false, created[0].PermissionsCreate, 'Only Read should be granted, nothing broader');
    }

    // A permission set that already has object-level Read is left exactly as it is - no update, no
    // second row, other flags untouched.
    @IsTest
    static void ensureObjectReadForFieldGrantsLeavesAnExistingReadGrantUntouched() {
        PermissionSet permissionSet = new PermissionSet(Name = 'Test_Fls_AutoRead_Set2', Label = 'Test FLS Auto Read Set 2');
        insert permissionSet;
        ObjectPermissions existing = new ObjectPermissions(ParentId = permissionSet.Id, SobjectType = 'Opportunity', PermissionsRead = true, PermissionsCreate = true);
        insert existing;

        InspectorNativeFlsGrant grant = new InspectorNativeFlsGrant();
        grant.fieldApiName = 'NextStep';
        grant.permissionSetId = permissionSet.Id;
        grant.readAccess = true;
        grant.editAccess = false;

        Test.startTest();
        InspectorNativeFlsMatrix.ensureObjectReadForFieldGrants('Opportunity', JSON.serialize(new List<InspectorNativeFlsGrant>{ grant }));
        Test.stopTest();

        List<ObjectPermissions> after = [
            SELECT Id, PermissionsRead, PermissionsCreate
            FROM ObjectPermissions
            WHERE ParentId = :permissionSet.Id AND SobjectType = 'Opportunity'
        ];
        System.assertEquals(1, after.size(), 'No second row should be created');
        System.assertEquals(existing.Id, after[0].Id);
        System.assertEquals(true, after[0].PermissionsRead);
        System.assertEquals(true, after[0].PermissionsCreate, 'Pre-existing flags should be left alone');
    }

    // Revoking a field grant (both boxes unchecked) removes access - it should never grant
    // object-level Read, since no new access is actually being requested.
    @IsTest
    static void ensureObjectReadForFieldGrantsIsANoOpWhenOnlyRevokingAField() {
        PermissionSet permissionSet = new PermissionSet(Name = 'Test_Fls_AutoRead_Set3', Label = 'Test FLS Auto Read Set 3');
        insert permissionSet;
        insert new FieldPermissions(
            ParentId = permissionSet.Id,
            SobjectType = 'Opportunity',
            Field = 'Opportunity.LeadSource',
            PermissionsRead = true,
            PermissionsEdit = false
        );

        InspectorNativeFlsGrant grant = new InspectorNativeFlsGrant();
        grant.fieldApiName = 'LeadSource';
        grant.permissionSetId = permissionSet.Id;
        grant.readAccess = false;
        grant.editAccess = false;

        Test.startTest();
        InspectorNativeFlsMatrix.ensureObjectReadForFieldGrants('Opportunity', JSON.serialize(new List<InspectorNativeFlsGrant>{ grant }));
        Test.stopTest();

        List<ObjectPermissions> objectPermissions = [
            SELECT Id
            FROM ObjectPermissions
            WHERE ParentId = :permissionSet.Id AND SobjectType = 'Opportunity'
        ];
        System.assertEquals(0, objectPermissions.size(), 'Revoking a field grant should not create an object-level permission that was never there');
    }

    @IsTest
    static void ensureObjectReadForFieldGrantsIsANoOpWhenGivenNoGrantsAtAll() {
        Test.startTest();
        InspectorNativeFlsMatrix.ensureObjectReadForFieldGrants('Opportunity', JSON.serialize(new List<InspectorNativeFlsGrant>()));
        Test.stopTest();
        // No exception thrown is the assertion here - nothing to query, there was nothing to do.
    }

    // The platform rejects inserting an ObjectPermissions row with every flag off, so a grant that
    // asks for nothing on a permission set with no row yet must not attempt one.
    @IsTest
    static void saveFieldPermissionsSkipsANewObjectPermissionThatGrantsNothing() {
        PermissionSet permissionSet = new PermissionSet(Name = 'Test_Fls_Obj_Set4', Label = 'Test FLS Object Set 4');
        insert permissionSet;

        InspectorNativeObjectPermissionGrant grant = new InspectorNativeObjectPermissionGrant();
        grant.permissionSetId = permissionSet.Id;
        grant.readAccess = false;
        grant.createAccess = false;

        Test.startTest();
        InspectorNativeFlsMatrix.saveFieldPermissions('Opportunity', '[]', JSON.serialize(new List<InspectorNativeObjectPermissionGrant>{ grant }));
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM ObjectPermissions WHERE ParentId = :permissionSet.Id AND SobjectType = 'Opportunity']);
    }

    // Unchecking everything on an existing row: the platform deletes an ObjectPermissions row once
    // every flag on it is off, so the permission set ends up with no row for the object at all.
    @IsTest
    static void saveFieldPermissionsRemovesObjectAccessWhenEverythingIsUnchecked() {
        PermissionSet permissionSet = new PermissionSet(Name = 'Test_Fls_Obj_Set5', Label = 'Test FLS Object Set 5');
        insert permissionSet;
        insert new ObjectPermissions(ParentId = permissionSet.Id, SobjectType = 'Opportunity', PermissionsRead = true, PermissionsCreate = true);

        InspectorNativeObjectPermissionGrant grant = new InspectorNativeObjectPermissionGrant();
        grant.permissionSetId = permissionSet.Id;

        Test.startTest();
        InspectorNativeFlsMatrix.saveFieldPermissions('Opportunity', '[]', JSON.serialize(new List<InspectorNativeObjectPermissionGrant>{ grant }));
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM ObjectPermissions WHERE ParentId = :permissionSet.Id AND SobjectType = 'Opportunity']);
    }

    // Account Read on its own: works everywhere, and in a Person Accounts org (where the platform
    // makes it depend on Contact Read) Contact Read is granted alongside it.
    @IsTest
    static void saveFieldPermissionsGrantsAccountReadAndContactReadWhenPersonAccountsRequireIt() {
        PermissionSet permissionSet = new PermissionSet(Name = 'Test_Fls_Acct_Set1', Label = 'Test FLS Account Set 1');
        insert permissionSet;

        InspectorNativeObjectPermissionGrant grant = new InspectorNativeObjectPermissionGrant();
        grant.permissionSetId = permissionSet.Id;
        grant.readAccess = true;
        grant.editAccess = true;

        Test.startTest();
        InspectorNativeFlsMatrix.saveFieldPermissions('Account', '[]', JSON.serialize(new List<InspectorNativeObjectPermissionGrant>{ grant }));
        Test.stopTest();

        ObjectPermissions account = [
            SELECT PermissionsRead, PermissionsEdit
            FROM ObjectPermissions
            WHERE ParentId = :permissionSet.Id AND SobjectType = 'Account'
        ];
        System.assertEquals(true, account.PermissionsRead);
        System.assertEquals(true, account.PermissionsEdit);
        List<ObjectPermissions> contact = [
            SELECT PermissionsRead, PermissionsEdit
            FROM ObjectPermissions
            WHERE ParentId = :permissionSet.Id AND SobjectType = 'Contact'
        ];
        if (InspectorNativeFlsMatrix.isPersonAccountsEnabled()) {
            System.assertEquals(1, contact.size(), 'Person Accounts: Contact Read should be granted with Account Read');
            System.assertEquals(true, contact[0].PermissionsRead);
            System.assertEquals(false, contact[0].PermissionsEdit, 'Only Contact Read is required, nothing broader');
        } else {
            System.assertEquals(0, contact.size(), 'Without Person Accounts, Contact access should be left alone');
        }
    }

    @IsTest
    static void ensureObjectReadForFieldGrantsOnAccountWorksWithOrWithoutPersonAccounts() {
        PermissionSet permissionSet = new PermissionSet(Name = 'Test_Fls_Acct_Set2', Label = 'Test FLS Account Set 2');
        insert permissionSet;

        InspectorNativeFlsGrant grant = new InspectorNativeFlsGrant();
        grant.fieldApiName = 'Phone';
        grant.permissionSetId = permissionSet.Id;
        grant.readAccess = true;
        grant.editAccess = true;

        Test.startTest();
        InspectorNativeFlsMatrix.ensureObjectReadForFieldGrants('Account', JSON.serialize(new List<InspectorNativeFlsGrant>{ grant }));
        InspectorNativeFlsMatrix.saveFieldPermissions('Account', JSON.serialize(new List<InspectorNativeFlsGrant>{ grant }), '[]');
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM ObjectPermissions WHERE ParentId = :permissionSet.Id AND SobjectType = 'Account' AND PermissionsRead = TRUE]);
        System.assertEquals(
            InspectorNativeFlsMatrix.isPersonAccountsEnabled() ? 1 : 0,
            [SELECT COUNT() FROM ObjectPermissions WHERE ParentId = :permissionSet.Id AND SobjectType = 'Contact' AND PermissionsRead = TRUE]
        );
        FieldPermissions phone = [SELECT PermissionsRead, PermissionsEdit FROM FieldPermissions WHERE ParentId = :permissionSet.Id AND Field = 'Account.Phone'];
        System.assertEquals(true, phone.PermissionsEdit);
    }

    // A permission set that already has Contact Read needs nothing added.
    @IsTest
    static void addRequiredContactReadSkipsAPermissionSetThatAlreadyHasContactRead() {
        PermissionSet permissionSet = new PermissionSet(Name = 'Test_Fls_Acct_Set3', Label = 'Test FLS Account Set 3');
        insert permissionSet;
        insert new ObjectPermissions(ParentId = permissionSet.Id, SobjectType = 'Contact', PermissionsRead = true, PermissionsCreate = true);

        List<ObjectPermissions> toUpsert = new List<ObjectPermissions>{
            new ObjectPermissions(ParentId = permissionSet.Id, SobjectType = 'Account', PermissionsRead = true)
        };
        Test.startTest();
        InspectorNativeFlsMatrix.addRequiredContactRead('Account', toUpsert);
        Test.stopTest();

        System.assertEquals(1, toUpsert.size(), 'Contact Read is already there, so nothing should be added');
    }

    @IsTest
    static void addRequiredContactReadIgnoresOtherObjects() {
        List<ObjectPermissions> toUpsert = new List<ObjectPermissions>{
            new ObjectPermissions(ParentId = UserInfo.getUserId(), SobjectType = 'Opportunity', PermissionsRead = true)
        };
        Test.startTest();
        InspectorNativeFlsMatrix.addRequiredContactRead('Opportunity', toUpsert);
        Test.stopTest();

        System.assertEquals(1, toUpsert.size());
    }
}
