-- Link the requested test captain account to the existing emp1 driver.
update public.drivers
   set user_id = (
         select u.id
           from auth.users u
          where lower(u.email) = lower('captain.emp1@bmt-app.com')
          limit 1
       ),
       updated_at = now()
 where id = '3a398822-eee5-4db4-9262-fd6ad86d18b5'
   and user_id is null
   and exists (
         select 1
           from auth.users u
          where lower(u.email) = lower('captain.emp1@bmt-app.com')
       );

