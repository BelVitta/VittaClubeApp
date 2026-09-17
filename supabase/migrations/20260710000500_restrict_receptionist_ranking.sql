-- O ranking é operacional da recepção; financeiro não deve acessá-lo.
CREATE OR REPLACE FUNCTION public.get_receptionist_monthly_ranking(
  p_month_reference text
)
RETURNS TABLE (
  receptionist_id uuid,
  receptionist_name text,
  receptionist_code text,
  indicacoes_count bigint,
  conversoes_count bigint,
  total_gerado numeric
)
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF auth.uid() IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Acesso restrito às recepcionistas.';
  END IF;

  RETURN QUERY
  SELECT p.id, p.name, p.receptionist_code,
    count(rr.id) FILTER (
      WHERE rr.created_at >= to_date(p_month_reference || '-01', 'YYYY-MM-DD')
        AND rr.created_at < (to_date(p_month_reference || '-01', 'YYYY-MM-DD') + interval '1 month')
    ),
    count(rr.id) FILTER (WHERE rr.month_reference = p_month_reference),
    coalesce(sum(rr.plan_price_at_conversion)
      FILTER (WHERE rr.month_reference = p_month_reference), 0)
  FROM public.profiles p
  LEFT JOIN public.receptionist_referrals rr ON rr.receptionist_id = p.id
  WHERE p.role = 'admin'
  GROUP BY p.id, p.name, p.receptionist_code
  ORDER BY 5 DESC, 6 DESC, 2 ASC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_receptionist_monthly_ranking(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_receptionist_monthly_ranking(text) TO authenticated;
