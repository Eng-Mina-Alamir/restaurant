-- ==============================================================================
-- 🧪 E2E DB SMOKE TESTS — order lifecycle / chat+realtime / cart+modifiers
-- ==============================================================================
-- HOW TO RUN (repeatable, zero residue):
--   Each flow below is ONE transaction that ends with ROLLBACK, so nothing it
--   creates survives. Run each block separately in the Supabase SQL Editor or
--   via `supabase db query`.
--
-- PREREQUISITES (one-off, already applied as migrations on 2026-08-24):
--   • order_items.id default gen_random_uuid()::text
--   • supabase_realtime publication includes chat_messages,
--     delivery_assignments, order_status_log (+ orders/tables/driver_locations)
--   • status-log policies allow driver inserts and staff reads
--
-- IDENTITY MAP used here (all demo profiles, roles restored by ROLLBACK):
--   C  = 77770c66-6fb4-4723-9215-2e319405a6bd  customer (order owner)
--   W  = 6bae86c6-79c8-48a4-a185-32f643204656  -> waiter
--   K  = 0f52d653-640c-44cf-a5b4-cdc5152146a4  -> kitchen
--   D  = 68f1fb56-3868-4dd7-9c87-8253676b6837  -> driver
--   M  = 3cde9c93-c153-4060-a899-bc7051dce379  -> manager
--   S  = e909a3d4-6378-4606-8957-6ac641456731  stranger customer (negative probes)
-- The role-guard triggers are disabled INSIDE the tx only, then re-enabled.
-- ==============================================================================

-- ##############################################################################
-- FLOW 1 — ORDER LIFECYCLE: place → kitchen claims → manager dispatches →
--          driver delivers & completes parent order → audit trail tracked
-- EXPECTED FINAL RESULT SET: every probe matches its "expect" label.
-- ##############################################################################
begin;
create temp table e2e_results(probe text, result text) on commit drop;
grant insert, select on e2e_results to authenticated;

alter table public.profiles disable trigger trg_enforce_profile_insert_role;
alter table public.profiles disable trigger trg_enforce_profile_update_role;
update public.profiles set role='waiter'  where id='6bae86c6-79c8-48a4-a185-32f643204656';
update public.profiles set role='kitchen' where id='0f52d653-640c-44cf-a5b4-cdc5152146a4';
update public.profiles set role='driver'  where id='68f1fb56-3868-4dd7-9c87-8253676b6837';
update public.profiles set role='manager' where id='3cde9c93-c153-4060-a899-bc7051dce379';
alter table public.profiles enable trigger trg_enforce_profile_insert_role;
alter table public.profiles enable trigger trg_enforce_profile_update_role;

set local role authenticated;

-- STEP 1: customer places order + line items (no id — server generates)
set local request.jwt.claims = '{"sub":"77770c66-6fb4-4723-9215-2e319405a6bd","role":"authenticated"}';
insert into public.orders(id, restaurant_id, customer_id, order_type, status, subtotal, tax_amount, total_amount, created_at, updated_at)
values ('ORD-E2E-0001','1e08b47c-15be-4604-a913-431af7fbd54f','77770c66-6fb4-4723-9215-2e319405a6bd','dineIn','pending',470,46.5,516.5,now(),now());
insert into public.order_items(order_id, menu_item_id, item_name, price, quantity, total_price, special_notes, modifiers_json, added_at)
values ('ORD-E2E-0001','item-1','كباب وكفتة ضاني',280,1,280,null,'[]'::jsonb,now()),
       ('ORD-E2E-0001','item-2','شيش طاووق متبل',190,2,380,'زيادة توابل','[]'::jsonb,now());
insert into e2e_results
select 'F1.items_with_generated_ids(expect 2)', count(*)::text from public.order_items oi where oi.order_id='ORD-E2E-0001';

