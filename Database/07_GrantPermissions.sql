revoke all on table public."TblP106Places" from anon;
grant select, insert, update, delete on table public."TblP106Places" to authenticated;

revoke all on function public."P106SetUpdatedAt"() from public;
revoke all on function public."P106SetUpdatedAt"() from anon;
grant execute on function public."P106SetUpdatedAt"() to authenticated;

revoke all on function public."P106SearchPublicPlaces"() from public;
revoke all on function public."P106SearchPublicPlaces"() from anon;
grant execute on function public."P106SearchPublicPlaces"() to authenticated;
