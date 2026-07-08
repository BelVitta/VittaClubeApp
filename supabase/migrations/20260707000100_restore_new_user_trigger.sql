-- O trigger on_auth_user_created (dispara handle_new_user() para criar a
-- linha em public.profiles no signup) foi encontrado ausente em produção,
-- fora do histórico de migrations rastreado — provavelmente removido
-- manualmente durante alguma depuração e nunca recriado. A função em si
-- continuava intacta; só o trigger que a conecta a auth.users sumiu,
-- deixando contas novas (Google e email/senha) sem perfil.
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
