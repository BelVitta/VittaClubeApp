-- Registra quem aprovou e quando, automaticamente — não confia no client
-- pra mandar approved_by (poderia mandar qualquer uuid).
create or replace function public.prevent_dependent_self_approval()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status is distinct from old.status and new.status = 'active' then
    if not public.is_admin() then
      raise exception 'Somente um administrador pode aprovar um dependente.';
    end if;
    new.approved_by := auth.uid();
    new.approved_at := now();
  end if;
  return new;
end;
$$;