-- STEP 2: kitchen claims & starts preparing
set local request.jwt.claims = '{"sub":"0f52d653-640c-44cf-a5b4-cdc5152146a4","role":"authenticated"}';
update public.orders set assigned_kitchen_id='0f52d653-640c-44cf-a5b4-cdc5152146a4', status='preparing' where id='ORD-E2E-0001';
insert into public.order_status_log(order_id, from_status, to_status, changed_by, reason)
values ('ORD-E2E-0001','pending','preparing','0f52d653-640c-44cf-a5b4-cdc5152146a4','KDS start');
insert into e2e_results
select 'F1.kds_reads_own_trail(expect 1)', count(*)::text from public.order_status_log where order_id='ORD-E2E-0001';

-- STEP 3: manager dispatches driver
set local request.jwt.claims = '{"sub":"3cde9c93-c153-4060-a899-bc7051dce379","role":"authenticated"}';
update public.orders set driver_id='68f1fb56-3868-4dd7-9c87-8253676b6837' where id='ORD-E2E-0001';
insert into public.delivery_assignments(id, order_id, driver_id, pickup_time, delivery_location)
values ('DA-E2E-0001','ORD-E2E-0001','68f1fb56-3868-4dd7-9c87-8253676b6837',now(),'شارع التحرير، القاهرة');

-- STEP 4: driver accepts → delivers → completes parent order (onDelivered hook)
set local request.jwt.claims = '{"sub":"68f1fb56-3868-4dd7-9c87-8253676b6837","role":"authenticated"}';
update public.delivery_assignments set delivery_status='accepted' where id='DA-E2E-0001';
update public.delivery_assignments set delivery_status='delivered', delivered_time=now(), latitude=30.0444, longitude=31.2357 where id='DA-E2E-0001';
update public.orders set status='completed', completed_at=now() where id='ORD-E2E-0001' and driver_id='68f1fb56-3868-4dd7-9c87-8253676b6837';
insert into public.order_status_log(order_id, from_status, to_status, changed_by)
values ('ORD-E2E-0001','preparing','completed','68f1fb56-3868-4dd7-9c87-8253676b6837');
insert into e2e_results
select 'F1.assignment_terminal(expect delivered)', coalesce((select delivery_status from public.delivery_assignments where id='DA-E2E-0001'),'MISSING')
union all select 'F1.final_state(expect completed)', coalesce((select status from public.orders where id='ORD-E2E-0001'),'MISSING');

-- STEP 5: owner visibility
set local request.jwt.claims = '{"sub":"77770c66-6fb4-4723-9215-2e319405a6bd","role":"authenticated"}';
insert into e2e_results
select 'F1.order_visible_to_customer(expect 1)', count(*)::text from public.orders where id='ORD-E2E-0001'
union all
select 'F1.log_readable_by_customer(expect 2)', count(*)::text from public.order_status_log where order_id='ORD-E2E-0001';

-- STEP 6: stranger isolation
set local request.jwt.claims = '{"sub":"e909a3d4-6378-4606-8957-6ac641456731","role":"authenticated"}';
insert into e2e_results
select 'F1.NEG_order_hidden_from_stranger(expect 0)', count(*)::text from public.orders where id='ORD-E2E-0001'
union all
select 'F1.NEG_stranger_cannot_read_log(expect 0)', count(*)::text from public.order_status_log where order_id='ORD-E2E-0001';

select probe, result from e2e_results order by probe desc;
rollback;

-- ##############################################################################
-- FLOW 2 — CHAT + REALTIME PRECONDITIONS: send/receive across participants,
--          spoofing rejected, constraints enforced, hot tables in publication.
-- ##############################################################################
begin;
create temp table e2e_results(probe text, result text) on commit drop;
grant insert, select on e2e_results to authenticated;

alter table public.profiles disable trigger trg_enforce_profile_update_role;
update public.profiles set role='driver'  where id='68f1fb56-3868-4dd7-9c87-8253676b6837';
update public.profiles set role='manager' where id='3cde9c93-c153-4060-a899-bc7051dce379';
alter table public.profiles enable trigger trg_enforce_profile_update_role;

set local role authenticated;
set local request.jwt.claims = '{"sub":"77770c66-6fb4-4723-9215-2e319405a6bd","role":"authenticated"}';
insert into public.orders(id, restaurant_id, customer_id, order_type, status, subtotal, tax_amount, total_amount, delivery_address, created_at, updated_at)
values ('ORD-E2E-0002','1e08b47c-15be-4604-a913-431af7fbd54f','77770c66-6fb4-4723-9215-2e319405a6bd','delivery','pending',240,23.6,263.6,'المعادي، القاهرة',now(),now());

