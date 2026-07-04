-- Create a brand new test captain user because previous credentials failed
DO $$
DECLARE
    new_user_id uuid := gen_random_uuid();
    new_driver_id uuid := gen_random_uuid();
BEGIN
    -- 1. Create the auth user (Email: new_captain@bmt-app.com, Password: password123)
    INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        phone,
        encrypted_password,
        email_confirmed_at,
        created_at,
        updated_at,
        raw_app_meta_data,
        raw_user_meta_data
    ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        new_user_id,
        'authenticated',
        'authenticated',
        'new_captain@bmt-app.com',
        '+201111111111',
        extensions.crypt('password123', extensions.gen_salt('bf')),
        now(),
        now(),
        now(),
        '{"provider": "email", "providers": ["email"]}',
        '{"name": "New Captain"}'
    );

    -- 2. Create the auth identity record for email login
    INSERT INTO auth.identities (
        id,
        user_id,
        provider_id,
        identity_data,
        provider,
        created_at,
        updated_at
    ) VALUES (
        gen_random_uuid(),
        new_user_id,
        new_user_id::text,
        format('{"sub": "%s", "email": "%s"}', new_user_id, 'new_captain@bmt-app.com')::jsonb,
        'email',
        now(),
        now()
    );

    -- 3. Link this user to a new driver profile
    INSERT INTO public.drivers (
        id,
        user_id,
        employee_code,
        full_name,
        phone,
        status,
        license_number,
        created_at,
        updated_at
    ) VALUES (
        new_driver_id,
        new_user_id,
        'EMP-TEST-002',
        'Test Captain',
        '+201111111111',
        'active',
        'LIC-TEST-002',
        now(),
        now()
    );
END $$;
