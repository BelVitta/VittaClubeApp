export async function hasBillingAdminRole(
  userClient: any,
  userId: string,
): Promise<boolean> {
  const { data, error } = await userClient
    .from("profiles")
    .select("role")
    .eq("id", userId)
    .maybeSingle();
  if (error || !data) return false;
  return ["admin", "financeiro", "super_admin"].includes(String(data.role));
}

