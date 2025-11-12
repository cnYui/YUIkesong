select storage.create_bucket('selfies', public := false);
select storage.create_bucket('wardrobe', public := false);
select storage.create_bucket('saved_looks', public := false);
select storage.create_bucket('community', public := true);

create policy selfies_read on storage.objects for select using (
  bucket_id = 'selfies' and owner = auth.uid()
);
create policy selfies_write on storage.objects for all using (
  bucket_id = 'selfies' and owner = auth.uid()
) with check (
  bucket_id = 'selfies' and owner = auth.uid()
);

create policy wardrobe_read on storage.objects for select using (
  bucket_id = 'wardrobe' and owner = auth.uid()
);
create policy wardrobe_write on storage.objects for all using (
  bucket_id = 'wardrobe' and owner = auth.uid()
) with check (
  bucket_id = 'wardrobe' and owner = auth.uid()
);

create policy saved_looks_read on storage.objects for select using (
  bucket_id = 'saved_looks' and owner = auth.uid()
);
create policy saved_looks_write on storage.objects for all using (
  bucket_id = 'saved_looks' and owner = auth.uid()
) with check (
  bucket_id = 'saved_looks' and owner = auth.uid()
);

create policy community_public_read on storage.objects for select using (
  bucket_id = 'community'
);
create policy community_owner_write on storage.objects for all using (
  bucket_id = 'community' and owner = auth.uid()
) with check (
  bucket_id = 'community' and owner = auth.uid()
);