set local request.jwt.claims = '{"sub":"3cde9c93-c153-4060-a899-bc7051dce379","role":"authenticated"}';
insert into public.delivery_assignments(id, order_id, driver_id, pickup_time, delivery_location)
values ('DA-E2E-0002','ORD-E2E-0002','68f1fb56-3868-4dd7-9c87-8253676b6837',now(),'المعادي، القاهرة');

set local request.jwt.claims = '{"sub":"77770c66-6fb4-4723-9215-2e319405a6bd","role":"authenticated"}';
insert into public.chat_messages(order_id, sender_id, body)
values ('ORD-E2E-0002','77770c66-6fb4-4723-9215-2e319405a6bd','مرحباً، وصلت فين يا ريس؟');
insert into e2e_results
select 'F2.customer_sent_msg_with_generated_uuid(expect t)', (id::text ~* '^[0-9a-f-]{36}$')::text from public.chat_messages where order_id='ORD-E2E-0002';

set local request.jwt.claims = '{"sub":"68f1fb56-3868-4dd7-9c87-8253676b6837","role":"authenticated"}';
insert into e2e_results
select 'F2.driver_reads_history_via_assignment(expect 1)', count(*)::text from public.chat_messages where order_id='ORD-E2E-0002';
insert into public.chat_messages(order_id, sender_id, body)
values ('ORD-E2E-0002','68f1fb56-3868-4dd7-9c87-8253676b6837','قربت أوصل، ٥ دقايق');

set local request.jwt.claims = '{"sub":"3cde9c93-c153-4060-a899-bc7051dce379","role":"authenticated"}';
insert into e2e_results
select 'F2.manager_sees_full_thread(expect 2)', count(*)::text from public.chat_messages where order_id='ORD-E2E-0002';

set local request.jwt.claims = '{"sub":"e909a3d4-6378-4606-8957-6ac641456731","role":"authenticated"}';
insert into e2e_results
select 'F2.NEG_stranger_sees_nothing(expect 0)', count(*)::text from public.chat_messages where order_id='ORD-E2E-0002';

set local request.jwt.claims = '{"sub":"77770c66-6fb4-4723-9215-2e319405a6bd","role":"authenticated"}';
do $$ begin
  begin
    insert into public.chat_messages(order_id, sender_id, body)
    values ('ORD-E2E-0002','77770c66-6fb4-4723-9215-2e319405a6bd',repeat('x',1001));
    insert into e2e_results values('F2.NEG_overlong_body(expect check_violation)','FAIL');
  exception when check_violation then
    insert into e2e_results values('F2.NEG_overlong_body(expect check_violation)','OK-check_violation');
  end;
end $$;

do $$ begin
  begin
    insert into public.chat_messages(order_id, sender_id, body)
    values ('ORD-NOPE-404','77770c66-6fb4-4723-9215-2e319405a6bd','ghost');
    insert into e2e_results values('F2.NEG_ghost_order_rejected(expect rls)','FAIL');
  exception when insufficient_privilege then
    insert into e2e_results values('F2.NEG_ghost_order_rejected(expect rls)','OK-rls_rejected');
  end;
end $$;

set local request.jwt.claims = '{"sub":"e909a3d4-6378-4606-8957-6ac641456731","role":"authenticated"}';
do $$ begin
  begin
    insert into public.chat_messages(order_id, sender_id, body)
    values ('ORD-E2E-0002','77770c66-6fb4-4723-9215-2e319405a6bd','spoofed');
    insert into e2e_results values('F2.NEG_spoofed_sender_rejected(expect rls)','FAIL');
  exception when insufficient_privilege then
    insert into e2e_results values('F2.NEG_spoofed_sender_rejected(expect rls)','OK-rls_rejected');
  end;
end $$;

