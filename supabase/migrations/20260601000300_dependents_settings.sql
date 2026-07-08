-- Default dependent feature settings.
-- Values live in clinic_settings so business limits are configurable and not
-- hardcoded in Flutter code.

insert into public.clinic_settings (key, value)
values
  ('max_dependents_per_holder', '2'),
  ('monthly_uses_per_dependent', '2')
on conflict (key) do nothing;