insert into e2e_results
select 'F2.realtime_pub_has_'||tablename, 'yes'
from pg_publication_tables
where pubname='supabase_realtime'
  and schemaname='public'
  and tablename in ('chat_messages','delivery_assignments','order_status_log','orders','tables','driver_locations');

select probe, result from e2e_results order by probe desc;
rollback;

-- ##############################################################################
-- FLOW 3 — CART + MODIFIERS: seed options, save cart_item_modifiers pair-wise,
--          duplicate rejected, cross-user isolation enforced.
-- ##############################################################################
begin;
create temp table e2e_results(probe text, result text) on commit drop;
grant insert, select on e2e_results to authenticated;

alter table public.profiles disable trigger trg_enforce_profile_update_role;
update public.profiles set role='manager' where id='3cde9c93-c153-4060-a899-bc7051dce379';
alter table public.profiles enable trigger trg_enforce_profile_update_role;

set local role authenticated;

set local request.jwt.claims = '{"sub":"3cde9c93-c153-4060-a899-bc7051dce379","role":"authenticated"}';
insert into public.menu_modifier_groups(id, menu_item_id, title)
values ('mg-e2e-rice','item-3','اختر طبق جانبي'),
       ('mg-e2e-drink','item-3','مشروب');
insert into public.menu_modifier_options(id, modifier_group_id, name)
values ('mo-e2e-rice','mg-e2e-rice','أرز بالسمنة'),
       ('mo-e2e-salad','mg-e2e-rice','سلطة خضراء'),
       ('mo-e2e-limon','mg-e2e-drink','ليمون بالنعناع');
insert into e2e_results
select 'F3.manager_seeds_modifiers(expect 3)', count(*)::text from public.menu_modifier_options where id like 'mo-e2e%';

set local request.jwt.claims = '{"sub":"77770c66-6fb4-4723-9215-2e319405a6bd","role":"authenticated"}';
insert into public.cart_items(id, user_id, menu_item_id)
values ('ci-e2e-1','77770c66-6fb4-4723-9215-2e319405a6bd','item-3');
insert into public.cart_item_modifiers(id, cart_item_id, modifier_option_id)
values ('cim-e2e-1','ci-e2e-1','mo-e2e-rice'),
       ('cim-e2e-2','ci-e2e-1','mo-e2e-limon');
insert into e2e_results
select 'F3.cart_with_modifiers_saved(expect 2)', count(*)::text
from public.cart_item_modifiers cim
join public.menu_modifier_options mo on mo.id = cim.modifier_option_id
where cim.cart_item_id='ci-e2e-1';

do $$ begin
  begin
    insert into public.cart_item_modifiers(id, cart_item_id, modifier_option_id)
    values ('cim-e2e-dup','ci-e2e-1','mo-e2e-rice');
    insert into e2e_results values('F3.NEG_duplicate_pair_rejected(expect uniq)','FAIL');
  exception when unique_violation then
    insert into e2e_results values('F3.NEG_duplicate_pair_rejected(expect uniq)','OK-unique_violation');
  end;
end $$;

set local request.jwt.claims = '{"sub":"e909a3d4-6378-4606-8957-6ac641456731","role":"authenticated"}';
insert into e2e_results
select 'F3.NEG_stranger_sees_cart(expect 0)', count(*)::text from public.cart_items where id='ci-e2e-1';
do $$ begin
  begin
    insert into public.cart_item_modifiers(id, cart_item_id, modifier_option_id)
    values ('cim-e2e-hack','ci-e2e-1','mo-e2e-salad');
    insert into e2e_results values('F3.NEG_stranger_cannot_modify(expect rls)','FAIL');
  exception when insufficient_privilege then
    insert into e2e_results values('F3.NEG_stranger_cannot_modify(expect rls)','OK-rls_rejected');
  end;
end $$;

set local request.jwt.claims = '{"sub":"77770c66-6fb4-4723-9215-2e319405a6bd","role":"authenticated"}';
insert into e2e_results
select 'F3.owner_restores_cart(expect 1)', count(*)::text from public.cart_items where user_id='77770c66-6fb4-4723-9215-2e319405a6bd';

select probe, result from e2e_results order by probe desc;
rollback;
